import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/components/medical/upload_report.dart';
import 'package:roo_mobile/ui/track/components/period/period_calendar.dart';
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
                child: ActionCard(title: "Drink Water"),
              ),
              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(title: "Take Medicine"),
              ),
              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(title: "Track Steps"),
              ),
            ],
          ),
        ),

        // Section Title
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

        // Secondary Action Cards (2)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.03,
            vertical: screenHeight * 0.015,
          ),
          child: SecondaryActionCard(
            title: "Period Calendar",
            iconsSrc: "assets/icons/calendar.png",
            colorl: Colors.pinkAccent,
            trailingIcon: Icon(Icons.calendar_today),
            onTapCallback: () {
              showPeriodCalendarBottomSheet(context);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.03,
            vertical: screenHeight * 0.015,
          ),
          child: SecondaryActionCard(
            title: "Upload Medical Report",
            iconsSrc: "assets/icons/report.png",
            colorl: Colors.lightBlue,
            trailingIcon: Icon(Icons.upload_file),
            onTapCallback: () {
              showMedicalReportUploadSheet(context, defaultTabIndex: 2);
            },
          ),
        ),

        SizedBox(height: screenHeight * 0.1),
      ],
    );
  }
}
