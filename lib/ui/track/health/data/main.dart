import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:roo_mobile/ui/track/action_card.dart';
import 'package:roo_mobile/ui/track/health/data/body_data.dart';
import 'package:roo_mobile/ui/track/health/main.dart';
import 'package:roo_mobile/ui/track/secondary_action_card.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:simple_animated_button/elevated_layer_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  bool isFetchingDocuments = false;
  Future<void> uploadFileToSupabaseAndServer() async {
    final picker = ImagePicker();
    final supabase = Supabase.instance.client;

    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        print('❌ No image selected');
        return;
      }

      final file = File(image.path);
      final fileBytes = await file.readAsBytes();

      // Show filename input and preview bottom sheet
      String? enteredFilename = await showUploadPreviewSheet(
        context,
        image.path,
      );

      if (enteredFilename == null || enteredFilename.trim().isEmpty) {
        print("❌ Upload cancelled or no filename provided");
        return;
      }

      final fileName =
          'uploads/${DateTime.now().millisecondsSinceEpoch}_$enteredFilename.jpg';

      await supabase.storage
          .from('images')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = supabase.storage.from('images').getPublicUrl(fileName);
      print('✅ Supabase Upload Successful: $publicUrl');

      if (!mounted) return;
      setState(() {
        uploadedFileUrl = publicUrl;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in.");
        return;
      }

      final firebaseToken = await user.getIdToken();

      final uri = Uri.parse('${EnvConfig.baseUrl}/documents/upload-document');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_token': firebaseToken,
          'image_url': publicUrl,
          'file_name': enteredFilename, // ⬅️ Add filename here
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Server Upload Successful');
        await fetchDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File uploaded and saved to server!')),
        );
      } else {
        print('❌ Server error: ${response.body}');
      }
    } catch (e) {
      print('❌ Upload failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  String? uploadedFileUrl =
      "https://itbezvuwkxkjvmwazicb.supabase.co/storage/v1/object/public/images/uploads/1745446860194_image_picker_A0AE246C-9B07-47FD-ADF3-DBBF1CFC501E-10634-000004B7B1EA7AF4.jpg"; // 👈 State variable to hold the uploaded file URL

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    setState(() {
      isFetchingDocuments = true;
    });

    final fetchedDocs = await getDocuments();

    if (!mounted) return;
    setState(() {
      docs = fetchedDocs;
      isFetchingDocuments = false;
    });
  }

  List docs = [];
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in.");
      return [];
    }

    final firebaseToken = await user.getIdToken();
    final uri = Uri.parse('${EnvConfig.baseUrl}/documents/get-documents');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_token': firebaseToken}),
    );
    print("Response: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final rawWrapper = json['documents'];

      if (rawWrapper is List &&
          rawWrapper.length > 1 &&
          rawWrapper[1] is List) {
        final rawDocs = rawWrapper[1];
        final safeDocs = rawDocs.whereType<Map<String, dynamic>>().toList();
        //print("📄 Received ${safeDocs.length} safe documents");
        //print("objects: $safeDocs");
        return safeDocs;
      } else {
        print("⚠️ Invalid document wrapper format.");
        return [];
      }
    } else {
      print("❌ Failed to fetch documents: ${response.body}");
      return [];
    }
  }

  Future<void> saveNewFileName(int documentId, String newFilename) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in.");
      return;
    }

    final firebaseToken = await user.getIdToken();
    final uri = Uri.parse('${EnvConfig.baseUrl}/documents/edit-document-name');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_token': firebaseToken,
          'document_id': documentId,
          'new_filename': newFilename,
        }),
      );

      Navigator.pop(context); // Remove loading dialog

      if (response.statusCode == 200) {
        print("✅ Filename updated successfully!");
      } else {
        print("❌ Failed to update filename: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      Navigator.pop(context); // Ensure dialog closes on error
      print("❌ Error: $e");
    }
  }

  Future<void> confirmAndDeleteDocument(int documentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Delete Image"),
            content: Text("Are you sure you want to delete this image?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancel", style: TextStyle(color: Colors.black45)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in.");
      return;
    }

    final firebaseToken = await user.getIdToken();
    final uri = Uri.parse('${EnvConfig.baseUrl}/documents/delete-document');

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_token': firebaseToken,
          'document_id': documentId,
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        print("✅ Document deleted successfully");
        await fetchDocuments();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image deleted')));
      } else {
        print("❌ Failed to delete document: ${response.statusCode}");
        print("Body: ${response.body}");
      }
    } catch (e) {
      Navigator.pop(context); // Ensure dialog closes on error
      print("❌ Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Cards (3)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(
                  title: "Body Data",
                  titleWidget: Text("Body Data", style: largeText()),
                  indicatorWidget: FeelBetterIndicator(
                    message: "Self-care",
                    icon1: Icons.woman,
                    icon2: Icons.cruelty_free_outlined, // or Icons.favorite
                    backgroundColor: Colors.pink.shade50,
                    iconColor: Colors.pinkAccent,
                  ),
                  onTap: () => {print("Tap"), showBodyDataBottomSheet(context)},
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: screenHeight * 0.018),
                child: ActionCard(
                  title: "Fitness Data", // TODO: Change to "Fitness Data"
                  titleWidget: Text("Fitness Data", style: largeText()),
                  indicatorWidget: FeelBetterIndicator(
                    message: "Self-care",
                    icon1: Icons.monitor_heart_rounded,
                    icon2: Icons.favorite_border, // or Icons.favorite
                    backgroundColor: Colors.pink.shade50,
                    iconColor: Colors.pinkAccent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section Title
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.03,
            vertical: screenHeight * 0.015,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Files",
                style: largeText(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              DottedBorder(
                color: Colors.white,
                strokeWidth: 2,
                dashPattern: [4, 1],
                borderType: BorderType.RRect,
                radius: Radius.circular(15),
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.4, // ⬅️ Slightly wider
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await uploadFileToSupabaseAndServer();
                      await fetchDocuments(); // 👈 Refresh the docs after upload
                    },
                    icon: Icon(
                      Icons.file_upload_outlined,
                      color: iconColor,
                      size: 18, // ⬅️ Slightly bigger icon
                    ),
                    label: Text('Upload File', style: smallText()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ), // ⬅️ More breathing room
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size(0, 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Secondary Action Cards (2)
        ...(isFetchingDocuments
            ? List.generate(3, (index) => buildShimmerCard(screenHeight))
            : docs.map((doc) {
              final url = doc['image_url'] ?? '';
              final filename = doc['filename'] ?? 'Untitled';
              final createdAt =
                  (doc['created_at'] as String?)?.split('T').first ?? '';

              return FileItemCard(
                titleWidget: Text(filename, style: mediumText()),
                subtitleWidget: Text(
                  "$createdAt",
                  style: smallText(color: textColor),
                ),
                imageUrl: url,
                onTap:
                    () => showFilePreview(context, url, filename, "$createdAt"),
                onEdit: () {
                  showEditFileSheet(
                    doc['id'],
                    context,
                    url,
                    filename,
                    "Uploaded on $createdAt",
                    (newName) {
                      print("Renamed to: $newName");
                    },
                  );
                },
              );
            }).toList()),
        SizedBox(height: screenHeight * 0.1),
      ],
    );
  }

  Future<String?> showUploadPreviewSheet(
    BuildContext context,
    String imagePath,
  ) {
    final TextEditingController _nameController = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade200,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ListView(
                controller: controller,
                children: [
                  Text(
                    "Name your file",
                    style: mediumText(color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    maxLines: 1,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: 'Enter filename',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedLayerButton(
                      onClick: () {
                        final name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          Navigator.pop(context, name);
                        }
                      },
                      buttonHeight: 50,
                      buttonWidth: MediaQuery.of(context).size.width * 0.9,
                      topLayerChild: Text(
                        "Complete",
                        style: mediumText(color: Colors.black),
                      ),
                      topDecoration: BoxDecoration(
                        color: Colors.greenAccent,
                        border: Border.all(),
                      ),
                      baseDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        border: Border.all(),
                      ),
                      animationCurve: Curves.easeInOut,
                      animationDuration: Duration(milliseconds: 250),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showFilePreview(
    BuildContext context,
    String fileUrl,
    String title,
    String subtitle,
  ) {
    print("Tapped");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return StatefulBuilder(
              builder: (context, setState) {
                bool _imageLoaded = false;
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: ListView(
                    controller: controller,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          title,
                          style: largeText(color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            if (!_imageLoaded)
                              Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            Image.network(
                              fileUrl,
                              height: MediaQuery.of(context).size.height * 0.5,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) {
                                  Future.delayed(Duration.zero, () {
                                    if (!_imageLoaded) {
                                      setState(() {
                                        _imageLoaded = true;
                                      });
                                    }
                                  });
                                  return child;
                                } else {
                                  return const SizedBox(); // don't show default loading
                                }
                              },
                              errorBuilder:
                                  (context, error, stackTrace) => Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Error loading image.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          subtitle,
                          style: mediumText(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void showEditFileSheet(
    final int documentId,
    BuildContext context,
    String fileUrl,
    String filename,
    String subtitle,
    Function(String) onRename,
  ) {
    final TextEditingController _controller = TextEditingController(
      text: filename,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade200,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ListView(
                controller: controller,
                children: [
                  Text(
                    "Edit Filename",
                    style: mediumText(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.white, blurRadius: 4),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 2,
                      minLines: 1,
                      cursorColor: Colors.black,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Enter filename',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      fileUrl,
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading image.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedLayerButton(
                      onClick: () async {
                        final newFilename = _controller.text.trim();
                        if (newFilename.isNotEmpty) {
                          await saveNewFileName(documentId, newFilename);
                          onRename(newFilename);
                          fetchDocuments();
                          Navigator.pop(context); // Dismiss sheet
                        } else {
                          print("❌ Filename cannot be empty");
                        }
                      },
                      buttonHeight: 55,
                      buttonWidth: MediaQuery.of(context).size.width * 0.9,
                      animationDuration: const Duration(milliseconds: 200),
                      animationCurve: Curves.ease,
                      topDecoration: BoxDecoration(
                        color: Colors.greenAccent,
                        border: Border.all(),
                      ),
                      topLayerChild: Text(
                        "Save",
                        style: mediumText(color: Colors.black54),
                      ),
                      baseDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        border: Border.all(),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: () async {
                        // TODO: Confirm deletion + call delete endpoint
                        await confirmAndDeleteDocument(documentId);
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Delete Image",
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MedicalDocument {
  final int id;
  final String filename;
  final String imageUrl;
  final DateTime createdAt;

  MedicalDocument({
    required this.id,
    required this.filename,
    required this.imageUrl,
    required this.createdAt,
  });

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'],
      filename: json['filename'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

Widget buildShimmerCard(double screenHeight) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: screenHeight * 0.02,
      vertical: screenHeight * 0.015,
    ),
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}
