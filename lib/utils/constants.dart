import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// lib/config/env_config.dart
class EnvConfig {
  static const String baseUrl = "http://127.0.0.1:8000";
  static const String baseUrl2 = 'https://roo-withered-surf-3929.fly.dev';
  //static const String baseUrl2 = 'https://cupid-divine-field-8783.fly.dev';
  //static const String localUrl = 'http://localhost:8080';

  // Add other environment variables here if needed
}

TextStyle smallText({
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.sriracha(
    fontSize: 16,
    fontWeight: fontWeight,
    color: color,
  );
}

TextStyle mediumText({
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.sriracha(
    fontSize: 20,
    fontWeight: fontWeight,
    color: color,
  );
}

TextStyle largeText({
  FontWeight fontWeight = FontWeight.normal,
  Color color = Colors.black,
}) {
  return GoogleFonts.sriracha(
    fontSize: 28,
    fontWeight: fontWeight,
    color: color,
  );
}

Color primaryColor = Colors.greenAccent;
Color secondaryColor = Colors.greenAccent.shade400;
Color tertiary = Colors.greenAccent.shade200;
