import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/components/medical/upload_report.dart';
import 'package:roo_mobile/ui/track/health/diet/main.dart';
import 'package:roo_mobile/ui/track/health/mood/mood.dart';
import 'package:roo_mobile/ui/track/health/period/feel_better.dart';
import 'package:roo_mobile/ui/track/health/period/next_cycle.dart';
import 'package:roo_mobile/ui/track/health/period/period_calendar.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/utils/constants.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
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
                  title: "Next Cycle",
                  titleWidget: Text(
                    "Next Cycle",
                    style: largeText(color: titleColor),
                  ),
                  indicatorWidget: CountdownRoundedIndicator(
                    predictedDate: DateTime.now().add(Duration(days: 12)),
                    daysLeft: 12,
                    progress: 0.6,
                    ringColor: Colors.pinkAccent,
                    backgroundRingColor: Colors.pinkAccent.withOpacity(0.4),
                  ),
                  onTap: () {
                    showNextCycleBottomSheet(context, "Next Cycle");
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(
                  title: "Feel Better",
                  titleWidget: Text(
                    "Feel Better",
                    style: largeText(color: titleColor),
                  ),
                  indicatorWidget: FeelBetterIndicator(
                    message: "Self-care",
                    icon1: Icons.self_improvement,
                    icon2: Icons.trending_up, // or Icons.favorite
                    backgroundColor: Colors.pink.shade50,
                    iconColor: Colors.pinkAccent,
                  ),
                  onTap:
                      () => {showFeelBetterBottomSheet(context, "Feel Better")},
                ),
              ),
            ],
          ),
        ),

        // Section Title
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.03,
            vertical: screenHeight * 0.02,
          ),
          child: Text("Actions", style: largeText(fontWeight: FontWeight.bold)),
        ),

        // Secondary Action Cards (2)
        SecondaryActionCard(
          title: Text("Period Calendar", style: mediumText()),
          subtitle: Text(
            "track your period",
            style: smallText(color: textColor),
          ),
          icon: Icon(Icons.calendar_today, color: iconColor),
          colorl: Colors.white,
          onTapCallback: () {
            showPeriodCalendarBottomSheet(context);
          },
        ),
        SecondaryActionCard(
          title: Text("How do you feel", style: mediumText()),
          subtitle: Text("track you mood", style: smallText(color: textColor)),
          icon: Icon(Icons.mood, color: iconColor),
          colorl: Colors.white,
          onTapCallback: () {
            showMoodBottomSheet(context);
          },
        ),
        SecondaryActionCard(
          title: Text("Diet Choices", style: mediumText()),
          subtitle: Text(
            "dietary preferences",
            style: smallText(color: textColor),
          ),
          icon: Icon(Icons.fastfood_outlined, color: iconColor),
          colorl: Colors.white,
          onTapCallback: () {
            showDietaryPreferencesBottomSheet(context);
          },
        ),
        SizedBox(height: screenHeight * 0.1),
      ],
    );
  }
}

class CountdownRoundedIndicator extends StatelessWidget {
  final DateTime predictedDate;
  final int daysLeft;
  final double progress; // 0.0 to 1.0
  final double width;
  final double height;
  final Color ringColor;
  final Color backgroundRingColor;
  final TextStyle? dateTextStyle;
  final TextStyle? daysLeftTextStyle;

  const CountdownRoundedIndicator({
    Key? key,
    required this.predictedDate,
    required this.daysLeft,
    required this.progress,
    this.width = 120,
    this.height = 70,
    this.ringColor = Colors.deepPurpleAccent,
    this.backgroundRingColor = Colors.deepPurple,
    this.dateTextStyle,
    this.daysLeftTextStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('MMM d').format(predictedDate);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Rectangle
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pinkAccent.shade100, width: 4),
          ),
        ),
        // Progress Overlay
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.pinkAccent.shade100,
            ),
            minHeight: height,
          ),
        ),
        // Text Content
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedDate,
              style: mediumText(
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text("$daysLeft days", style: smallText()),
          ],
        ),
      ],
    );
  }
}

class FeelBetterIndicator extends StatelessWidget {
  final String message;
  final IconData icon1;

  final IconData icon2;
  final Color backgroundColor;
  final Color? iconColor;
  final TextStyle? textStyle;

  const FeelBetterIndicator({
    Key? key,
    this.message = "Self-care",
    this.icon1 = Icons.spa,
    this.icon2 = Icons.favorite,
    this.backgroundColor = const Color(0xFFFFF0F5),
    this.iconColor,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: FittedBox(
          // 👈 FittedBox is the key
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon1, size: 28, color: iconColor ?? Colors.pinkAccent),
              const SizedBox(width: 4),
              Icon(icon2, size: 28, color: iconColor ?? Colors.pinkAccent),
            ],
          ),
        ),
      ),
    );
  }
}
