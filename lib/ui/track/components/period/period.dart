import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final Set<DateTime> _periodDates = {};
  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDay = DateTime.now().subtract(Duration(days: 3650));
  final DateTime _lastDay = DateTime.now().add(Duration(days: 365));
  DateTime? _selectedDay;
  // 1. Add state variable
  bool _showingSymptomsInput = false;
  void _toggleSymptomsInput(bool value) {
    setState(() {
      _showingSymptomsInput = value;
    });
  }

  List<PeriodLog> _periodLogs = [];
  PeriodLog? _selectedLog;
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

  Future<void> _sendDateSelectionToApi(
    DateTime date,
    Map<String, bool> symptoms,
    String notes,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/period-update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'selected_date': date.toIso8601String(),
          'symptoms': symptoms,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        print("Data sent successfully.");
      } else {
        print("Failed to send data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending data: $e");
    }
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

  String _monthName(int month) {
    const months = [
      '', // index 0 placeholder
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month];
  }

  Widget _buildSymptomsInput() {
    final sortedDates = _periodDates.toList()..sort((a, b) => a.compareTo(b));
    final startDate = sortedDates.isNotEmpty ? sortedDates.first : null;
    final endDate = sortedDates.isNotEmpty ? sortedDates.last : null;

    String formatDate(DateTime? date) {
      if (date == null) return '';
      return "${_monthName(date.month)} ${date.day}";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (startDate != null && endDate != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${formatDate(startDate)} - ${formatDate(endDate)}",
                style: mediumText(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            'How Did You Feel ?',
            style: largeText(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _symptomOptions.map((symptom) {
                  return FilterChip(
                    selectedColor: const Color.fromARGB(255, 255, 152, 253),
                    label: Text(
                      symptom,
                      style: mediumText(color: Colors.black),
                    ),
                    selected: _selectedSymptoms[symptom] ?? false,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedSymptoms[symptom] = selected;
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 48),
          Text(
            'Anything Else ?',
            style: largeText(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            style: mediumText(color: Colors.black),
            maxLines: 3,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter any additional notes...',
              hintStyle: mediumText(),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedLayerButton(
              onClick: () {
                _sendDateSelectionToApi(
                  _selectedDay!,
                  _selectedSymptoms,
                  _notesController.text,
                );
                _toggleSymptomsInput(false);
              },
              buttonHeight: 60,
              buttonWidth: 270,
              animationDuration: const Duration(milliseconds: 200),
              animationCurve: Curves.ease,
              topDecoration: BoxDecoration(
                color: Colors.pinkAccent,
                border: Border.all(),
              ),
              topLayerChild: Text(
                "Done",
                style: largeText(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              baseDecoration: BoxDecoration(
                color: Colors.deepPurple,
                border: Border.all(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<PeriodLog> monthLogs = _periodLogs;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                                (day) =>
                                    _periodDates.any((d) => _isSameDay(d, day)),
                            onDaySelected: _onDaySelected,
                            onPageChanged: (day) {
                              _focusedDay = day;
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
                    if (_selectedDay != null) ...[
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: EdgeInsets.symmetric(vertical: 12),
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
                                  onPressed: () => _toggleSymptomsInput(true),

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
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
                    _buildSymptomsInput(),
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
