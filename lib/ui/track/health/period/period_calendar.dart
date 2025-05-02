import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roo_mobile/main.dart';
import 'package:roo_mobile/ui/track/health/period/period_symptoms.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:simple_animated_button/elevated_layer_button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void showPeriodCalendarBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Make background transparent
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: PeriodCalendarSheetContent(), // Your actual content
          );
        },
      );
    },
  );
}

class PeriodLog {
  final List<DateTime> days;
  final Map<String, bool> symptoms;
  String notes;

  PeriodLog({required this.days, Map<String, bool>? symptoms, this.notes = ''})
    : symptoms = symptoms ?? {};
}

class PeriodCalendarSheetContent extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const PeriodCalendarSheetContent({Key? key, this.onBackToHome})
    : super(key: key);

  @override
  _PeriodCalendarSheetContentState createState() =>
      _PeriodCalendarSheetContentState();
}

class _PeriodCalendarSheetContentState
    extends State<PeriodCalendarSheetContent> {
  Set<DateTime> _periodDates = {};
  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDay = DateTime.now().subtract(Duration(days: 3650));
  final DateTime _lastDay = DateTime.now().add(Duration(days: 365));
  bool _isLoading = true; // 1) loading flag

  // 1. Add state variable
  bool _showingSymptomsInput = false;
  int _selectedPeriodId = 0;
  void _toggleSymptomsInput(bool value) async {
    if (!value) {
      // Symptoms flow done, reload state
      setState(() {
        _showingSymptomsInput = false;
        _userSelectedDates.clear(); // ✅ clear selected
        _rangeStart = null;
        _rangeEnd = null;
        _isLoading = true;
      });

      await _fetchLast4MonthsPeriods(); // ✅ refresh calendar
    } else {
      setState(() {
        _showingSymptomsInput = true;
      });
    }
  }

  Future<void> _sendFullMonthPeriodData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final now = _focusedDay;
    final year = now.year;
    final month = now.month;
    _isLoading = true;

    final user = FirebaseAuth.instance.currentUser;
    final firebaseToken = await user?.getIdToken();

    // Helper to check if a date is in the current month
    bool isInCurrentMonth(DateTime date) {
      return date.year == year && date.month == month;
    }

    // Step 1: Sort the dates
    final datesToUse =
        _userSelectedDates.isNotEmpty ? _userSelectedDates : _prepopulatedDates;

    List<DateTime> sortedDates = List.from(datesToUse)..sort();
    // Step 2: Group dates into contiguous periods
    List<List<DateTime>> contiguousPeriods = [];
    List<DateTime> currentGroup = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final current = sortedDates[i];
      if (currentGroup.isEmpty) {
        currentGroup.add(current);
      } else {
        final previous = currentGroup.last;
        // Check if the current date is exactly one day after the previous
        if (current.difference(previous).inDays == 1) {
          currentGroup.add(current);
        } else {
          // End of one group, start a new one
          contiguousPeriods.add(currentGroup);
          currentGroup = [current];
        }
      }
    }

    // Don't forget the last group
    if (currentGroup.isNotEmpty) {
      contiguousPeriods.add(currentGroup);
    }

    // Step 3: Filter to include only periods that overlap with current month
    final filteredDates = <DateTime>[];
    for (var group in contiguousPeriods) {
      final overlapsCurrentMonth = group.any((d) => isInCurrentMonth(d));
      if (overlapsCurrentMonth) {
        filteredDates.addAll(group);
      }
    }

    final body = jsonEncode({
      'firebase_token': firebaseToken,
      'month': month,
      'year': year,
      'period_dates': filteredDates.map((d) => d.toIso8601String()).toList(),
    });

    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/period-calendar/update'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the loading dialog
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _selectedPeriodId = responseData["period_id"];
        _isLoading = false;
        _toggleSymptomsInput(true);
      } else {
        Navigator.of(context).pop(); // Close the loading dialog

        print("Failed to sync full calendar: ${response.statusCode}");
      }
    } catch (e) {
      print("Error syncing calendar: $e");
      _isLoading = false;
    }
    _isLoading = false;
  }

  //PeriodLog? _selectedLog;
  final List<String> _symptomOptions = [
    'Cramps',
    'Bloating',
    'Mood Swings',
    'Headache',
    'Fatigue',
  ];
  Map<String, bool> _selectedSymptoms = {};
  TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLast4MonthsPeriods();

    // Initialize all symptoms as false
    for (var symptom in _symptomOptions) {
      _selectedSymptoms[symptom] = false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Set<DateTime> _prepopulatedDates = {};
  Set<DateTime> _userSelectedDates = {};

  Future<void> _fetchLast4MonthsPeriods() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final resp = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/period-calendar/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': token}),
      );

      //print("Response: ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final periods = data['periods'] as List<dynamic>;

        final Set<DateTime> loadedDates = {};
        for (var p in periods) {
          final start = DateTime.parse(p['start_date']);
          final end = DateTime.parse(p['end_date']);
          for (
            var d = start;
            !d.isAfter(end);
            d = d.add(const Duration(days: 1))
          ) {
            loadedDates.add(DateTime(d.year, d.month, d.day));
          }
        }

        setState(() {
          _periodDates = loadedDates;
          _prepopulatedDates = loadedDates;
        });
      } else {
        debugPrint('Error fetching periods: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception fetching periods: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _resetCurrentMonth() async {
    final int month = _focusedDay.month;
    final int year = _focusedDay.year;

    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    // 1. Confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Reset Month?', style: largeText()),
              ],
            ),
            content: Text(
              'This will remove all period data for $month/$year.',
              style: mediumText(color: Colors.black54),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('No', style: mediumText(color: Colors.black)),
              ),
              TextButton(
                style: TextButton.styleFrom(backgroundColor: Colors.black),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Yes', style: mediumText(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      print('User canceled the reset.');
      return;
    }

    // 2. Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Send POST request
      final response = await http.post(
        Uri.parse('${EnvConfig.baseUrl2}/period-calendar/reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firebase_token': token,
          'month': month,
          'year': year,
        }),
      );

      Navigator.of(context).pop(); // Close the loading dialog

      //print("Response: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _userSelectedDates.removeWhere(
            (d) => d.year == year && d.month == month,
          );
          _prepopulatedDates.removeWhere(
            (d) => d.year == year && d.month == month,
          );
          _periodDates.removeWhere((d) => d.year == year && d.month == month);
          _rangeStart = null;
          _rangeEnd = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current month has been reset.')),
        );
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Ensure the loader is closed on error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reset month: $e')));
    }
  }

  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _focusedDay = focusedDay;

      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new selection
        _rangeStart = selectedDay;
        _rangeEnd = null;
        _userSelectedDates.clear();
        _userSelectedDates.add(selectedDay); // 👈 show the first tap
      } else if (_rangeStart != null && _rangeEnd == null) {
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }

        _userSelectedDates.clear();
        DateTime current = _rangeStart!;
        while (!current.isAfter(_rangeEnd!)) {
          _userSelectedDates.add(current);
          current = current.add(Duration(days: 1));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: screenHeight * 0.02,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
            ),
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.01,
              horizontal: screenWidth * 0.05,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 28),
                  ),
                ),
                Center(child: Text("Period Calendar", style: largeText())),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.015,
              ),
              children: [
                if (!_showingSymptomsInput) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TableCalendar(
                          firstDay: _firstDay,
                          lastDay: _lastDay,
                          focusedDay: _focusedDay,
                          onDaySelected: _onDaySelected,
                          onPageChanged: (day) {
                            setState(() {
                              _focusedDay = day;
                            });
                          },
                          selectedDayPredicate:
                              (_) =>
                                  false, // 👈 disables default Flutter selection ring
                          calendarStyle: CalendarStyle(
                            isTodayHighlighted:
                                false, // 👈 disables the highlight on today
                            outsideDaysVisible: false,
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, date, _) {
                              if (_prepopulatedDates.any(
                                (d) => _isSameDay(d, date),
                              )) {
                                return _buildCalendarCell(
                                  date,
                                  const Color.fromARGB(255, 255, 110, 219),
                                );
                              } else if (_userSelectedDates.any(
                                (d) => _isSameDay(d, date),
                              )) {
                                return _buildCalendarCell(
                                  date,
                                  Colors.lightBlue.shade100,
                                );
                              }
                              return null;
                            },
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: largeText(color: Colors.pinkAccent),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              size: 28,
                              color: Colors.pinkAccent,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              size: 28,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _resetCurrentMonth,
                            icon: Icon(Icons.refresh, size: 22),
                            label: Text(
                              "Reset This Month",
                              style: mediumText(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color.fromARGB(
                                255,
                                255,
                                120,
                                165,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        // Add the Cancel and Save buttons here (inside the white container)
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.01,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Cancel',
                                style: mediumText(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Save button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ElevatedButton(
                              // Add your save logic here
                              //Navigator.of(context).pop();
                              onPressed: () async {
                                await _sendFullMonthPeriodData();
                              },

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Save',
                                style: mediumText(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PeriodSymptomsPage(
                    periodId: _selectedPeriodId,
                    onDone: () => _toggleSymptomsInput(false),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildCalendarCell(DateTime date, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      margin: const EdgeInsets.all(4),
      child: Text('${date.day}', style: TextStyle(color: Colors.black)),
    );
  }
}
