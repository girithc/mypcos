import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/ui/components/chat.dart';
import 'package:roo_mobile/ui/track/health/period/period_calendar.dart';
import 'package:roo_mobile/ui/components/settings.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:shimmer/shimmer.dart';

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
        maxChildSize: 0.5, // Maximum height of 75% of screen
        expand: false, // Prevents full-screen expansion
        builder: (BuildContext context, ScrollController scrollController) {
          return SettingsPageContent(scrollController: scrollController);
        },
      );
    },
  );
}

/// Call this function to show the Mood Tracker bottom sheet.

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
