import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roo_mobile/utils/constants.dart';
import 'package:shimmer/shimmer.dart';

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

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchBodyData();
  }

  Future<void> _fetchBodyData() async {
    setState(() => isLoading = true);
    final token =
        await FirebaseAuth.instance.currentUser
            ?.getIdToken(); // You should implement this
    final response = await http.post(
      Uri.parse('${EnvConfig.baseUrl}/body-data/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"firebase_token": token}),
    );
    final data = jsonDecode(response.body)["body_data"];

    void updateController(TextEditingController controller, dynamic value) {
      controller.text = (value == 0 || value == 0.0) ? '' : value.toString();
    }

    updateController(_ageController, data["age"]);
    updateController(_heightController, data["height_cm"]);
    updateController(_weightController, data["weight_kg"]);
    updateController(_waistController, data["waist_in"]);
    updateController(_bmiController, data["bmi"]);
    setState(() => isLoading = false);
  }

  Future<void> _saveBodyData() async {
    setState(() {
      isLoading = true;
      isSaving = true;
    });

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.post(
      Uri.parse('${EnvConfig.baseUrl}/body-data/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "firebase_token": token,
        "age": int.tryParse(_ageController.text) ?? 0,
        "height_cm": double.tryParse(_heightController.text) ?? 0,
        "weight_kg": double.tryParse(_weightController.text) ?? 0,
        "waist_in": double.tryParse(_waistController.text) ?? 0,
        "bmi": double.tryParse(_bmiController.text) ?? 0,
      }),
    );

    if (response.statusCode == 200) {
      final updatedData = jsonDecode(response.body)["body_data"];

      // Update the controllers from the updated response (optional sync back)
      _ageController.text = updatedData["age"].toString();
      _heightController.text = updatedData["height_cm"].toString();
      _weightController.text = updatedData["weight_kg"].toString();
      _waistController.text = updatedData["waist_in"].toString();
      _bmiController.text = updatedData["bmi"].toString();

      setState(() {
        isLoading = false;
        isSaving = false;
      });
      Navigator.of(context).pop();
    } else {
      showAboutDialog(
        context: context,
        applicationName: "Error",
        children: [Text("Failed to save data: ${response.statusCode}")],
      );
    }
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),

      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.only(bottom: keyboardInset),
        curve: Curves.easeOut,
        child: Column(
          children: [
            // Header with title and close icon
            Container(
              margin: EdgeInsets.only(
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.02,
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
                  Center(child: Text("My Body Data", style: largeText())),
                ],
              ),
            ),

            // Form content
            Expanded(
              child:
                  isLoading
                      ? ListView.builder(
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom:
                              16 + keyboardInset, // leave space for keyboard
                          left: 16,
                          right: 16,
                        ),
                        itemCount: 6,
                        itemBuilder: (_, __) => _buildShimmerTile(),
                      )
                      : ListView(
                        // 2) Drag down on the list to dismiss keyboard
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.05,
                          right: screenWidth * 0.05,
                          bottom: screenHeight * 0.015 + keyboardInset,
                          top: screenHeight * 0.005,
                        ),
                        children: [
                          _buildInfoTile(),
                          _buildDataTile(
                            "Age",
                            "Enter your age",
                            "years",
                            _ageController,
                          ),
                          _buildDataTile(
                            "Height",
                            "Enter your height",
                            "cm",
                            _heightController,
                          ),
                          _buildDataTile(
                            "Weight",
                            "Enter your weight",
                            "kg",
                            _weightController,
                          ),
                          _buildDataTile(
                            "Waist Size",
                            "Enter waist size",
                            "inches",
                            _waistController,
                          ),
                          _buildDataTile(
                            "BMI",
                            "Enter BMI",
                            "",
                            _bmiController,
                          ),
                        ],
                      ),
            ),

            // Save Button
            GestureDetector(
              onTap: isSaving ? null : _saveBodyData,
              child: Container(
                margin: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.05,
                ),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                decoration: BoxDecoration(
                  color: isSaving ? Colors.pink.shade50 : secondaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Center(
                  child:
                      isSaving
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                            "Save",
                            style: mediumText(color: Colors.black),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(
    String label,
    String hint,
    String unit,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: mediumText(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: const UnderlineInputBorder(),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(unit, style: mediumText(color: Colors.grey)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your data is anonymized and securely encrypted.",
              style: mediumText(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
