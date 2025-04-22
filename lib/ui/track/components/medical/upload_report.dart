import 'package:flutter/material.dart';

class UplooadMedicalReport extends StatefulWidget {
  const UplooadMedicalReport({super.key});

  @override
  State<UplooadMedicalReport> createState() => _UplooadMedicalReportState();
}

class _UplooadMedicalReportState extends State<UplooadMedicalReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medical Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}
