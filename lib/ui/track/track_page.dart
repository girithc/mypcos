import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/data.dart'
    show categoryActions, secondaryCategoryActions;
import 'package:roo_mobile/ui/track/diet/main.dart';
import 'package:roo_mobile/ui/track/health/data/main.dart';
import 'package:roo_mobile/ui/track/health/main.dart';
import 'package:roo_mobile/ui/track/health/pcos/main.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/ui/track/health/data/main.dart';
import 'package:roo_mobile/utils/constants.dart';

class TrackPage extends StatefulWidget {
  const TrackPage({super.key});

  @override
  State<TrackPage> createState() => _TrackPageState();
}

class _TrackPageState extends State<TrackPage> {
  String selectedCategory = "Period";
  final types = HealthDataCardType.values;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: screenColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false, // 👈 ADD THIS LINE!
        title: Text("MyPCOS", style: largeText(fontWeight: FontWeight.bold)),
        actions: [
          _circleIcon(
            context,
            null,
            showSettingsBottomSheet,
            imageAsset: 'assets/img/profile_pic.png',
          ),
          SizedBox(width: screenWidth * 0.01),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // 👈 Evenly distribute tabs
                children:
                    ["Period", "Data", "PCOS"].map((category) {
                      final isSelected = selectedCategory == category;
                      return GestureDetector(
                        onTap:
                            () => setState(() => selectedCategory = category),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenHeight * 0.03,
                            vertical: screenHeight * 0.0125,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? secondaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(category, style: mediumText()),
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
      ),
    );
  }

  Widget _buildTabCurrentView(BuildContext context) {
    switch (selectedCategory) {
      case "Period":
        return HealthPage();
      case "PCOS":
        return PCOSPage();
      case "Diet":
        return DietPage();
      case "Data":
        return FilePage();
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
                  return Padding(
                    padding: EdgeInsets.only(left: screenHeight * 0.018),
                  );
                }).toList(),
          ),
        ),

        // Secondary Actions
        Padding(
          padding: EdgeInsets.all(screenHeight * 0.03),
          child: Text("Actions", style: largeText()),
        ),

        ...secondaryCategoryActions[selectedCategory]!.map(
          (action) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenHeight * 0.03,
              vertical: screenHeight * 0.015,
            ),
            child: SecondaryActionCard(
              title: Text(action.title, style: mediumText()),
              subtitle: Text("subtitle", style: smallText()),
              icon: Icon(Icons.calendar_today),
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
                  : Icon(icon, color: Colors.pinkAccent.shade200),
        ),
      ),
    );
  }
}
