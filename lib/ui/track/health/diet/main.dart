import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roo_mobile/utils/constants.dart';
import 'package:shimmer/shimmer.dart';

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
  bool _loading = true; // ← track loading
  List<DietOption> _options = [];

  @override
  void initState() {
    super.initState();
    _getAllDietChoices();
  }

  Future<void> _getAllDietChoices() async {
    setState(() => _loading = true);

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      setState(() => _loading = false);
      return;
    }

    final response = await http.post(
      Uri.parse('${EnvConfig.baseUrl}/diet/get-diets'),
      body: jsonEncode({'firebase_token': token}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['diets'] as List<dynamic>;
      setState(() {
        _options =
            list
                .map((e) => DietOption.fromJson(e as Map<String, dynamic>))
                .toList();
        _loading = false;
      });
    } else {
      // error path
      debugPrint(
        'Failed loading diets: ${response.statusCode} ${response.body}',
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _updateDietPreferences() async {
    setState(() => _loading = true);

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      setState(() => _loading = false);
      return;
    }

    // 1) Build a plain List<Map> from DietOption objects
    final List<Map<String, dynamic>> payload =
        _options.map((opt) {
          return {
            'diet_id': opt.id, // int
            'added': opt.added, // bool
          };
        }).toList();

    // 2) Encode only primitives
    final body = jsonEncode({'firebase_token': token, 'preferences': payload});

    print("body: $body");
    final response = await http.post(
      Uri.parse('${EnvConfig.baseUrl}/diet/update'),
      body: body,
      headers: {'Content-Type': 'application/json'},
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferences saved!')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${response.statusCode}')),
      );
    }
  }

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
              // 1) Show shimmer if loading
              if (_loading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(5, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            height: 24,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
                  ),
                )
              else
                // 2) Actual switches once loaded
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children:
                        _options.map((opt) {
                          return SwitchListTile(
                            title: Text(opt.name, style: mediumText()),
                            value: opt.added,
                            onChanged: (val) => setState(() => opt.added = val),

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

              const SizedBox(height: 20),
            ],
          ),
        ),

        if (_loading)
          Container()
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _updateDietPreferences(),
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
              ),
            ),
          ),
      ],
    );
  }
}

class DietOption {
  final int id;
  final String name;
  bool added;

  DietOption({required this.id, required this.name, required this.added});

  factory DietOption.fromJson(Map<String, dynamic> json) => DietOption(
    id: json['id'] as int,
    name: json['name'] as String,
    added: json['added'] as bool,
  );
}
