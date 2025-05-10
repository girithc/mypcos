import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

void showFeelBetterBottomSheet(BuildContext context, String sampleText) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Make background transparent
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        expand: false,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: FeelBetterSheetContent(
              sampleText: sampleText,
            ), // Your actual content
          );
        },
      );
    },
  );
}

class FeelBetterSheetContent extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String sampleText;
  const FeelBetterSheetContent({
    Key? key,
    this.onBackToHome,
    required this.sampleText,
  }) : super(key: key);

  @override
  _FeelBetterSheetContentState createState() => _FeelBetterSheetContentState();
}

class _FeelBetterSheetContentState extends State<FeelBetterSheetContent> {
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
              Container(
                height: screenHeight * 0.2,
                margin: EdgeInsets.only(top: screenHeight * 0.02),
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: Text(
                    "Eat Well Today",
                    style: largeText(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Container(
                height: screenHeight * 0.2,
                margin: EdgeInsets.only(top: screenHeight * 0.02),
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: Text(
                    "Mindfulness",
                    style: largeText(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Container(
                height: screenHeight * 0.2,
                margin: EdgeInsets.only(top: screenHeight * 0.02),
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.01,
                  horizontal: screenWidth * 0.05,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child: Text(
                    "Exercise Routine",
                    style: largeText(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
            horizontal: screenWidth * 0.05,
          ),
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.01,
            horizontal: screenWidth * 0.05,
          ),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [Center(child: Text("Coming Soon", style: mediumText()))],
          ),
        ),
      ],
    );
  }
}
