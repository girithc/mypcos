import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/ui/components/bottom_sheet.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? firebaseToken;

  @override
  void initState() {
    super.initState();
    _getFirebaseToken();
  }

  Future<void> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      firebaseToken = await user.getIdToken();
    }
  }

  Future<File> _loadBundledPDF() async {
    final byteData = await rootBundle.load('assets/file/blood_report.pdf');

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/blood_report.pdf',
    ); // ✅ DON'T include '/file/' in the temp path

    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> uploadAndGetUrl() async {
    final supabase = Supabase.instance.client;
    final ImagePicker picker = ImagePicker();

    try {
      // Let user pick an image
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        print('❌ No image selected.');
        return;
      }

      final File file = File(image.path);
      final String fileName =
          'uploads/${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      // Upload to Supabase
      final fileBytes = await file.readAsBytes();
      await supabase.storage
          .from('your-bucket-name')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // Get public URL
      final String publicUrl = supabase.storage
          .from('your-bucket-name')
          .getPublicUrl(fileName);
      print('✅ Uploaded! Public URL: $publicUrl');

      // Optionally store or use the URL
      setState(() {
        gptResponse = "✅ Uploaded!\n$publicUrl";
      });
    } catch (e) {
      print('❌ Upload failed: $e');
      setState(() {
        gptResponse = 'Upload failed: $e';
      });
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
                        color: Color.fromARGB(255, 106, 0, 255),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 106, 0, 255),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: TabBar(
                          // fill whole tab with white when selected
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,

                          // selected text = black, unselected = white
                          labelColor: Colors.black87,
                          unselectedLabelColor: Colors.white,

                          // optional: tweak font size / weight
                          labelStyle: smallText(fontWeight: FontWeight.bold),
                          unselectedLabelStyle: smallText(),

                          tabs: [
                            Tab(text: 'Insights'),
                            Tab(text: 'Manage'),
                            Tab(text: 'Upload'),
                          ],
                        ),
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
                                      onPressed: uploadAndGetUrl,
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
