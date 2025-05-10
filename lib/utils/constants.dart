import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// lib/config/env_config.dart
class EnvConfig {
  static const String baseUrl2 = "http://127.0.0.1:8000";
  static const String baseUrl =
      'https://roo-withered-surf-3929-production.up.railway.app';
  //static const String baseUrl2 = 'https://cupid-divine-field-8783.fly.dev';
  //static const String localUrl = 'http://localhost:8080';

  // Add other environment variables here if needed
}

TextStyle smallText({
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.monda(fontSize: 14, fontWeight: fontWeight, color: color);
}

TextStyle mediumText({
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.monda(
    fontSize: 18,
    fontWeight: fontWeight,
    color: color,
    decorationStyle: TextDecorationStyle.double,
  );
}

TextStyle largeText({
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.monda(
    fontSize: 24,
    fontWeight: fontWeight,
    color: color,
    decorationStyle: TextDecorationStyle.double,
  );
}

Color lightgreenColor = Colors.lightGreenAccent;
Color primaryColor = Colors.greenAccent.shade400;
Color secondaryColor = Colors.greenAccent.shade200;
Color tertiaryColor = Colors.greenAccent.shade100;
Color iconColor = Colors.green;

Color screenColor = Colors.grey.shade200;

Color textColor = Colors.black54;
Color titleColor = Colors.black87;
