import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

enum HealthDataCardType { steps, calories, exerciseMinutes }

class ActionCard extends StatefulWidget {
  final String title, iconSrc;
  final Color color;
  final HealthDataCardType? type; // nullable
  final VoidCallback? onTapOverride; // for non-health actions

  const ActionCard({
    super.key,
    required this.title,
    this.iconSrc = "assets/img/profile_pic.png",
    this.color = const Color(0xFF7553F6),
    this.type,
    this.onTapOverride,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  final Health _health = Health();
  int? _steps;
  double? _calories;
  double? _exerciseMinutes;

  Future<void> _fetchHealthData() async {
    // Avoid crashing in iOS Simulator
    if (Platform.isIOS) {
      final deviceInfo = await DeviceInfoPlugin().iosInfo;
      if (!deviceInfo.isPhysicalDevice) {
        //debugPrint("Skipping HealthKit: running in iOS Simulator");
        return;
      }
    }

    final types = [
      HealthDataType.STEPS,
      HealthDataType.EXERCISE_TIME,
      HealthDataType.BASAL_ENERGY_BURNED,
    ];

    final permissions = [
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE,
    ];

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final hasPermissions = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );

    if (hasPermissions) {
      try {
        final data = await _health.getHealthDataFromTypes(
          types: types,
          startTime: midnight,
          endTime: now,
        );
        debugPrint("Fetched data: $data");

        final steps =
            _sumQuantity(data, HealthDataType.ACTIVE_ENERGY_BURNED).round();
        final calories = _sumQuantity(data, HealthDataType.WORKOUT);
        final exercise = _sumQuantity(data, HealthDataType.EXERCISE_TIME);

        setState(() {
          _steps = steps;
          _calories = calories;
          _exerciseMinutes = exercise;
        });
      } catch (e) {
        debugPrint("Error fetching health data: $e");
      }
    } else {
      debugPrint("Permission not granted");
    }
  }

  double _sumQuantity(List<HealthDataPoint> data, HealthDataType type) {
    return data.where((d) => d.type == type).fold(0.0, (sum, d) {
      //print("Data point: $d, Data type: ${d.type} == $type");
      final value = d.value;
      if (value is NumericHealthValue) {
        return sum + value.numericValue;
      } else {
        debugPrint("Unsupported HealthValue type: ${value.runtimeType}");
        return sum;
      }
    });
  }

  double _getProgressValue() {
    switch (widget.type) {
      case HealthDataCardType.steps:
        return (_steps != null
            ? (_steps! / 10000).clamp(0.0, 1.0)
            : 0.0); // 10k step goal
      case HealthDataCardType.calories:
        return (_calories != null
            ? (_calories! / 400).clamp(0.0, 1.0)
            : 0.0); // 400 kcal goal
      case HealthDataCardType.exerciseMinutes:
        return (_exerciseMinutes != null
            ? (_exerciseMinutes! / 30).clamp(0.0, 1.0)
            : 0.0); // 30 min goal
      case null:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _getDisplayValue() {
    switch (widget.type) {
      case HealthDataCardType.steps:
        return '${_steps ?? 0}';
      case HealthDataCardType.calories:
        return '${_calories?.toInt() ?? 0} cal';
      case HealthDataCardType.exerciseMinutes:
        return '${_exerciseMinutes?.toInt() ?? 0} min';
      case null:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () async {
        if (widget.type != null) {
          await _fetchHealthData();
          _showHealthDetails(context);
        } else if (widget.onTapOverride != null) {
          widget.onTapOverride!();
        } else {
          // fallback
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: Text(widget.title),
                  content: const Text("Custom action coming soon!"),
                ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.01,
        ),
        height: screenHeight * 0.2,
        width: screenWidth * 0.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.type != null) ...[
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: screenWidth * 0.2,
                        width: screenWidth * 0.2,
                        child: CircularProgressIndicator(
                          value: _getProgressValue(),
                          backgroundColor: Colors.deepPurpleAccent.withOpacity(
                            0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.deepPurpleAccent,
                          ),
                          strokeWidth: 6.0,
                        ),
                      ),
                      Text(
                        _getDisplayValue(),
                        style: const TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHealthDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "Apple Health Data",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _infoTile("Steps", _steps?.toString() ?? "Loading..."),
              _infoTile(
                "Calories Burned",
                _calories != null
                    ? "${_calories!.toStringAsFixed(1)} kcal"
                    : "Loading...",
              ),
              _infoTile(
                "Exercise Minutes",
                _exerciseMinutes != null
                    ? "${_exerciseMinutes!.toStringAsFixed(0)} mins"
                    : "Loading...",
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
