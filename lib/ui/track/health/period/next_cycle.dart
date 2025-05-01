import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

void showNextCycleBottomSheet(BuildContext context, String sampleText) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50, Colors.purple.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: NextCycleContent(sampleText: sampleText),
          );
        },
      );
    },
  );
}

class NextCycleContent extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final String sampleText;

  const NextCycleContent({
    Key? key,
    this.onBackToHome,
    required this.sampleText,
  }) : super(key: key);

  @override
  _NextCycleContentState createState() => _NextCycleContentState();
}

class _NextCycleContentState extends State<NextCycleContent> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Widget sectionCard({
      required IconData icon,
      required String title,
      required Widget child,
    }) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Colors.pinkAccent),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            child,
          ],
        ),
      );
    }

    return Column(
      children: [
        // Drag handle

        // Header
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
            color: Colors.transparent,
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
              Center(child: Text("Period Calendar", style: largeText())),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            children: [
              // 1. At-a-Glance Summary
              sectionCard(
                icon: Icons.calendar_today,
                title: 'At-a-Glance',
                child: Row(
                  children: [
                    // Make this column flexible so it never overflows
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Period: May 28 - June 1',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Avg Cycle: 29 days',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '5 days to go',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              // 2. Fertility & Hormonal Windows
              sectionCard(
                icon: Icons.pie_chart,
                title: 'Fertility & PMS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('Fertile May 13-17')),
                        Chip(label: Text('Ovulation: May 15')),
                        Chip(label: Text('PMS: May 25-27')),
                      ],
                    ),
                  ],
                ),
              ),
              // 3. Visualizations & Trends
              sectionCard(
                icon: Icons.show_chart,
                title: 'Trends',
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text('📈 Graph Placeholder')),
                ),
              ),
              // 4. Symptom & Habit Tracking
              sectionCard(
                icon: Icons.favorite_border,
                title: 'Log Symptoms',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(children: [Icon(Icons.opacity), Text('Flow')]),
                    Column(children: [Icon(Icons.mood), Text('Mood')]),
                    Column(children: [Icon(Icons.healing), Text('Pain')]),
                  ],
                ),
              ),
              // 5. Personalized Insights
              sectionCard(
                icon: Icons.insights,
                title: 'Insights',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cycle a bit long this month (+2 days).'),
                    SizedBox(height: 4),
                    Text(
                      'Tips: Yoga, magnesium-rich foods.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              // 6. Actions & Settings
              sectionCard(
                icon: Icons.settings,
                title: 'Actions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton(
                      onPressed: () {
                        /* edit cycle */
                      },
                      child: Text('Edit Predictions'),
                    ),
                    TextButton(
                      onPressed: () {
                        /* notifications */
                      },
                      child: Text('Notification Settings'),
                    ),
                    TextButton(
                      onPressed: () {
                        /* sync data */
                      },
                      child: Text('Sync Tracker'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              SizedBox(height: 24),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('In Progress', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}
