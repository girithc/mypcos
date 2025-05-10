import 'package:flutter/material.dart';

class LibraryDetailPage extends StatelessWidget {
  final String title;
  final Color color;
  final String tag;

  const LibraryDetailPage({
    super.key,
    required this.title,
    required this.color,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Hero(
        tag: tag,
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              width: screenWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page title and description
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium!.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Detailed course information and description goes here. "
                    "Add more content, lessons, videos, text, images etc. "
                    "to fully describe the course and its contents.",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  // Wrap the TabBar and TabBarView with DefaultTabController
                  DefaultTabController(
                    length: 3,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      child: Column(
                        children: [
                          // TabBar inside the card header
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: const TabBar(
                              indicatorColor: Colors.white,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white70,
                              tabs: [
                                Tab(text: 'cycst'),
                                Tab(text: 'periods'),
                                Tab(text: 'hormones'),
                              ],
                            ),
                          ),
                          // TabBarView inside the card body
                          Container(
                            height: 400, // Adjust the height as needed.
                            padding: const EdgeInsets.all(16),
                            child: const TabBarView(
                              children: [
                                // Tab 1: cycst
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'cycst',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Detailed explanation for cycst goes here. Add information about ovarian cysts, their relevance in PCOS, and their impact on overall health.",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 16),
                                      // Dummy content to demonstrate scrolling
                                      SizedBox(height: 300),
                                    ],
                                  ),
                                ),
                                // Tab 2: mentrual cycle
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'mentrual cycle',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Detailed explanation for mentrual cycle goes here. Provide insights on how PCOS affects menstrual cycles, including irregularities and the underlying hormonal disturbances.",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 16),
                                      // Dummy content to demonstrate scrolling
                                      SizedBox(height: 300),
                                    ],
                                  ),
                                ),
                                // Tab 3: hormones
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'hormones',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        "Detailed explanation for hormones goes here. Discuss how hormonal imbalances in PCOS occur and detail symptoms associated with increased androgen levels.",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(height: 16),
                                      // Dummy content to demonstrate scrolling
                                      SizedBox(height: 300),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Additional dummy content to test scrolling.
                  const SizedBox(height: 2400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
