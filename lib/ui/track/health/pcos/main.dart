import 'package:flutter/material.dart';
import 'package:roo_mobile/utils/constants.dart';

class PCOSPage extends StatefulWidget {
  const PCOSPage({super.key});

  @override
  State<PCOSPage> createState() => _PCOSPageState();
}

class _PCOSPageState extends State<PCOSPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(child: Text("Coming Soon", style: mediumText())),
      ],
    );
  }
}
