import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:simple_animated_button/elevated_layer_button.dart';

class PeriodSymptomsPage extends StatefulWidget {
  final int periodId;
  final VoidCallback onDone; // callback to toggle back

  const PeriodSymptomsPage({
    Key? key,
    required this.periodId,
    required this.onDone,
  }) : super(key: key);

  @override
  _PeriodSymptomsPageState createState() => _PeriodSymptomsPageState();
}

class _PeriodSymptomsPageState extends State<PeriodSymptomsPage> {
  // Holds the API‐returned period record
  String? _startDate;
  String? _endDate;
  bool _isLoading = false;
  // Holds the API‐returned severity (defaults to false)
  Map<String, bool> _selectedSymptoms = {};
  final List<String> _symptomOptions = [
    'Cramps',
    'Bloating',
    'Mood Swings',
    'Headache',
    'Fatigue',
  ];
  TextEditingController _notesController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // initialize map
    for (var s in _symptomOptions) _selectedSymptoms[s] = false;
    _fetchPeriod();
  }

  Future<void> _fetchPeriod() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('${EnvConfig.baseUrl}/period-symptoms-get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_token': token, 'period_id': widget.periodId}),
    );

    if (response.statusCode != 200) {
      setState(() => _loading = false);
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final period = data['period'] as Map<String, dynamic>;
    final symptoms = data['symptoms'] as List<dynamic>;
    final notes = period['notes'] as String?;

    setState(() {
      _startDate = period['start_date'];
      _endDate = period['end_date'];
      _notesController.text = notes ?? '';
      for (var s in symptoms) {
        _selectedSymptoms[s['name'] as String] = true;
      }
      _loading = false;
    });
  }

  Future<void> _updateSymptoms() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('${EnvConfig.baseUrl}/period-symptoms-update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_token': token,
        'period_id': widget.periodId,
        'symptoms': _selectedSymptoms,
        'notes': _notesController.text,
      }),
    );

    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      Navigator.of(context).pop(); // dismiss spinner

      _isLoading = false;

      widget.onDone(); // ← toggle back to calendar
    } else {
      Navigator.of(context).pop(); // dismiss spinner

      _isLoading = false;

      // handle error...
    }
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      );
    }

    // format range
    String rangeText;
    if (_startDate != null && _endDate != null) {
      final startDt = DateTime.parse(_startDate!);
      final endDt = DateTime.parse(_endDate!);
      final fmt = DateFormat('MMM d'); // e.g. "May 6"
      rangeText = '${fmt.format(startDt)} – ${fmt.format(endDt)}';
    } else {
      rangeText = 'No period data';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the fetched date range
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rangeText,
              style: mediumText(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'How Did You Feel ?',
            style: mediumText(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _symptomOptions.map((symptom) {
                  return FilterChip(
                    selectedColor: const Color.fromARGB(255, 255, 152, 253),
                    label: Text(
                      symptom,
                      style: mediumText(color: Colors.black),
                    ),
                    selected: _selectedSymptoms[symptom] ?? false,
                    onSelected:
                        (sel) => setState(() {
                          _selectedSymptoms[symptom] = sel;
                        }),
                  );
                }).toList(),
          ),

          const SizedBox(height: 32),
          Text(
            'Anything Else ?',
            style: mediumText(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            style: mediumText(color: Colors.black),
            cursorColor: Colors.black,
            maxLines: 3,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter any additional notes...',
              hintStyle: mediumText(),
            ),
          ),

          Center(
            child: ElevatedLayerButton(
              onClick: _updateSymptoms,
              buttonHeight: 55,
              buttonWidth: 180,
              animationDuration: const Duration(milliseconds: 200),
              animationCurve: Curves.ease,
              topDecoration: BoxDecoration(
                color: Colors.pinkAccent,
                border: Border.all(),
              ),
              topLayerChild: Text(
                "Done",
                style: mediumText(color: Colors.white),
              ),
              baseDecoration: BoxDecoration(
                color: Colors.deepPurple,
                border: Border.all(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
