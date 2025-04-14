import 'package:flutter/material.dart';
import 'package:roo_mobile/ui/chat.dart';
import 'package:roo_mobile/ui/library/detail.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(title: const Text('Library')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: GridView.count(
          padding: const EdgeInsets.all(8),
          crossAxisCount: 2, // Two cards per row
          childAspectRatio:
              0.7, // Adjust the ratio so the card height fits nicely
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
          children: const [
            CourseCard(title: "PCOS??", color: Colors.white),
            CourseCard(title: "iOS App Development", color: Colors.white),
            CourseCard(title: "PCOS 2??", color: Colors.white),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Chat page when the button is pressed.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatPage()),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.deepPurpleAccent,
          size: 35,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.title,
    this.color = const Color(0xFF7553F6),
    this.iconSrc = "assets/img/google.png",
  });

  final String title, iconSrc;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    LibraryDetailPage(title: title, color: color, tag: title),
          ),
        );
      },
      child: Hero(
        tag: title,
        // Custom flightShuttleBuilder with CurvedAnimation for a smoother transition.
        flightShuttleBuilder: (
          flightContext,
          animation,
          flightDirection,
          fromHeroContext,
          toHeroContext,
        ) {
          final Widget transitioningWidget =
              flightDirection == HeroFlightDirection.push
                  ? toHeroContext.widget
                  : fromHeroContext.widget;
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return ScaleTransition(
            scale: Tween<double>(
              begin: flightDirection == HeroFlightDirection.push ? 1.0 : 1.0,
              end: flightDirection == HeroFlightDirection.push ? 1.0 : 1.0,
            ).animate(curvedAnimation),
            child: transitioningWidget,
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          // Content of the card arranged vertically.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color:
                      color == Colors.white
                          ? Colors.deepPurpleAccent
                          : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.02,
                  bottom: screenHeight * 0.01,
                ),
                child: Text(
                  "Build and animate an iOS app from scratch",
                  style: TextStyle(
                    color:
                        color == Colors.white
                            ? Colors.deepPurple
                            : Colors.white38,
                  ),
                ),
              ),

              const Spacer(),
              // Overlapping avatars using a Stack.
              SizedBox(
                height: screenWidth * 0.12,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: List.generate(3, (index) {
                    return Positioned(
                      left: index * ((screenWidth * 0.06 * 2) - 10),
                      child: CircleAvatar(
                        radius: screenWidth * 0.06,
                        backgroundImage: const AssetImage(
                          "assets/img/profile_pic.png",
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
