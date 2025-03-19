import 'package:flutter/material.dart';
import 'package:roo_mobile/ui/chat.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Chat page when the button is pressed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(),
            ), // Adjust with your actual Chat page
          );
        },
        backgroundColor: Colors.white, // Set the desired background color
        child: Icon(
          Icons.auto_awesome,
          color: Colors.deepPurpleAccent,
          size: 35,
        ), // Set icon to chat
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Make it rounder
        ),
      ),
    );
  }
}
