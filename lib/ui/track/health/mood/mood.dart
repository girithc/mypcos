import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/track/health/period/period_symptoms.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';

void showMoodBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Make background transparent
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9, // Slightly larger initial size
        minChildSize: 0.4,
        maxChildSize: 0.95, // Allow slightly more height
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              // Gradient background applied in MoodTrackerSheetContent now
              color: Colors.transparent, // Make container transparent
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: MoodTrackerSheetContent(
              scrollController: scrollController,
            ), // Your actual content
          );
        },
      );
    },
  );
}

class MoodTrackerSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  const MoodTrackerSheetContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  _MoodTrackerSheetContentState createState() =>
      _MoodTrackerSheetContentState();
}

class _MoodTrackerSheetContentState extends State<MoodTrackerSheetContent>
    with SingleTickerProviderStateMixin {
  final Set<String> selectedMoods = {};
  // Initial list of common moods
  final List<Map<String, String>> moods = [
    {"emoji": "😀", "label": "Happy"},
    {"emoji": "😞", "label": "Sad"},
    {"emoji": "😡", "label": "Angry"},
    {"emoji": "😱", "label": "Anxious"},
    {"emoji": "😌", "label": "Relaxed"},
    // Add more common moods if desired
    {"emoji": "😐", "label": "Neutral"},
    {"emoji": "🤩", "label": "Excited"},
  ];

  // Summary colors (dominant/latest mood per day)
  final Map<DateTime, Color> _moodTrendSummary = {
    DateTime.now().subtract(Duration(days: 6)): Colors.green.shade300, // Happy
    DateTime.now().subtract(Duration(days: 5)): Colors.blue.shade300, // Relaxed
    DateTime.now().subtract(Duration(days: 4)):
        Colors.yellow.shade600, // Neutral
    DateTime.now().subtract(Duration(days: 3)):
        Colors.orange.shade400, // Anxious
    DateTime.now().subtract(Duration(days: 2)): Colors.red.shade300, // Angry
    DateTime.now().subtract(Duration(days: 1)): Colors.green.shade400, // Happy
    DateTime.now(): Colors.grey.shade400, // Sad (Today)
  };

  // Detailed mood log (replace with actual fetched data)
  final Map<DateTime, List<String>> _detailedMoodLog = {
    DateTime.now().subtract(Duration(days: 6)): ["Happy", "Excited"],
    DateTime.now().subtract(Duration(days: 5)): ["Relaxed"],
    DateTime.now().subtract(Duration(days: 4)): [
      "Neutral",
      "Confused",
    ], // Example custom
    DateTime.now().subtract(Duration(days: 3)): ["Anxious", "Sad"],
    DateTime.now().subtract(Duration(days: 2)): ["Angry"],
    DateTime.now().subtract(Duration(days: 1)): [
      "Happy",
      "Relaxed",
      "Grateful",
    ], // Example custom
    DateTime.now(): ["Sad"], // Today
  };
  // Separate list for less common or expandable moods (optional)
  // final List<Map<String, String>> moreMoods = [ ... ];

  // State for custom mood input
  final TextEditingController _customMoodController = TextEditingController();
  bool _showCustomMoodInput = false;

  bool _isLoading = false;
  bool _isSuccess = false;
  late final AnimationController _checkmarkController;

  // Placeholder data for mood trend
  final List<Color> _moodTrendColors = [
    Colors.green.shade300, // Happy
    Colors.blue.shade300, // Relaxed
    Colors.yellow.shade600, // Neutral
    Colors.orange.shade400, // Anxious
    Colors.red.shade300, // Angry
    Colors.green.shade400, // Happy
    Colors.grey.shade400, // Sad
  ];

  @override
  void initState() {
    super.initState();
    _checkmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _customMoodController.dispose(); // Dispose the custom mood controller
    super.dispose();
  }

  // --- Log Moods Function (Modified slightly for custom moods) ---
  Future<void> _logMoods() async {
    if (selectedMoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add at least one mood.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final uri = Uri.parse('${EnvConfig.baseUrl}/mood/log-mood');
    bool allSuccess = true;

    // Create a final list of moods to log (including potential custom ones)
    final List<String> moodsToLog = selectedMoods.toList();

    for (var mood in moodsToLog) {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        // Ensure you handle the case where token might be null
        if (token == null) {
          throw Exception("User not authenticated");
        }
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            // Add Authorization header if your API requires it
            // 'Authorization': 'Bearer $token',
          },
          // Pass token in body OR header based on your API design
          body: jsonEncode({'firebase_token': token, 'mood': mood}),
        );
        if (response.statusCode != 200 && response.statusCode != 201) {
          // Check for 201 Created as well
          print(
            "Error logging mood '$mood': ${response.statusCode} ${response.body}",
          );
          allSuccess = false;
        }
      } catch (e) {
        print("Exception logging mood '$mood': $e");
        allSuccess = false;
      }
    }

    if (!mounted) return;
    if (allSuccess) {
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
      _checkmarkController.forward();
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while logging moods.')),
      );
    }
  }

  // --- Function to add custom mood ---
  void _addCustomMood() {
    final String customMood = _customMoodController.text.trim();
    if (customMood.isNotEmpty && !selectedMoods.contains(customMood)) {
      setState(() {
        // Optionally prefix custom moods to distinguish them later if needed
        // selectedMoods.add("Custom: $customMood");
        selectedMoods.add(customMood);
        _customMoodController.clear();
        _showCustomMoodInput = false; // Hide input after adding
      });
    } else if (customMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom mood.')),
      );
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // --- Main Content ListView ---
    Widget contentListView = ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ), // Adjust padding for keyboard
      children: [
        // --- Handle & Title ---
        Padding(
          padding: EdgeInsets.only(
            top: screenHeight * 0.015, // Reduced top padding
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            bottom: 15, // Added bottom padding
          ),
          // Using Ink for ripple effect on close button
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.03, // Adjusted horizontal padding
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Draggable handle indicator (optional)
                  Positioned(
                    top: -8, // Adjust position
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    // Using InkWell for better tap feedback
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(
                        30,
                      ), // Make ripple circular
                      child: const Padding(
                        padding: EdgeInsets.all(
                          8.0,
                        ), // Add padding for larger tap area
                        child: Icon(
                          Icons.close,
                          size: 24,
                        ), // Slightly smaller icon
                      ),
                    ),
                  ),
                  Text('How Do You Feel?', style: largeText()),
                ],
              ),
            ),
          ),
        ),
        // const SizedBox(height: 15), // Reduced spacing

        // --- Mood Selection Grid ---
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Wrap(
            spacing: 10, // Horizontal space
            runSpacing: 15, // Vertical space
            alignment: WrapAlignment.center,
            children: [
              // Map predefined moods
              ...moods.map((m) => _buildMoodChip(m['emoji']!, m['label']!)),
              // Map selected custom moods (that aren't predefined)
              ...selectedMoods
                  .where((mood) => !moods.any((m) => m['label'] == mood))
                  .map(
                    (customMood) => _buildMoodChip("📝", customMood),
                  ), // Use a generic emoji for custom
              // "Add Custom" Chip/Button
              _buildAddCustomChip(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // --- Custom Mood Input Field (Conditional) ---
        if (_showCustomMoodInput) _buildCustomMoodInput(),
        const SizedBox(height: 20),

        // --- Mood Trend Placeholder Section ---
        _buildMoodTrendPlaceholder(context, screenWidth),
        const SizedBox(height: 30), // Space before button
        // --- Log Button ---
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            // vertical: screenHeight * 0.015, // Removed vertical padding here
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _logMoods,
            style: ElevatedButton.styleFrom(
              elevation: 2, // Added subtle elevation
              backgroundColor: Colors.pinkAccent.shade200,
              foregroundColor: Colors.white, // Set text color explicitly
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ), // Increased padding slightly
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // More rounded
              ),
              minimumSize: Size(
                double.infinity,
                50,
              ), // Ensure button takes full width and has min height
            ),
            // Show loading indicator inside button
            child:
                _isLoading
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      'Log Mood',
                      style: mediumText(
                        color: Colors.white,
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 20), // Space at the bottom inside ListView
      ],
    );

    // --- Main Container with Gradient and Loading/Success states ---
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade100,
            Colors.purple.shade50,
          ], // Softer gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child:
          _isSuccess
              ? Center(
                // Success Animation
                child: ScaleTransition(
                  scale: _checkmarkController.drive(
                    Tween(
                      begin: 0.0,
                      end: 1.0,
                    ).chain(CurveTween(curve: Curves.elasticOut)),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
              )
              : (_isLoading // Loading Shimmer
                  ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    enabled: _isLoading, // Control shimmer state
                    child: IgnorePointer(
                      // Prevent interaction while loading
                      ignoring: true,
                      child: contentListView, // Show structure but greyed out
                    ),
                  )
                  : contentListView // Normal Content
                  ),
    );
  }

  // --- Helper: Build Mood Chip ---
  Widget _buildMoodChip(String emoji, String label) {
    final isSelected = selectedMoods.contains(label);
    return GestureDetector(
      onTap:
          () => setState(() {
            if (isSelected) {
              selectedMoods.remove(label);
            } else {
              selectedMoods.add(label);
              // Optionally hide custom input if a predefined mood is selected
              // if (_showCustomMoodInput) {
              //   _showCustomMoodInput = false;
              // }
            }
          }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // Faster animation
        width: 100,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15), // More rounded
          border: Border.all(
            // Add border for visual distinction
            color:
                isSelected ? Colors.pinkAccent.shade100 : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center, // Center align text if it wraps
              style: TextStyle(
                fontSize: 13, // Slightly smaller font
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.pinkAccent.shade400 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Build "Add Custom" Chip ---
  Widget _buildAddCustomChip() {
    return GestureDetector(
      onTap:
          () => setState(() {
            _showCustomMoodInput =
                !_showCustomMoodInput; // Toggle input field visibility
          }),
      child: Container(
        // Use Container for consistent sizing
        width: 100,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _showCustomMoodInput ? secondaryColor : Colors.grey.shade300,
            width: _showCustomMoodInput ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showCustomMoodInput
                  ? Icons.edit_off_outlined
                  : Icons.add_circle_outline,
              size: 32,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              _showCustomMoodInput ? 'Cancel' : 'Something Else',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Build Custom Mood Input Section ---
  Widget _buildCustomMoodInput() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _customMoodController,
              maxLength: 25, // Limit custom mood length
              decoration: InputDecoration(
                hintText: 'whatsup...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: secondaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                counterText: "", // Hide the counter text
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _addCustomMood,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Icon(Icons.add, color: Colors.pink),
              // Call function to add the mood
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrendPlaceholder(BuildContext context, double screenWidth) {
    // Added context parameter
    // Get the dates for the last 7 days
    final List<DateTime> trendDates =
        List.generate(
          7,
          (index) => DateTime.now().subtract(Duration(days: index)),
        ).reversed.toList();
    final theme = Theme.of(context); // Get theme for colors

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // Title and Details Button
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.center, // Align items vertically
            children: [
              Text(
                "Your Mood Trend",
                style: mediumText(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showDetailedMoodDialog(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  "Details +",
                  style: smallText(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10), // Reduced space
          GestureDetector(
            onTap: () {
              _showDetailedMoodDialog(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    trendDates.map((date) {
                      // Find the summary color for the specific date
                      // Need to compare date only (ignore time)
                      DateTime dateOnly = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                      Color dayColor =
                          Colors.grey.shade200; // Default if no data
                      _moodTrendSummary.forEach((key, value) {
                        if (DateTime(key.year, key.month, key.day) ==
                            dateOnly) {
                          dayColor = value;
                        }
                      });

                      return Column(
                        children: [
                          Container(
                            height: 40,
                            width: 25,
                            decoration: BoxDecoration(
                              color: dayColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat('E').format(
                              date,
                            ), // Format date to day initial (e.g., 'Sat')
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: Function to Show Detailed Mood Dialog (Place inside your State class) ---
  void _showDetailedMoodDialog(BuildContext context) {
    // Added context parameter
    // Get the dates for the last 7 days for the dialog
    final List<DateTime> dialogDates =
        List.generate(
          7,
          (index) => DateTime.now().subtract(Duration(days: index)),
        ).reversed.toList();
    final theme = Theme.of(context); // Get theme for colors

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            "Detailed Mood Log (Last 7 Days)",
            style: largeText(color: Colors.grey.shade800),
            textAlign: TextAlign.center,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            15.0,
            20.0,
            15.0,
            10.0,
          ), // Adjust padding
          content: Container(
            width: double.maxFinite, // Make dialog content use available width
            // Use ConstrainedBox + ListView for scrollable content if it overflows
            child: ListView.separated(
              shrinkWrap: true, // Make ListView take minimum height needed
              itemCount: dialogDates.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade300),
              itemBuilder: (context, index) {
                final date = dialogDates[index];
                final dateOnly = DateTime(date.year, date.month, date.day);
                // Find the moods logged for this specific date
                List<String> moodsForDay = [];
                _detailedMoodLog.forEach((key, value) {
                  if (DateTime(key.year, key.month, key.day) == dateOnly) {
                    moodsForDay = value;
                  }
                });

                // Format the date nicely (e.g., "May 3" or "Yesterday")
                String formattedDate;
                DateTime today = DateTime.now();
                DateTime yesterday = today.subtract(Duration(days: 1));
                if (dateOnly == DateTime(today.year, today.month, today.day)) {
                  formattedDate = "Today";
                } else if (dateOnly ==
                    DateTime(yesterday.year, yesterday.month, yesterday.day)) {
                  formattedDate = "Yesterday";
                } else {
                  formattedDate = DateFormat(
                    'MMM d',
                  ).format(date); // e.g., "May 3"
                }

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 5.0,
                  ),
                  title: Text(
                    formattedDate,
                    style: mediumText(fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      moodsForDay.isNotEmpty
                          ? Padding(
                            // Add padding for wrapped text
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              moodsForDay.join(', '), // Join moods with a comma
                              style: mediumText(color: Colors.grey.shade600),
                            ),
                          )
                          : Text(
                            // Show if no moods were logged
                            'No moods logged',
                            style: mediumText(color: Colors.grey.shade500),
                          ),
                );
              },
            ),
          ),
          actionsAlignment: MainAxisAlignment.center, // Center the close button
          actions: <Widget>[
            TextButton(
              child: Text(
                "Close",
                style: mediumText(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
