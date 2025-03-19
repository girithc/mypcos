import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/bottom_sheet.dart';
import 'package:roo_mobile/ui/chat.dart';
import 'package:roo_mobile/ui/settings.dart';

class Action {
  final String title, description, iconSrc;
  final Color color;

  Action({
    required this.title,
    this.description = 'Build and animate an iOS app from scratch',
    this.iconSrc = "assets/img/profile_pic.png",
    this.color = const Color(0xFF7553F6),
  });
}

final List<Action> Actions = [
  Action(title: "Animate SwiftUI", color: Colors.white),
  Action(
    title: "Animate Flutter",
    iconSrc: "assets/img/profile_pic.png",
    color: const Color.fromARGB(255, 103, 2, 255),
  ),
];

final List<Action> recentActions = [
  Action(title: "State Machine", color: Colors.deepPurpleAccent),
  Action(
    title: "Animated Menu",
    color: Colors.white,
    iconSrc: "assets/img/profile_pic.png",
  ),
  Action(title: "Flutter with Rive"),
  Action(
    title: "Animated Menu",
    color: Colors.white,
    iconSrc: "assets/img/profile_pic.png",
  ),
];

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.title,
    this.color = const Color(0xFF7553F6),
    this.iconSrc = "assets/img/profile_pic.png",
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
        vertical: screenHeight * 0.01,
      ),
      height: screenHeight * 0.2,
      width: screenWidth * 0.4, // Reduced the width here
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.075)),
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
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to the left
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.02,
                      bottom: screenHeight * 0.01,
                    ),
                    child: Text(
                      "Build and animate ",
                      style: TextStyle(color: Colors.deepPurpleAccent),
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

class SecondaryActionCard extends StatelessWidget {
  const SecondaryActionCard({
    super.key,
    required this.title,
    this.iconsSrc = "assets/icons/ios.svg",
    this.colorl = const Color(0xFF7553F6),
  });

  final String title, iconsSrc;
  final Color colorl;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return GestureDetector(
      onTap: () {
        if (title == "Dietary Preferences") {
          showDietaryPreferencesBottomSheet(context);
        } else if (title == "Upload Medical Report") {
          showMedicalReportUploadSheet(context);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: colorl,
          borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.05)),
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
                      color:
                          colorl == Colors.white
                              ? Colors.deepPurpleAccent
                              : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Watch video - 15 mins",
                    style: TextStyle(
                      color:
                          colorl == Colors.white
                              ? Colors.deepPurple
                              : Colors.white60,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 40,
              child: VerticalDivider(color: Colors.white70),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(iconsSrc),
          ],
        ),
      ),
    );
  }
}

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  String selectedCategory = "Trending";

  // Content for each category
  final Map<String, List<Action>> categoryActions = {
    "Trending": Actions,
    "Workout": [
      Action(title: "Yoga", color: Colors.blueAccent),
      Action(title: "HIIT", color: Colors.greenAccent),
    ],
    "Diet": [
      Action(title: "Weight Loss", color: Colors.orangeAccent),
      Action(title: "Meal", color: Colors.pinkAccent),
      Action(title: "Seed Cycling", color: Colors.cyan),
    ],
    "Health": [
      Action(title: "Health Tips", color: Colors.cyan),
      Action(title: "Supplements", color: Colors.deepPurple),
    ],
  };

  // Secondary actions for each category
  final Map<String, List<Action>> secondaryCategoryActions = {
    "Trending": recentActions,
    "Workout": [
      Action(title: "Workout Plan", color: Colors.blueAccent),
      Action(title: "Progress Tracking", color: Colors.greenAccent),
      Action(title: "Body Measurements", color: Colors.purple),
    ],
    "Diet": [
      Action(title: "Set Meal Plan", color: Colors.orangeAccent),
      Action(title: "Dietary Preferences", color: Colors.pinkAccent),
      Action(title: "Nutrition Guide", color: Colors.cyan),
    ],
    "Health": [
      Action(title: "Upload Medical Report", color: Colors.white),
      Action(title: "Body Measurements", color: Colors.purple),
      Action(title: "Fitness Tips", color: Colors.deepPurple),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Top Bar
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ Category Title
                    Text(
                      selectedCategory,
                      style: GoogleFonts.sriracha(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),

                    // ✅ Profile Icons
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 24,
                          child: IconButton(
                            icon: Icon(
                              Icons.calendar_month,
                              size: 26,
                              color: Colors.deepPurpleAccent,
                            ),
                            onPressed: () {
                              showCalendarBottomSheet(context);
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 24,
                          child: GestureDetector(
                            onTap: () {
                              showChatBottomSheet(context);
                            },
                            child: ClipOval(
                              child: Image.asset(
                                'assets/img/profile_pic.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 24,
                          child: GestureDetector(
                            onTap: () {
                              showChatBottomSheet(context);
                            },
                            child: ClipOval(
                              child: Icon(
                                Icons.auto_awesome,
                                color: const Color.fromARGB(255, 106, 0, 255),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ Category Bubbles
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      ["Workout", "Diet", "Health"].map((category) {
                        bool isSelected = selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              // Toggle between selected category and "Trending"
                              selectedCategory =
                                  isSelected ? "Trending" : category;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenHeight * 0.03,
                              vertical: screenHeight * 0.0125,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade100,
                                  blurRadius: 1,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.deepPurpleAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // ✅ Category Content (Actions)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      categoryActions[selectedCategory]!
                          .map(
                            (action) => Padding(
                              padding: EdgeInsets.only(
                                left: screenHeight * 0.018,
                              ),
                              child: ActionCard(
                                title: action.title,
                                iconSrc: action.iconSrc,
                                color: action.color,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(screenHeight * 0.03),
                child: Text(
                  "Actions",
                  style: GoogleFonts.sriracha(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),

              // ✅ List of Secondary Actions (based on selected category)
              ...secondaryCategoryActions[selectedCategory]!.map(
                (action) => Padding(
                  padding: EdgeInsets.only(
                    left: screenHeight * 0.03,
                    right: screenHeight * 0.03,
                    bottom: screenHeight * 0.03,
                  ),
                  child: SecondaryActionCard(
                    title: action.title,
                    iconsSrc: action.iconSrc,
                    colorl: action.color,
                  ),
                ),
              ),

              // Add extra padding or content at the bottom to ensure scrollability
              SizedBox(height: screenHeight * 0.1), // Extra space for scrolling
            ],
          ),
        ),
      ),
    );
  }
}
