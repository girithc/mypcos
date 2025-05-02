import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

void showBodyDataBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
            child: const BodyDataSheetContent(),
          );
        },
      );
    },
  );
}

class BodyDataSheetContent extends StatefulWidget {
  const BodyDataSheetContent({Key? key}) : super(key: key);

  @override
  _BodyDataSheetContentState createState() => _BodyDataSheetContentState();
}

class _BodyDataSheetContentState extends State<BodyDataSheetContent> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _bmiController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _bmiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Header with title and close icon
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
                  child: const Icon(Icons.close, size: 28),
                ),
              ),
              Center(child: Text("Your Body Data", style: largeText())),
            ],
          ),
        ),

        // Form content
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.015,
            ),
            children: [
              _formFieldTile("I am", "years old", _ageController, "24"),
              _formFieldTile("My height is", "cm", _heightController, "165"),
              _formFieldTile("My weight is", "kg", _weightController, "60"),
              _formFieldTile(
                "My waist size is",
                "inches",
                _waistController,
                "28",
              ),
              _formFieldTile("My BMI is", "", _bmiController, "auto or manual"),
            ],
          ),
        ),

        // Save / submit button
        Container(
          margin: EdgeInsets.symmetric(
            vertical: screenHeight * 0.02,
            horizontal: screenWidth * 0.05,
          ),
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
          decoration: BoxDecoration(
            color: secondaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Center(
            child: Text(
              "Save Body Data",
              style: mediumText(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _formFieldTile(
    String prefix,
    String suffix,
    TextEditingController controller,
    String hint,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Text(prefix, style: mediumText()),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                border: const UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Text(suffix, style: mediumText(color: Colors.grey)),
        ],
      ),
    );
  }
}
