import 'dart:async';

import 'package:calendar_timeline/calendar_timeline.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/chat.dart';
import 'package:roo_mobile/ui/track/components/period/period_calendar.dart';
import 'package:roo_mobile/ui/settings.dart';

void showDietaryPreferencesBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return DietaryPreferencesContent();
    },
  );
}

class DietaryPreferencesContent extends StatefulWidget {
  @override
  _DietaryPreferencesContentState createState() =>
      _DietaryPreferencesContentState();
}

class _DietaryPreferencesContentState extends State<DietaryPreferencesContent> {
  // Define the dietary preferences and their initial states
  Map<String, bool> preferences = {
    'Gluten-Free': false,
    'Vegetarian': false,
    'Dairy-Free': false,
    'Nut-Free': false,
    'Vegan': false,
  };

  // List of PCOS-friendly foods
  final List<String> pcosFriendlyFoods = [
    'Avocado',
    'Berries',
    'Leafy Greens',
    'Salmon',
    'Chia Seeds',
    'Flaxseeds',
    'Nuts',
    'Eggs',
    'Quinoa',
    'Lentils',
    'Turmeric',
    'Cinnamon',
    'Sweet Potatoes',
    'Zucchini',
    'Broccoli',
  ];

  Set<String> selectedFoods = {}; // Store selected chips

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dietary Preferences',
                style: GoogleFonts.sriracha(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 106, 0, 255),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.deepPurple),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Preferences List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preferences List
                  Column(
                    children:
                        preferences.keys.map((String key) {
                          return SwitchListTile(
                            inactiveTrackColor: Colors.white,
                            inactiveThumbColor: Colors.black,
                            activeTrackColor: Color.fromARGB(255, 106, 0, 255),
                            activeColor: Colors.white,
                            title: Text(
                              key,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            value: preferences[key]!,
                            onChanged: (bool value) {
                              setState(() {
                                preferences[key] = value;
                              });
                            },
                          );
                        }).toList(),
                  ),

                  SizedBox(height: 20),

                  // Chips for PCOS-friendly foods
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children:
                        pcosFriendlyFoods.map((food) {
                          return ChoiceChip(
                            label: Text(
                              food,
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    selectedFoods.contains(food)
                                        ? Colors.white
                                        : Colors
                                            .black, // Change text color dynamically
                              ),
                            ),
                            selected: selectedFoods.contains(food),
                            selectedColor: Color.fromARGB(
                              255,
                              106,
                              0,
                              255,
                            ), // Purple when selected
                            backgroundColor:
                                Colors.grey[50], // Light grey when unselected
                            checkmarkColor:
                                Colors.white, // White tick mark when selected
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedFoods.add(food);
                                } else {
                                  selectedFoods.remove(food);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),

                  SizedBox(height: 20),

                  // Save Button
                ],
              ),
            ),
          ),
          // Save Button
        ],
      ),
    );
  }
}

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

void showMedicalReportUploadSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.3, // Initial height as a fraction of screen height
        minChildSize: 0.2, // Minimum height
        maxChildSize: 0.9, // Maximum height when fully expanded
        expand: false,
        builder: (context, scrollController) {
          return MedicalReportUploadContent(scrollController: scrollController);
        },
      );
    },
  );
}

class MedicalReportUploadContent extends StatefulWidget {
  final ScrollController scrollController;

  const MedicalReportUploadContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  _MedicalReportUploadContentState createState() =>
      _MedicalReportUploadContentState();
}

class _MedicalReportUploadContentState
    extends State<MedicalReportUploadContent> {
  String? selectedFileName;

  Future<void> _pickFile() async {
    // Simulating file picker (Replace this with actual file picker logic)
    setState(() {
      selectedFileName = "medical_report.pdf"; // Mock file selection
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController, // Make it scrollable
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),

        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical Report',
                  style: GoogleFonts.sriracha(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 106, 0, 255),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.deepPurple),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Upload Button
            Center(
              child: DottedBorder(
                color: Colors.deepPurple, // Dotted border color
                strokeWidth: 2, // Border thickness
                dashPattern: [8, 4], // Dash pattern (8px dash, 4px gap)
                borderType: BorderType.RRect, // Rounded rectangle border
                radius: Radius.circular(8),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: Icon(
                      Icons.upload_file,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      'Upload File',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 106, 0, 255),
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 36,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Show selected file name with progress tracker
            if (selectedFileName != null)
              ProgressTrackerContainer(selectedFileName: selectedFileName),

            SizedBox(height: 30),

            // Save Button
          ],
        ),
      ),
    );
  }
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

void showPeriodCalendarBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey.shade200, // To allow the gradient to show
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize:
            0.8, // Increased from 0.75 so more content appears immediately
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return PeriodCalendarSheetContent();
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
    return Container(
      // Gradient background with rounded top corners.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade100, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Small handle at the top.
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "How's Your Moooood?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          ElevatedButton(
            onPressed: () {
              debugPrint('Moods selected: ${selectedMoods.toList()}');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Center(
              child: Text("Save Mood", style: TextStyle(fontSize: 18)),
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ), // Curved top borders
    ),
    builder: (BuildContext context) {
      return Container(
        height:
            MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white, // Background color of the bottom sheet
        ),
        child: Column(
          children: [
            // Header with "Roo" and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROO',
                    style: GoogleFonts.sriracha(
                      // ✅ Use Rock Salt from Google Fonts
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

            // ChatPage with curved borders
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ChatPage(), // Your chatPage widget
              ),
            ),
          ],
        ),
      );
    },
  );
}
