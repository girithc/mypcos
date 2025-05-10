import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

enum HealthDataCardType { steps, calories, exerciseMinutes }

class ActionCard extends StatelessWidget {
  final String title; // Placeholder for sample text
  final Widget titleWidget;
  final Widget indicatorWidget;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.titleWidget,
    required this.indicatorWidget,
    this.backgroundColor = Colors.white,
    this.onTap,
  });

  void _handleTap(BuildContext context, String sampleText) {
    if (onTap != null) {
      onTap!();
    } else {
      // Default action if no onTap provided
      showSampleBottomSheet(context, sampleText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => _handleTap(context, title),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        height: screenHeight * 0.2,
        width: screenWidth * 0.4,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            titleWidget,
            const SizedBox(height: 10),
            Expanded(child: indicatorWidget),
          ],
        ),
      ),
    );
  }
}

void showSampleBottomSheet(BuildContext context, String sampleText) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Make background transparent
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.4,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SampleSheetContent(
              sampleText: sampleText,
            ), // Your actual content
          );
        },
      );
    },
  );
}

class SampleSheetContent extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String sampleText;
  const SampleSheetContent({
    Key? key,
    this.onBackToHome,
    required this.sampleText,
  }) : super(key: key);

  @override
  _SampleSheetContentState createState() => _SampleSheetContentState();
}

class _SampleSheetContentState extends State<SampleSheetContent> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: screenHeight * 0.02,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
          ),
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.01,
            horizontal: screenWidth * 0.05,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, size: 28),
                ),
              ),
              Center(child: Text(widget.sampleText, style: largeText())),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.015,
            ),
            children: [
              SizedBox(height: screenHeight * 0.2),
              ElevatedButton(
                onPressed: () {
                  // Save preferences action
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: secondaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Coming Soon',
                  style: mediumText(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
