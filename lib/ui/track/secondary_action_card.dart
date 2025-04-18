import 'package:flutter/material.dart';
import 'package:roo_mobile/ui/bottom_sheet.dart';
import 'package:roo_mobile/ui/track/components/period/period_calendar.dart';

class SecondaryActionCard extends StatelessWidget {
  const SecondaryActionCard({
    super.key,
    required this.title,
    this.iconsSrc = "assets/img/google.png",
    this.colorl = const Color(0xFF7553F6),
    this.trailingIcon,
  });

  final String title, iconsSrc;
  final Color colorl;
  final Widget? trailingIcon; // New optional icon widget

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return GestureDetector(
      onTap: () async {
        if (title == "Period Calendar") {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                expand: false,
                builder: (
                  BuildContext context,
                  ScrollController scrollController,
                ) {
                  return PeriodCalendarSheetContent(
                    scrollController: scrollController,
                  );
                },
              );
            },
          );
        } else if (title == "How Do You Feel ?") {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.65,
                minChildSize: 0.5,
                maxChildSize: 0.8,
                expand: false,
                builder: (
                  BuildContext context,
                  ScrollController scrollController,
                ) {
                  return MoodTrackerSheetContent(
                    scrollController: scrollController,
                  );
                },
              );
            },
          );
        } else if (title == "Dietary Preferences") {
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
            const SizedBox(width: 12),
            trailingIcon!,
          ],
        ),
      ),
    );
  }
}
