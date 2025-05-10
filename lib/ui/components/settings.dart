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

  const SettingsPageContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  State<SettingsPageContent> createState() => _SettingsPageContentState();
}

class _SettingsPageContentState extends State<SettingsPageContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    await _secureStorage.deleteAll();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _fetchUserDetails() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print("No user is signed in.");
        return;
      }
      final firebaseToken = await currentUser.getIdToken();
      final email = currentUser.email;
      final Uri url = Uri.parse("${EnvConfig.baseUrl}/users/me");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebase_token': firebaseToken, 'email': email}),
      );

      print("Response from /users/me: ${response.body}");
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? "";

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
                    backgroundMotifColor:
                        Colors.greenAccent.shade200, // ✅ CHANGED
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
                    color: Colors.greenAccent.shade200.withOpacity(
                      0.3,
                    ), // ✅ CHANGED
                    thickness: 1.0,
                  ),
                  items: [
                    SettingsItem(
                      onTap: () => _signOut(context),
                      icons: Icons.logout,
                      iconStyle: IconStyle(
                        iconsColor: Colors.greenAccent.shade200, // ✅ CHANGED
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
