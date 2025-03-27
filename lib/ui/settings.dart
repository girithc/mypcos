import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roo_mobile/main.dart';

class SettingsPageContent extends StatelessWidget {
  final ScrollController scrollController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();

  SettingsPageContent({Key? key, required this.scrollController})
    : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    await _auth.signOut();
    await _secureStorage.deleteAll(); // Delete everything from secure storage

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Remove all routes from stack
    );
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
              controller: scrollController,
              children: [
                SmallUserCard(
                  userProfilePic: const AssetImage(
                    "assets/img/profile_pic.png",
                  ),
                  cardColor: Colors.deepPurpleAccent.shade100,
                  cardRadius: 12.0,
                  backgroundMotifColor: Colors.white,
                  onTap: () => print("User card tapped"),
                  userName: userEmail,
                  userNameStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
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
