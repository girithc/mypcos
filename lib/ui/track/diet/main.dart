import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/components/medical/upload_report.dart';
import 'package:roo_mobile/ui/track/health/period/period_calendar.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/utils/constants.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Cards (3)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(
                  title: "AI Diet Plan",
                  titleWidget: Text("AI Diet Plan", style: largeText()),
                  indicatorWidget: Text("12 Days", style: mediumText()),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(
                  title: "AI Workout Plan",
                  titleWidget: Text("AI Workout Plan", style: largeText()),
                  indicatorWidget: Text("12 Steps", style: mediumText()),
                ),
              ),
            ],
          ),
        ),

        // Section Title
        Padding(
          padding: EdgeInsets.all(screenHeight * 0.03),
          child: Text(
            "Files",
            style: GoogleFonts.sriracha(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),

        // Secondary Action Cards (2)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.03,
            vertical: screenHeight * 0.015,
          ),
          child: SecondaryActionCard(
            title: Text("Period Calendar", style: mediumText()),
            subtitle: Text("subtitle", style: smallText()),
            icon: Icon(Icons.calendar_today),
            colorl: Colors.pinkAccent,
            trailingIcon: Icon(Icons.calendar_today),
            onTapCallback: () {
              showPeriodCalendarBottomSheet(context);
            },
          ),
        ),

        SizedBox(height: screenHeight * 0.1),
      ],
    );
  }
}
