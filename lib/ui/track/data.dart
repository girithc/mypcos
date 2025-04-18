import 'package:flutter/material.dart';

class Action {
  final String title;
  final String description;
  final String iconSrc;
  final Color color;
  final Icon? icon;

  const Action({
    required this.title,
    this.description = 'Build and animate an iOS app from scratch',
    this.iconSrc = "assets/img/profile_pic.png",
    this.color = const Color(0xFF7553F6),
    this.icon,
  });
}

// Trending category gradient: light blue -> indigo
final List<Action> Actions = [
  Action(
    title: "Trendy 1",
    color: Colors.lightBlue.shade200,
    icon: Icon(Icons.apple, color: Colors.white),
  ),
  Action(
    title: "Trendy 2",
    color: Colors.indigo.shade400,
    icon: Icon(Icons.flutter_dash, color: Colors.white),
  ),
];

final List<Action> recentActions = [
  Action(
    title: "Period Calendar",
    color: Colors.white,
    icon: Icon(Icons.calendar_today, color: Colors.indigo),
  ),
  Action(
    title: "How Do You Feel ?",
    color: Colors.indigo.shade500,
    icon: Icon(Icons.mood, color: Colors.white),
  ),
];

// Workout category: green gradients
final List<Action> workoutActions = [
  Action(
    title: "Yoga",
    color: Colors.green.shade300,
    icon: Icon(Icons.self_improvement, color: Colors.white),
  ),
  Action(
    title: "HIIT",
    color: Colors.green.shade600,
    icon: Icon(Icons.fitness_center, color: Colors.white),
  ),
];

final List<Action> workoutSecondary = [
  Action(
    title: "Period Calendar",
    color: Colors.white,
    icon: Icon(Icons.calendar_today, color: Colors.green),
  ),
  Action(
    title: "How do you feel ?",
    color: Colors.green.shade400,
    icon: Icon(Icons.mood, color: Colors.white),
  ),
  Action(
    title: "Body Measurements",
    color: Colors.green.shade700,
    icon: Icon(Icons.straighten, color: Colors.white),
  ),
];

// Diet category: orange-pink gradient
final List<Action> dietActions = [
  Action(
    title: "Weight Loss",
    color: Colors.deepOrange.shade200,
    icon: Icon(Icons.scale, color: Colors.white),
  ),
  Action(
    title: "Meal",
    color: Colors.orange.shade400,
    icon: Icon(Icons.restaurant_menu, color: Colors.white),
  ),
  Action(
    title: "Seed Cycling",
    color: Colors.pink.shade300,
    icon: Icon(Icons.eco, color: Colors.white),
  ),
];

final List<Action> dietSecondary = [
  Action(
    title: "Set Meal Plan",
    color: Colors.white,
    icon: Icon(Icons.food_bank, color: Colors.orange),
  ),
  Action(
    title: "Dietary Preferences",
    color: Colors.orange.shade300,
    icon: Icon(Icons.dining, color: Colors.white),
  ),
  Action(
    title: "Nutrition Guide",
    color: Colors.pink.shade400,
    icon: Icon(Icons.menu_book, color: Colors.white),
  ),
];

// Health category: purple gradient
final List<Action> healthActions = [
  Action(
    title: "Health Tips",
    color: Colors.purple.shade300,
    icon: Icon(Icons.health_and_safety, color: Colors.white),
  ),
  Action(
    title: "Supplements",
    color: Colors.deepPurple.shade600,
    icon: Icon(Icons.medical_services, color: Colors.white),
  ),
];

final List<Action> healthSecondary = [
  Action(
    title: "Upload Medical Report",
    color: Colors.white,
    icon: Icon(Icons.upload_file, color: Colors.deepPurpleAccent),
  ),
  Action(
    title: "Body Measurements",
    color: Colors.purple.shade400,
    icon: Icon(Icons.straighten, color: Colors.white),
  ),
  Action(
    title: "Fitness Tips",
    color: Colors.deepPurple.shade700,
    icon: Icon(Icons.fitness_center, color: Colors.white),
  ),
];

final Map<String, List<Action>> categoryActions = {
  "Trending": Actions,
  "Workout": workoutActions,
  "Diet": dietActions,
  "Health": healthActions,
};

final Map<String, List<Action>> secondaryCategoryActions = {
  "Trending": recentActions,
  "Workout": workoutSecondary,
  "Diet": dietSecondary,
  "Health": healthSecondary,
};
