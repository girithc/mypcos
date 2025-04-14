import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/bottom_sheet.dart';
import 'package:roo_mobile/ui/chat.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/ui/track/data.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  String selectedCategory = "Trending";

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
              // Header
              Padding(
                padding: EdgeInsets.all(screenHeight * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCategory,
                      style: GoogleFonts.sriracha(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        _circleIcon(
                          context,
                          Icons.calendar_month,
                          showCalendarBottomSheet,
                        ),
                        _circleIcon(
                          context,
                          null,
                          showSettingsBottomSheet,
                          imageAsset: 'assets/img/profile_pic.png',
                        ),
                        _circleIcon(
                          context,
                          Icons.auto_awesome,
                          showChatBottomSheet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Category Selector
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      ["Workout", "Diet", "Health"].map((category) {
                        final isSelected = selectedCategory == category;
                        return GestureDetector(
                          onTap:
                              () => setState(
                                () =>
                                    selectedCategory =
                                        isSelected ? "Trending" : category,
                              ),
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

              // Horizontal Primary Actions
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

              // Secondary Actions
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

              ...secondaryCategoryActions[selectedCategory]!.map(
                (action) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHeight * 0.03,
                    vertical: screenHeight * 0.015,
                  ),
                  child: SecondaryActionCard(
                    title: action.title,
                    iconsSrc: action.iconSrc,
                    colorl: action.color,
                    trailingIcon: action.icon,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(
    BuildContext context,
    IconData? icon,
    Function(BuildContext) onTap, {
    String? imageAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 24,
        child: GestureDetector(
          onTap: () => onTap(context),
          child:
              imageAsset != null
                  ? ClipOval(
                    child: Image.asset(
                      imageAsset,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                  : Icon(icon, color: Colors.deepPurpleAccent),
        ),
      ),
    );
  }
}
