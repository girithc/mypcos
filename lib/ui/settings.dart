import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:roo_mobile/main.dart';

class SettingsPageContent extends StatelessWidget {
  final ScrollController scrollController;

  const SettingsPageContent({Key? key, required this.scrollController})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  userName: "Nom de l'utilisateur",
                ),
                SettingsGroup(
                  items: [
                    SettingsItem(
                      onTap: () {},
                      icons: CupertinoIcons.pencil_outline,
                      iconStyle: IconStyle(),
                      title: 'Appearance',
                      subtitle: "Make Ziar'App yours",
                      titleMaxLine: 1,
                      subtitleMaxLine: 1,
                    ),
                    SettingsItem(
                      onTap: () {},
                      icons: Icons.fingerprint,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.red,
                      ),
                      title: 'Privacy',
                      subtitle: "Lock Ziar'App to improve your privacy",
                    ),
                    SettingsItem(
                      onTap: () {},
                      icons: Icons.dark_mode_rounded,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.red,
                      ),
                      title: 'Dark mode',
                      subtitle: "Automatic",
                      trailing: Switch.adaptive(
                        value: false,
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
                SettingsGroup(
                  items: [
                    SettingsItem(
                      onTap: () {},
                      icons: Icons.info_rounded,
                      iconStyle: IconStyle(backgroundColor: Colors.purple),
                      title: 'About',
                      subtitle: "Learn more about Ziar'App",
                    ),
                    SettingsItem(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                          (Route<dynamic> route) =>
                              false, // This removes all routes in the stack
                        );
                      },
                      icons: Icons.info_rounded,
                      iconStyle: IconStyle(backgroundColor: Colors.purple),
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
