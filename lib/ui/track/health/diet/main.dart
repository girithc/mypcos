import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

void showDietaryPreferencesBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.grey.shade200,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.65,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: DietaryPreferencesContent(
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}

class DietaryPreferencesContent extends StatefulWidget {
  final ScrollController scrollController;

  const DietaryPreferencesContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  _DietaryPreferencesContentState createState() =>
      _DietaryPreferencesContentState();
}

class _DietaryPreferencesContentState extends State<DietaryPreferencesContent> {
  Map<String, bool> preferences = {
    'Gluten-Free': false,
    'Vegetarian': false,
    'Dairy-Free': false,
    'Nut-Free': false,
    'Vegan': false,
  };

  final List<String> pcosFriendlyFoods = [
    'Avocado',
    'Berries',
    'Leafy Greens',
    'Salmon',
    'Chia Seeds',
    'Flaxseeds',
    'Nuts',
    'Eggs',
    'Quinoa',
    'Lentils',
    'Turmeric',
    'Cinnamon',
    'Sweet Potatoes',
    'Zucchini',
    'Broccoli',
  ];

  Set<String> selectedFoods = {};

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Top Bar
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
              Center(child: Text("Diet Choices", style: largeText())),
            ],
          ),
        ),
        // Scrollable Content
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.015,
            ),
            children: [
              // Switch List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children:
                      preferences.keys.map((String key) {
                        return SwitchListTile(
                          title: Text(key, style: mediumText()),
                          value: preferences[key]!,
                          onChanged: (bool value) {
                            setState(() {
                              preferences[key] = value;
                            });
                          },
                          trackOutlineColor: MaterialStateProperty.all(
                            Colors.greenAccent,
                          ),
                          activeTrackColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1),
                          ),
                          activeColor: Colors.white,
                          inactiveThumbColor: Colors.black54,
                          inactiveTrackColor: Colors.white,
                        );
                      }).toList(),
                ),
              ),

              // Chips List
              const SizedBox(height: 20),

              // Save Button
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
                  'Save Preferences',
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
