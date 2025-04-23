import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/utils/constants.dart';

void showMedicalReportUploadSheet(
  BuildContext context, {
  int defaultTabIndex = 0,
}) {
  showModalBottomSheet(
    backgroundColor: Colors.grey.shade200,
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return MedicalReportUploadContent(defaultTabIndex: defaultTabIndex);
        },
      );
    },
  );
}

class MedicalReportUploadContent extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final int defaultTabIndex;

  const MedicalReportUploadContent({
    Key? key,
    this.onBackToHome,
    this.defaultTabIndex = 0,
  }) : super(key: key);

  @override
  MedicalReportUploadContentState createState() =>
      MedicalReportUploadContentState();
}

class MedicalReportUploadContentState
    extends State<MedicalReportUploadContent> {
  String? selectedFileName;
  String? apiRawJson;
  String? gptResponse;

  Future<File> _loadBundledPDF() async {
    final byteData = await rootBundle.load('assets/file/blood_report.pdf');

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/blood_report.pdf',
    ); // ✅ DON'T include '/file/' in the temp path

    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> _uploadBundledPDF() async {
    final file = await _loadBundledPDF();
    setState(() {
      selectedFileName = 'medical_report.pdf';
    });
    await _uploadFile(file);
  }

  Future<void> _uploadFile(File file) async {
    final apiUrl = '${EnvConfig.baseUrl}/upload-report';

    // 1) grab the Firebase ID token for auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        apiRawJson = null;
        gptResponse = 'Error: not signed in';
      });
      return;
    }
    final token = await user.getIdToken();

    // 2) build multipart request
    final request =
        http.MultipartRequest('POST', Uri.parse(apiUrl))
          // add token as a normal form field
          ..fields['firebase_token'] = token!
          // add the file part (binary)
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    /*
    We use MultipartRequest/MultipartFile because:
    - It sets up `Content-Type: multipart/form-data` with the proper boundary for you.
    - It lets you mix text fields (firebase_token) and binary file parts in one request.
    - Standard JSON bodies can't carry a raw PDF in the same payload.
  */

    try {
      final streamed = await request.send();
      print("Response status: ${streamed.statusCode}");
      if (streamed.statusCode == 200) {
        final res = await http.Response.fromStream(streamed);
        print('Response body: ${res.body}');
        final decoded = jsonDecode(res.body);

        setState(() {
          apiRawJson = const JsonEncoder.withIndent(
            '  ',
          ).convert(decoded['json_data']);
          gptResponse = decoded['gpt_response'];
        });

        print('✅ JSON Data: $apiRawJson');
        print('✅ GPT Response: $gptResponse');
      } else {
        setState(() {
          apiRawJson = null;
          gptResponse = 'Failed with status: ${streamed.statusCode}';
        });
        print('❌ Upload failed: ${streamed.statusCode}');
      }
    } catch (e) {
      setState(() {
        apiRawJson = null;
        gptResponse = 'Error uploading file: $e';
      });
      print('❌ Exception during upload: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),

        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.05,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, size: 28),
                    ),
                  ),
                  Center(child: Text("Medical Reports", style: largeText())),
                ],
              ),
            ), // Header
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            DefaultTabController(
              length: 3,
              initialIndex: widget.defaultTabIndex,
              child: Card(
                shadowColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // TabBar inside the card header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicatorColor: Color.fromARGB(255, 106, 0, 255),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black,
                        tabs: [
                          Tab(
                            text: 'Insights',
                            style: mediumText(
                              color: Color.fromARGB(255, 106, 0, 255),
                            ),
                          ),
                          Tab(
                            text: 'Manage',
                            style: mediumText(
                              color: Color.fromARGB(255, 106, 0, 255),
                            ),
                          ),
                          Tab(
                            text: 'Upload',
                            style: mediumText(
                              color: Color.fromARGB(255, 106, 0, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // TabBarView inside the card body
                    Container(
                      height:
                          screenHeight * 0.7, // Adjust the height as needed.
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: TabBarView(
                        children: [
                          // Tab 1: cycst
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [SizedBox(height: 300)],
                            ),
                          ),
                          // Tab 2: mentrual cycle
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [SizedBox(height: 300)],
                            ),
                          ),
                          // Tab 3: hormones
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Upload Button
                                DottedBorder(
                                  color:
                                      Colors.deepPurple, // Dotted border color
                                  strokeWidth: 2, // Border thickness
                                  dashPattern: [
                                    8,
                                    4,
                                  ], // Dash pattern (8px dash, 4px gap)
                                  borderType:
                                      BorderType
                                          .RRect, // Rounded rectangle border
                                  radius: Radius.circular(8),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 5,
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _uploadBundledPDF,
                                      icon: Icon(
                                        Icons.upload_file,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      label: Text(
                                        'Upload File',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color.fromARGB(
                                          255,
                                          106,
                                          0,
                                          255,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 36,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 30),

                                // Show selected file name with progress tracker
                                if (selectedFileName != null)
                                  ProgressTrackerContainer(
                                    selectedFileName: selectedFileName,
                                  ),
                                if (apiRawJson != null || gptResponse != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 20),
                                      Text(
                                        "🧾 Extracted Medical Data (JSON):",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          border: Border.all(
                                            color: Colors.deepPurple,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: SelectableText(
                                          apiRawJson ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        "🤖 GPT Health Plan:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          border: Border.all(
                                            color: Colors.teal,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: SelectableText(
                                          gptResponse ?? '',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),

                                SizedBox(height: 300),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Additional dummy content to test scrolling.
            SizedBox(height: 30),

            // Save Button
          ],
        ),
      ),
    );
  }
}
