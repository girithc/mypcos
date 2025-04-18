import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roo_mobile/utils/constants.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder:
          (BuildContext context) => SafeArea(
            child: SizedBox(
              height: 144,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleImageSelection();
                    },
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('Photo'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleFileSelection();
                    },
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('File'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = _messages.indexWhere(
            (element) => element.id == message.id,
          );
          final updatedMessage = (_messages[index] as types.FileMessage)
              .copyWith(isLoading: true);

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index = _messages.indexWhere(
            (element) => element.id == message.id,
          );
          final updatedMessage = (_messages[index] as types.FileMessage)
              .copyWith(isLoading: null);

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final userMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(userMessage);

    try {
      final body = jsonEncode({
        'q': message.text,
        'firebase_token': await _auth.currentUser?.getIdToken(),
      });
      final uri = Uri.parse('${EnvConfig.baseUrl}/ask');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      //print(response.statusCode);
      //print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? 'No answer found.';

        final botMessage = types.TextMessage(
          author: const types.User(id: 'bot'),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: answer,
        );

        _addMessage(botMessage);
      } else {
        _addMessage(
          types.TextMessage(
            author: const types.User(id: 'bot'),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: const Uuid().v4(),
            text: 'Oops! Server error (${response.statusCode}).',
          ),
        );
      }
    } catch (e) {
      _addMessage(
        types.TextMessage(
          author: const types.User(id: 'bot'),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: 'Network error: $e',
        ),
      );
    }
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/data/messages.json');
    final messages =
        (jsonDecode(response) as List)
            .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
            .toList();

    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      // optionally center your title, or leave title blank
      title: const SizedBox.shrink(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: Text('Roo', style: largeText(color: Colors.deepPurple)),
          ),
        ),
      ],
    ),
    body: Chat(
      messages: _messages,
      onAttachmentPressed: _handleAttachmentPressed,
      onMessageTap: _handleMessageTap,
      onPreviewDataFetched: _handlePreviewDataFetched,
      onSendPressed: _handleSendPressed,
      showUserAvatars: true,
      showUserNames: true,
      user: _user,
    ),

    /*
    floatingActionButton: SizedBox(
      height: MediaQuery.of(context).size.height * 0.045,
      child: FloatingActionButton.extended(
        onPressed: () {
          // ✅ Switch to ChatHomePage within the same tab
          (context.findAncestorStateOfType<MyHomePageState>())?.setState(() {
            (context.findAncestorStateOfType<MyHomePageState>())?.showChatHome =
                true;
            (context.findAncestorStateOfType<MyHomePageState>())
                ?.selectedIndex = 2;
          });
        },
        label: Row(
          children: [
            Text(
              'PCOS GPT  ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Icon(Icons.expand_more_rounded, color: Colors.deepPurpleAccent),
          ],
        ),
        backgroundColor: Colors.black,
      ),
    ),

    floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
    */
  );
}

void showChatBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ), // Curved top borders
    ),
    builder: (BuildContext context) {
      return Container(
        height:
            MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: Colors.white, // Background color of the bottom sheet
        ),
        child: Column(
          children: [
            // Header with "Roo" and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ROO',
                    style: GoogleFonts.sriracha(
                      // ✅ Use Rock Salt from Google Fonts
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 106, 0, 255),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: const Color.fromARGB(255, 106, 0, 255),
                    ),
                    onPressed:
                        () => Navigator.of(context).pop(), // Close action
                  ),
                ],
              ),
            ),

            // ChatPage with curved borders
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ChatPage(), // Your chatPage widget
              ),
            ),
          ],
        ),
      );
    },
  );
}
