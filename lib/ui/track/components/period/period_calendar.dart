import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roo_mobile/ui/track/components/period/period_symptoms.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:simple_animated_button/elevated_layer_button.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PeriodLog {
  final List<DateTime> days;
  final Map<String, bool> symptoms;
  String notes;

  PeriodLog({required this.days, Map<String, bool>? symptoms, this.notes = ''})
    : symptoms = symptoms ?? {};
}

class PeriodCalendarSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const PeriodCalendarSheetContent({Key? key, required this.scrollController})
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
  DateTime? _selectedDay;
  bool _isLoading = true; // 1) loading flag

  // 1. Add state variable
  bool _showingSymptomsInput = false;
  int _selectedPeriodId = 0;
  void _toggleSymptomsInput(bool value) {
    setState(() {
      _showingSymptomsInput = value;
    });
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
    List<DateTime> sortedDates = List.from(_periodDates)..sort();

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
        Uri.parse('${EnvConfig.baseUrl}/period-calendar-update'),
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
        Uri.parse('${EnvConfig.baseUrl}/period-calendar-get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': token}),
      );

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

  void _resetCurrentMonth() {
    setState(() {
      _periodDates.removeWhere(
        (date) =>
            date.year == _focusedDay.year && date.month == _focusedDay.month,
      );
      _selectedDay = null;
    });
  }

  bool _hasDatesThisMonth() {
    return _periodDates.any(
      (d) => d.year == _focusedDay.year && d.month == _focusedDay.month,
    );
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _focusedDay = focusedDay;
      _selectedDay = selectedDay;
      bool isAlreadySelected = _periodDates.any(
        (d) => _isSameDay(d, selectedDay),
      );
      DateTime previousDay = selectedDay.subtract(Duration(days: 1));
      DateTime nextDay = selectedDay.add(Duration(days: 1));
      bool hasAdjacentBefore = _periodDates.any(
        (d) => _isSameDay(d, previousDay),
      );
      bool hasAdjacentAfter = _periodDates.any((d) => _isSameDay(d, nextDay));

      if (!isAlreadySelected && !hasAdjacentBefore && !hasAdjacentAfter) {
        for (int i = 0; i < 5; i++) {
          _periodDates.add(selectedDay.add(Duration(days: i)));
        }
      } else {
        if (isAlreadySelected) {
          _periodDates.removeWhere((d) => _isSameDay(d, selectedDay));
        } else {
          _periodDates.add(selectedDay);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      );
    } else {
      return Theme(
        data: Theme.of(context).copyWith(
          textTheme: GoogleFonts.srirachaTextTheme(
            Theme.of(context).textTheme,
          ).apply(fontSizeFactor: 1.25),
        ),
        child: Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Periods :))',
                      style: largeText(
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
                              selectedDayPredicate:
                                  (day) => _periodDates.any(
                                    (d) => _isSameDay(d, day),
                                  ),
                              onDaySelected: _onDaySelected,
                              onPageChanged: (day) {
                                setState(() {
                                  _focusedDay = day;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                isTodayHighlighted: true,
                                selectedDecoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  shape: BoxShape.circle,
                                ),
                                todayDecoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                weekendTextStyle: TextStyle(
                                  color: Colors.redAccent,
                                ),
                                outsideDaysVisible: false,
                              ),
                              headerStyle: HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                leftChevronIcon: Icon(
                                  Icons.chevron_left,
                                  size: 28,
                                  color: Colors.black,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right,
                                  size: 28,
                                  color: Colors.black,
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
                                  style: TextStyle(fontSize: 18),
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
                      if (_hasDatesThisMonth()) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Cancel button
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                              // Save button
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
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
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Save',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
          ),
        ),
      );
    }
  }
}
