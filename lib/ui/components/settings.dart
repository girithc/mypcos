import 'dart:convert';

import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:roo_mobile/main.dart';
import 'package:roo_mobile/utils/constants.dart';

class SettingsPageContent extends StatefulWidget {
  final ScrollController scrollController;

  SettingsPageContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  State<SettingsPageContent> createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<SettingsPageContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _secureStorage = const FlutterSecureStorage();

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    await _secureStorage.deleteAll(); // Delete everything from secure storage

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Remove all routes from stack
    );
  }

  Future<void> _fetchUserDetails() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No user is signed in.");
        return;
      }
      // Get the Firebase token.
      final firebaseToken = await currentUser.getIdToken();
      final email = currentUser.email;
      // Replace the URL with your actual backend endpoint.
      final Uri url = Uri.parse("${EnvConfig.baseUrl}/users/me");

      // Build the request body.
      final Map<String, dynamic> requestBody = {
        'firebase_token': firebaseToken,
        'email': email,
      };

      // Send the POST request.
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Print the response to the console.
      print("Response from /users/me: ${response.body}");
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? "No email found";

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Settings",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SmallUserCard(
                    userProfilePic: const AssetImage(
                      "assets/img/profile_pic.png",
                    ),
                    cardColor: Colors.grey.shade100,
                    cardRadius: 12.0,
                    backgroundMotifColor: Colors.deepPurpleAccent.shade100,
                    onTap: () => print("User card tapped"),
                    userName: userEmail,
                    userNameStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SettingsGroup(
                  dividerStyle: Divider(
                    color: Colors.deepPurpleAccent.withOpacity(
                      0.3,
                    ), // Custom divider color
                    thickness: 1.0, // Custom divider thickness
                  ),
                  items: [
                    SettingsItem(
                      onTap: () {},
                      icons: CupertinoIcons.pencil_outline,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                      title: 'Appearance',
                      subtitle: "Customize your experience",
                    ),
                    SettingsItem(
                      onTap: () {},
                      icons: Icons.person,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                      title: 'Profile',
                      subtitle: "Learn more about this app",
                    ),
                    SettingsItem(
                      onTap: () {},
                      icons: Icons.dark_mode_rounded,
                      iconStyle: IconStyle(
                        iconsColor: Colors.deepPurpleAccent,
                        withBackground: true,
                        backgroundColor: Colors.white,
                      ),
                      title: 'Dark Mode',
                      subtitle: "Enable or disable dark mode",
                      trailing: Switch.adaptive(
                        value: false,
                        onChanged: (value) {},
                      ),
                    ),

                    SettingsItem(
                      onTap: () => _signOut(context),
                      icons: Icons.logout,
                      iconStyle: IconStyle(
                        iconsColor: Colors.deepPurpleAccent,
                        withBackground: true,
                        backgroundColor: Colors.white,
                      ),
                      title: 'Sign Out',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
