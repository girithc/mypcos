import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/feature_card.dart';
import 'package:roo_mobile/ui/track/health/diet/main.dart';
import 'package:roo_mobile/ui/track/health/main.dart';
import 'package:roo_mobile/ui/track/health/mood/mood.dart';
import 'package:roo_mobile/ui/track/health/period/period_calendar.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:shimmer/shimmer.dart';

class PCOSPage extends StatefulWidget {
  const PCOSPage({super.key});

  @override
  State<PCOSPage> createState() => _PCOSPageState();
}

class _PCOSPageState extends State<PCOSPage> {
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
                  title: "Care Plans",
                  titleWidget: Text(
                    "Care Plans",
                    style: largeText(color: titleColor),
                  ),
                  indicatorWidget: CountdownRoundedIndicator(
                    predictedDate: DateTime.now().add(Duration(days: 12)),
                    daysLeft: 12,
                    progress: 0.6,
                    ringColor: Colors.pinkAccent,
                    backgroundRingColor: Colors.pinkAccent.withOpacity(0.4),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(
                  title: "MyPCOS Signs",
                  titleWidget: Text(
                    "PCOS Signs",
                    style: largeText(color: titleColor),
                  ),
                  onTap: () {
                    showPCOSSignBottomSheet(context, "PCOS Signs");
                  },

                  indicatorWidget: FeelBetterIndicator(
                    message: "Self-care",
                    icon1: Icons.self_improvement,
                    icon2: Icons.trending_up, // or Icons.favorite
                    backgroundColor: Colors.pink.shade50,
                    iconColor: Colors.pinkAccent,
                  ),
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
          title: Text("Seed Cycle", style: mediumText()),
          subtitle: Text("Lets seed cycle", style: smallText(color: textColor)),
          icon: Icon(Icons.calendar_today, color: iconColor),
          colorl: Colors.white,
          onTapCallback: () {
            showPeriodCalendarBottomSheet(context);
          },
        ),
        SecondaryActionCard(
          title: Text("MyCyst", style: mediumText()),
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

showPCOSSignBottomSheet(BuildContext context, String sampleText) {
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
            child: PCOSSignSheetContent(
              sampleText: sampleText,
            ), // Your actual content
          );
        },
      );
    },
  );
}

class PCOSSignSheetContent extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String sampleText;
  const PCOSSignSheetContent({
    Key? key,
    this.onBackToHome,
    required this.sampleText,
  }) : super(key: key);

  @override
  _PCOSSignSheetContentState createState() => _PCOSSignSheetContentState();
}

class _PCOSSignSheetContentState extends State<PCOSSignSheetContent> {
  String selectedCategory = 'Common Signs';
  List<PCOSSymptom> commonSigns = [];
  List<PCOSSymptom> mySigns = [];
  bool loading = true;
  bool mySignsloading = true;
  String? error;
  String? mySignserror;

  @override
  void initState() {
    super.initState();
    _getAllPCOSSymptoms();
  }

  Future<void> _getAllPCOSSymptoms() async {
    try {
      final res = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/pcos-symptoms/get-all'),
        body: jsonEncode({
          'firebase_token':
              await FirebaseAuth.instance.currentUser?.getIdToken(),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['pcos_symptoms'] as List<dynamic>;
        final myList = body['my_symptoms'] as List<dynamic>;

        final fetchedCommon =
            list
                .map((e) => PCOSSymptom.fromJson(e as Map<String, dynamic>))
                .toList();
        final fetchedMy =
            myList
                .map((e) => PCOSSymptom.fromJson(e as Map<String, dynamic>))
                .toList();

        setState(() {
          commonSigns = fetchedCommon;
          mySigns = fetchedMy;
          loading = false;
          mySignsloading = false;

          // ←—— New: pick the initial tab based on whether they have any “my” signs
          selectedCategory = mySigns.isNotEmpty ? 'My Signs' : 'Common Signs';
        });
      } else {
        setState(() {
          error = 'Status ${res.statusCode}';
          mySignserror = 'Status ${res.statusCode}';
          loading = false;
          mySignsloading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        mySignserror = e.toString();
        loading = false;
        mySignsloading = false;
      });
    }
  }

  Future<void> _getMySigns() async {
    setState(() {
      mySignsloading = true;
      mySignserror = null;
    });

    try {
      final userId = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }
      final res = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/pcos-symptoms/get-my-symptoms'),
        body: jsonEncode({'firebase_token': userId}),
        headers: {'Content-Type': 'application/json'},
      );

      print("Status Code: ${res.statusCode}");
      print("Response Body: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = body['my_symptoms'] as List<dynamic>;
        setState(() {
          mySigns =
              list
                  .map((e) => PCOSSymptom.fromJson(e as Map<String, dynamic>))
                  .toList();
          mySignsloading = false;
        });
      } else {
        setState(() {
          mySignserror = 'Server error: ${res.statusCode}';
          mySignsloading = false;
        });
      }
    } catch (e) {
      setState(() {
        mySignserror = 'Network error: $e';
        mySignsloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Top fixed content
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
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ["Common Signs", "My Signs"].map((category) {
                  final isSelected = selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = category),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHeight * 0.03,
                        vertical: screenHeight * 0.0125,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? secondaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.shade100, blurRadius: 1),
                        ],
                      ),
                      child: Text(category, style: mediumText()),
                    ),
                  );
                }).toList(),
          ),
        ),

        // Single Expanded widget for scrollable content
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Builder(
              builder: (context) {
                switch (selectedCategory) {
                  case 'Common Signs':
                    return CommonSignsTab(
                      symptoms: commonSigns,
                      loading: loading,
                      error: error,
                      onSymptomToggled: _getMySigns,
                    );
                  case 'My Signs':
                    return MySignsTab(
                      symptoms: mySigns,
                      loading: mySignsloading,
                      error: mySignserror,
                      onSymptomToggled: _getMySigns,
                    );
                  default:
                    return const Center(child: Text('Select a category'));
                }
              },
            ),
          ),
        ),

        // Bottom fixed button
      ],
    );
  }
}

class CommonSignsTab extends StatelessWidget {
  final List<PCOSSymptom> symptoms;
  final bool loading;
  final String? error;
  final VoidCallback onSymptomToggled; // <-- new

  const CommonSignsTab({
    super.key,
    required this.symptoms,
    required this.loading,
    this.error,
    required this.onSymptomToggled,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        itemCount: 6, // number of skeleton cards
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300, // dark base
            highlightColor: Colors.grey.shade100, // light highlight
            child: Container(
              height: 120, // mimic real card height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      );
    }
    if (error != null) return Center(child: Text('Error: $error'));
    if (symptoms.isEmpty) return const Center(child: Text('No symptoms found'));

    return MasonryGridView.count(
      crossAxisCount: 2, // two uneven columns
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.only(bottom: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: symptoms.length,
      itemBuilder:
          (context, i) => PCOSSymptomCard(
            symptom: symptoms[i],
            personal: false,
            onChange: onSymptomToggled, // <-- pass it down
          ), // ← cards dictate height
    );
  }
}

class PCOSSymptomCard extends StatefulWidget {
  final PCOSSymptom symptom;
  final bool personal;
  final VoidCallback onChange;
  const PCOSSymptomCard({
    super.key,
    required this.symptom,
    required this.personal,
    required this.onChange,
  });

  @override
  State<PCOSSymptomCard> createState() => _PCOSSymptomCardState();
}

class _PCOSSymptomCardState extends State<PCOSSymptomCard> {
  late bool _isAdded;

  @override
  void initState() {
    super.initState();
    _isAdded = widget.symptom.added ?? false;
  }

  Future<void> _addSymptomToPCOS(int id) async {
    try {
      final userId = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      final res = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/pcos-symptoms/add'),
        body: jsonEncode({'firebase_token': userId, 'symptom_id': id}),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(body['message'])));

        // 2) update local flag immediately
        setState(() {
          _isAdded = true;
        });

        // 3) notify parent to refresh its mySigns list
        widget.onChange();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add symptom')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  _removeSymptomFromPCOS(int id) async {
    try {
      final userId = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }
      final res = await http.post(
        Uri.parse('${EnvConfig.baseUrl}/pcos-symptoms/remove'),
        body: jsonEncode({'firebase_token': userId, 'symptom_id': id}),
        headers: {'Content-Type': 'application/json'},
      );

      print("Status Code: ${res.statusCode}");
      print("Response Body: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['status'] == 'success') {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(body['message'])));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(body['message'])));
        }
        widget.onChange();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add symptom')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAlreadyAdded = !widget.personal && _isAdded;
    final bool isDisabled = isAlreadyAdded;
    final bool shouldGrey = widget.personal || isDisabled;

    final String buttonText =
        widget.personal
            ? 'Remove'
            : isAlreadyAdded
            ? 'Added'
            : 'Add';

    // Decide base color
    final Color activeColor =
        shouldGrey ? Colors.grey.shade50 : Colors.pink.shade50;

    // Override for disabled state
    final background = MaterialStateProperty.resolveWith<Color>((states) {
      if (states.contains(MaterialState.disabled)) {
        return Colors.grey.shade50;
      }
      return activeColor;
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeatureCard(
            title: widget.symptom.name,
            titleWidget: Text(widget.symptom.name, style: largeText()),
            onTap: () {},
            indicatorWidget: Container(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton(
              onPressed:
                  isDisabled
                      ? null
                      : () {
                        if (widget.personal) {
                          _removeSymptomFromPCOS(widget.symptom.id);
                        } else {
                          _addSymptomToPCOS(widget.symptom.id);
                        }
                      },
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                backgroundColor: background,
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MySignsTab extends StatefulWidget {
  final List<PCOSSymptom> symptoms;
  final bool loading;
  final String? error;
  final VoidCallback onSymptomToggled; // <-- new

  const MySignsTab({
    Key? key,
    required this.symptoms,
    required this.loading,
    this.error,
    required this.onSymptomToggled,
  }) : super(key: key);

  @override
  _MySignsTabState createState() => _MySignsTabState();
}

class _MySignsTabState extends State<MySignsTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.all(16),
        physics: const ClampingScrollPhysics(),
        itemCount: 6, // number of skeleton cards
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300, // dark base
            highlightColor: Colors.grey.shade100, // light highlight
            child: Container(
              height: 120, // mimic real card height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      );
    }
    if (widget.error != null)
      return Center(child: Text('Error: ${widget.error}'));
    if (widget.symptoms.isEmpty)
      return const Center(child: Text('No symptoms recorded'));

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.only(bottom: 16),
      physics: const ClampingScrollPhysics(),
      itemCount: widget.symptoms.length,
      itemBuilder: (context, i) {
        return PCOSSymptomCard(
          symptom: widget.symptoms[i],
          personal: true,
          onChange: widget.onSymptomToggled, // <-- pass it down
        ); // ← cards dictate height
      },
    );
  }
}

class PCOSSymptom {
  final int id;
  final String name;
  final bool? added;

  PCOSSymptom({required this.id, required this.name, this.added});

  factory PCOSSymptom.fromJson(Map<String, dynamic> json) => PCOSSymptom(
    id: json['id'],
    name: json['name'],
    added: json['added'] ?? false,
  );
}
