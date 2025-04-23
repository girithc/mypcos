import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/components/chat.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/components/period/period_calendar.dart';
import 'package:roo_mobile/ui/track/health/main.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/ui/track/data.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  String selectedCategory = "Health";
  final types = HealthDataCardType.values;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white, // match Scaffold background if needed
        elevation: 0,
        automaticallyImplyLeading: false, // disables default back button
        title: Text(
          selectedCategory,
          style: GoogleFonts.sriracha(
            fontSize: 32, // Slightly smaller for AppBar
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        actions: [
          _circleIcon(context, Icons.calendar_month, showCalendarBottomSheet),
          _circleIcon(
            context,
            null,
            showSettingsBottomSheet,
            imageAsset: 'assets/img/profile_pic.png',
          ),
          _circleIcon(context, Icons.auto_awesome, showChatBottomSheet),
          const SizedBox(width: 12), // spacing at end
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenHeight * 0.03,
              vertical: screenHeight * 0.02,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  ["Health", "Diet", "Workout"].map((category) {
                    final isSelected = selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = category),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildTabCurrentView(context),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            layoutBuilder:
                (currentChild, previousChildren) => Stack(
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabCurrentView(BuildContext context) {
    switch (selectedCategory) {
      case "Health":
        return HealthPage();
      case "Diet":
        return defaultTabView(context);
      case "Workout":
        return defaultTabView(context);
      default:
        return defaultTabView(context);
    }
  }

  Widget defaultTabView(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                categoryActions[selectedCategory]!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  final rotatedType = types[index % types.length];

                  return Padding(
                    padding: EdgeInsets.only(left: screenHeight * 0.018),
                    child: ActionCard(title: action.title, type: rotatedType),
                  );
                }).toList(),
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
              onTapCallback:
                  action.title == "Period Calendar"
                      ? () => setState(() => selectedCategory = "Period")
                      : action.title == "Upload Medical Report"
                      ? () => setState(() => selectedCategory = "Medical")
                      : null,
            ),
          ),
        ),

        SizedBox(height: screenHeight * 0.1),
      ],
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
