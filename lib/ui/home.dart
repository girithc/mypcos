import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/bottom_sheet.dart';

class Course {
  final String title, description, iconSrc;
  final Color color;

  Course({
    required this.title,
    this.description = 'Build and animate an iOS app from scratch',
    this.iconSrc = "assets/img/google.png",
    this.color = const Color(0xFF7553F6),
  });
}

final List<Course> courses = [
  Course(title: "Animations in SwiftUI", color: Colors.white),
  Course(
    title: "Animations in Flutter",
    iconSrc: "assets/img/google.png",
    color: const Color.fromARGB(255, 103, 2, 255),
  ),
];

final List<Course> recentCourses = [
  Course(title: "Track Periods", color: Colors.deepPurpleAccent),
  Course(
    title: "How Are You Feeling ?",
    color: Colors.white,
    iconSrc: "assets/img/google.png",
  ),
  Course(title: "Progress <>"),
];

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.title,
    this.color = const Color(0xFF7553F6),
    this.iconSrc = "assets/img/google.png",
  });

  final String title, iconSrc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      height: screenHeight * 0.35,
      width: screenWidth * 0.5, // Reduced the width here
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.03)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.015,
                right: screenWidth * 0.02,
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color:
                          color == Colors.white
                              ? Colors.deepPurpleAccent
                              : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.02,
                      bottom: screenHeight * 0.01,
                    ),
                    child: Text(
                      "Build and animate an iOS app from scratch",
                      style: TextStyle(
                        color:
                            color == Colors.white
                                ? Colors.deepPurple
                                : Colors.white38,
                      ),
                    ),
                  ),
                  const Text(
                    "61 SECTIONS - 11 HOURS",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Transform.translate(
                        offset: Offset((-10 * index).toDouble(), 0),
                        child: CircleAvatar(
                          radius: screenWidth * 0.06,
                          backgroundImage: AssetImage(
                            "assets/img/profile_pic.png",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecondaryCourseCard extends StatelessWidget {
  const SecondaryCourseCard({
    Key? key,
    required this.title,
    this.iconsSrc = "assets/img/google.png",
    this.colorl = const Color(0xFF7553F6),
    this.index,
  }) : super(key: key);

  final String title, iconsSrc;
  final Color colorl;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Define a list of custom colors for the trailing icon.
    final List<Color> trailingColors = [
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];

    // Define a list of custom trailing icons.
    final List<IconData> trailingIcons = [
      Icons.star,
      Icons.favorite,
      Icons.lightbulb,
      Icons.ac_unit,
      Icons.access_alarm,
    ];

    // Use the given index (defaulting to 0) to choose the trailing color and icon.
    final int currentIndex = index ?? 0;
    final Color trailingColor =
        trailingColors[currentIndex % trailingColors.length];
    final IconData trailingIcon =
        trailingIcons[currentIndex % trailingIcons.length];

    return GestureDetector(
      onTap: () {
        if (title.toLowerCase().contains('period')) {
          showPeriodCalendarBottomSheet(context);
        } else if (title.toLowerCase().contains('feeling')) {
          showMoodTrackerBottomSheet(context);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.02)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Colors.deepPurpleAccent.shade200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Watch video - 15 mins",
                    style: TextStyle(
                      color: Colors.deepPurpleAccent.shade100,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            // Trailing circle showing rotating color and icon.
            CircleAvatar(
              backgroundColor: Colors.deepPurpleAccent.shade100,
              radius: 16,
              child: Icon(Icons.airplane_ticket, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Example implementation for showMoodTrackerBottomSheet.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    print(FirebaseAuth.instance.currentUser.toString());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    double scrollOffset = _scrollController.offset;
    double cardWidth =
        MediaQuery.of(context).size.width * 0.1 +
        MediaQuery.of(context).size.height * 0.03; // Card width + padding

    int newIndex = (scrollOffset / cardWidth).round();

    if (newIndex != _focusedIndex && newIndex < courses.length) {
      setState(() {
        _focusedIndex = newIndex;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 221, 255),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.03),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween, // Ensures text and icon are at opposite ends
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          "Trending",
                      style: GoogleFonts.sriracha(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),

                    // Reduced padding around the CircleAvatar
                    CircleAvatar(
                      backgroundColor:
                          Colors.white, // Set background color to black
                      radius: 18, // Reduced radius for smaller circle
                      child: IconButton(
                        icon: Icon(
                          Icons.woman,
                          size: 20,
                          color:
                              Colors
                                  .deepPurpleAccent, // Change icon color to white for contrast
                        ),
                        onPressed: () {
                          showSettingsBottomSheet(context);
                          // Navigate to the Settings page when the icon is pressed
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      courses.asMap().entries.map((entry) {
                        int index = entry.key;
                        var course = entry.value;
                        bool isFocused = index == _focusedIndex;

                        return Padding(
                          padding: EdgeInsets.only(left: screenHeight * 0.03),
                          child: CourseCard(
                            title: course.title,
                            iconSrc: course.iconSrc,
                            color: isFocused ? Color(0xFF7553F6) : Colors.white,
                          ),
                        );
                      }).toList(),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.03),
                child: Text(
                  "Actions",
                  style: GoogleFonts.sriracha(
                    // ✅ Apply Rock Salt font
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              ...recentCourses.map(
                (course) => Padding(
                  padding: EdgeInsets.only(
                    left: screenHeight * 0.03,
                    right: screenHeight * 0.03,
                    bottom: screenHeight * 0.03,
                  ),
                  child: SecondaryCourseCard(title: course.title),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: screenHeight * 0.12,
        ), // Lift button by 12% of screen height
      ), // Adjust location if needed
    );
  }
}
