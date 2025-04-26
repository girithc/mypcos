import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/ui/components/chat.dart';
import 'package:roo_mobile/ui/track/health/period/period_calendar.dart';
import 'package:roo_mobile/ui/components/settings.dart';
import 'package:roo_mobile/utils/constants.dart';

void showCalendarBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ), // Curved top borders
    ),
    builder: (BuildContext context) {
      return Container(
        height:
            MediaQuery.of(context).size.height * 0.5, // 70% of screen height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white, // Background color of the bottom sheet
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with "Calendar" and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calendar',
                    style: GoogleFonts.sriracha(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 106, 0, 255),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: const Color.fromARGB(255, 106, 0, 255),
                    ),
                    onPressed:
                        () => Navigator.of(context).pop(), // Close action
                  ),
                ],
              ),
            ),

            // CalendarTimeline widget
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CalendarTimeline(
                initialDate: DateTime.now(), // Set initial date to today
                firstDate: DateTime(DateTime.now().year - 1), // One year ago
                lastDate: DateTime(DateTime.now().year + 1), // One year ahead
                onDateSelected: (date) {
                  print("Selected Date: $date"); // Handle date selection
                },
                leftMargin: 20,
                monthColor: Colors.blueGrey,
                dayColor: Colors.teal[200],
                activeDayColor: Colors.white,
                activeBackgroundDayColor: Colors.redAccent[100],
                selectableDayPredicate:
                    (date) => true, // Allow all dates to be selectable
                locale: 'en_ISO',
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Text("Tasks To Do", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
    },
  );
}

class ProgressTrackerContainer extends StatefulWidget {
  final String? selectedFileName;

  const ProgressTrackerContainer({Key? key, this.selectedFileName})
    : super(key: key);

  @override
  _ProgressTrackerContainerState createState() =>
      _ProgressTrackerContainerState();
}

class _ProgressTrackerContainerState extends State<ProgressTrackerContainer> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.selectedFileName != null) {
      _startProgress();
    }
  }

  void _startProgress() {
    _timer = Timer.periodic(Duration(milliseconds: 20), (timer) {
      setState(() {
        if (_progress < 100) {
          _progress += 1.0;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.1,
      decoration: BoxDecoration(
        color: Colors.white, // White background
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4), // Rounded borders
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 106, 0, 255), // Purple shadow
            offset: Offset(5, 5), // Shifted to the right and bottom
            blurRadius: 2, // Shadow blur
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Leading widget: File icon or green circle with checkmark
          Icon(Icons.insert_drive_file, size: 40, color: Colors.grey[700]),
          SizedBox(
            width: 16,
          ), // Spacing between leading widget and progress bar
          // Middle: Progress tracker
          Expanded(
            child: LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          SizedBox(
            width: 16,
          ), // Spacing between progress bar and trailing widget
          // Trailing widget: Green circle with checkmark (only visible when progress is 100)
          _progress >= 100
              ? Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green, // Green circle
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.white,
                ), // White checkmark
              )
              : Icon(Icons.sync, size: 30, color: Colors.grey[700]),
        ],
      ),
    );
  }
}

void showSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5, // Start at 50% of screen height
        minChildSize: 0.4, // Minimum height of 25% of screen
        maxChildSize: 0.9, // Maximum height of 75% of screen
        expand: false, // Prevents full-screen expansion
        builder: (BuildContext context, ScrollController scrollController) {
          return SettingsPageContent(scrollController: scrollController);
        },
      );
    },
  );
}

/// Call this function to show the Mood Tracker bottom sheet.
void showMoodTrackerBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return SizedBox(
        height:
            MediaQuery.of(context).size.height * 0.95, // allow enough height
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.7,
          maxChildSize: 0.9,
          expand: true,
          builder: (BuildContext context, ScrollController scrollController) {
            return MoodTrackerSheetContent(scrollController: scrollController);
          },
        ),
      );
    },
  );
}

/// The content widget for the Mood Tracker bottom sheet.
class MoodTrackerSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  const MoodTrackerSheetContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  _MoodTrackerSheetContentState createState() =>
      _MoodTrackerSheetContentState();
}

class _MoodTrackerSheetContentState extends State<MoodTrackerSheetContent> {
  // Change from a single selected mood to a set of selected moods.
  final Set<String> selectedMoods = {};

  final List<Map<String, String>> moods = [
    {"emoji": "😀", "label": "Happy"},
    {"emoji": "😞", "label": "Sad"},
    {"emoji": "😡", "label": "Angry"},
    {"emoji": "😱", "label": "Anxious"},
    {"emoji": "😌", "label": "Relaxed"},
    {"emoji": "😔", "label": "Disappointed"},
    {"emoji": "😐", "label": "Neutral"},
    {"emoji": "🤩", "label": "Excited"},
    {"emoji": "😕", "label": "Confused"},
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      // Gradient background with rounded top corners.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Small handle at the top.
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
                Center(child: Text("How Do You Feel ?", style: largeText())),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Wrap the mood options in a responsive layout.
          Wrap(
            spacing: 10,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children:
                moods.map((mood) {
                  final bool isSelected = selectedMoods.contains(mood['label']);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selectedMoods.contains(mood['label'])) {
                          selectedMoods.remove(mood['label']);
                        } else {
                          selectedMoods.add(mood['label']!);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                                : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood['label']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 30),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.015,
            ),
            child: ElevatedButton(
              onPressed: () {
                // Save preferences action
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.pinkAccent.shade200,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Coming Soon',
                style: mediumText(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

void showChatBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ), // 👈 Rounded top
            ),
            clipBehavior: Clip.antiAlias, // 👈 Ensures content respects radius
            child:
                ChatPage(), // ⬅️ Replace with the actual chat widget if needed
          );
        },
      );
    },
  );
}
