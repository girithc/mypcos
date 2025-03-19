import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roo_mobile/main.dart';
import 'package:roo_mobile/ui/chat.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  List<String> categories = ["Chats", "Groups", "Friends", "Journal"];
  int selectedIndex = 0;
  final TextEditingController _journalController = TextEditingController();
  List<JournalEntry> notes = []; // Store text and images for each entry
  String _groupSearchQuery = '';
  List<Uint8List> _uploadedImages = []; // To store multiple uploaded images

  // Mock data
  final List<ChatData> chats = [
    ChatData(
      category: "Chats",
      title: "Alice",
      lastMessage: "Hey, how are you?",
      time: "10:30 AM",
    ),
    ChatData(
      category: "Chats",
      title: "Bob",
      lastMessage: "See you tomorrow!",
      time: "9:45 AM",
    ),
  ];

  final List<Group> groups = [
    Group(
      name: "Flutter Devs",
      members: 12,
      lastActivity: "New project update",
    ),
    Group(name: "Design Team", members: 8, lastActivity: "UI review meeting"),
    Group(
      name: "Flutter Devs",
      members: 12,
      lastActivity: "New project update",
    ),
    Group(name: "Design Team", members: 8, lastActivity: "UI review meeting"),
  ];

  final List<Friend> friends = [
    Friend(name: "Alice", mutualGroups: ["Flutter Devs", "Design Team"]),
    Friend(name: "Charlie", mutualGroups: ["Sports Club"]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categories[selectedIndex],
                  style: GoogleFonts.sriracha(
                    // ✅ Apply Rock Salt font
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Show the dialog containing the chatPage
                    showChatBottomSheet(context);
                    // ✅ Switch to ChatHomePage within the same tab
                    /*
                    (context.findAncestorStateOfType<MyHomePageState>())
                        ?.setState(() {
                          (context.findAncestorStateOfType<MyHomePageState>())
                              ?.showChatHome = false;
                          (context.findAncestorStateOfType<MyHomePageState>())
                              ?.selectedIndex = 2;
                        });

                        */
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                            0.5,
                          ), // ✅ Grey shadow with transparency
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(
                            0,
                            3,
                          ), // Shadow position (horizontal, vertical)
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      child: Icon(
                        Icons.auto_awesome,
                        color: const Color.fromARGB(255, 106, 0, 255),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Categories(
            categories: categories,
            selectedIndex: selectedIndex,
            onCategorySelected:
                (index) => setState(() => selectedIndex = index),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (selectedIndex) {
      case 0:
        return _buildChatsView();
      case 1:
        return _buildGroupsView();
      case 2:
        return _buildFriendsView();
      case 3:
        return _buildJournalView();
      default:
        return Container();
    }
  }

  Widget _buildChatsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: chats.length,
      itemBuilder: (context, index) => _buildChatItem(chats[index]),
    );
  }

  Widget _buildGroupsView() {
    return Container(
      color: const Color.fromARGB(255, 106, 0, 255),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.25),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                hintStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _groupSearchQuery = value),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) => _buildGroupTile(groups[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: chats.length,
      itemBuilder: (context, index) => _buildFriendCard(chats[index]),
    );
  }

  void _uploadImage() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _uploadedImages.add(imageBytes); // Add the uploaded image to the list
      });
    }
  }

  void _addEntry() {
    final entryText = _journalController.text;
    if (entryText.isNotEmpty || _uploadedImages.isNotEmpty) {
      setState(() {
        notes.add(
          JournalEntry(
            text: entryText,
            images: List.from(_uploadedImages), // Store text and images
          ),
        );
        _journalController.clear(); // Clear the text field
        _uploadedImages.clear(); // Clear the uploaded images
      });
    }
  }

  Widget _buildJournalView() {
    return Container(
      color: const Color.fromARGB(255, 106, 0, 255),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        // Make the whole content scrollable
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _journalController,
                        decoration: InputDecoration(
                          hintText: 'Write your note...',
                          border: InputBorder.none,
                        ),
                        maxLines: null, // Allow the text field to expand
                        minLines: 1, // Start with at least one line
                        style: TextStyle(color: Colors.black, fontSize: 18),
                        cursorColor: Colors.black,
                      ),
                      // ✅ Increased space when no images are uploaded
                      if (_uploadedImages.isEmpty)
                        const SizedBox(height: 80), // More vertical space
                      // ✅ Display uploaded images if available
                      if (_uploadedImages.isNotEmpty)
                        Container(
                          height: 140,
                          margin: const EdgeInsets.only(bottom: 0, top: 40),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _uploadedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _uploadedImages[index],
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      // ✅ Reduced space when images are uploaded
                      if (_uploadedImages.isNotEmpty)
                        const SizedBox(
                          height: 60,
                        ), // Less space when images are uploaded
                    ],
                  ),
                ),

                // ✅ Positioned buttons at the bottom-right
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _uploadImage,
                        child: Text(
                          '+ Photo',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Colors.black, width: 2.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addEntry,
                        child: Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ✅ Conditionally render the ListView.builder only if there are notes
            ListView.builder(
              shrinkWrap:
                  true, // Ensures that the list doesn't take more space than needed
              physics:
                  NeverScrollableScrollPhysics(), // Disable scrolling for the list itself
              itemCount: notes.length,
              itemBuilder:
                  (context, index) =>
                      _buildNoteItem(notes.reversed.toList()[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(ChatData chat) {
    return Card(
      color: const Color.fromARGB(255, 106, 0, 255),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.person, color: Colors.black),
          backgroundColor: Colors.white,
        ),
        title: Text(
          chat.title,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          chat.lastMessage!,
          style: TextStyle(color: Colors.white),
        ),
        trailing: Text(chat.time!, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.group, color: Colors.deepPurple),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${group.members} members • ${group.lastActivity}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildGroupTile(Group group) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Icon(
                    Icons.group,
                    size: 40,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                group.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                "London, GB",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 5),
              Text(
                "${group.members} members",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Colors.deepPurple.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(ChatData chat) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey, // Border color
              width: 1, // Border width
            ),
          ),
        ),
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person, color: Colors.white),
            backgroundColor: Color.fromARGB(255, 106, 0, 255),
          ),
          title: Text(
            chat.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          subtitle: const Text(
            "London, GB",
            style: TextStyle(color: Colors.deepPurple),
          ),
          trailing: const Icon(Icons.more_horiz_outlined),
        ),
      ),
    );
  }

  Widget _buildNoteItem(JournalEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.text,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),

            if (entry.images.isNotEmpty) // Display images if any
              Column(
                children: [
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // Fully rounded
                            child: Image.memory(
                              entry.images[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            Container(
              margin: EdgeInsets.only(top: 10),
              alignment: Alignment.bottomRight,
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz_outlined, // Three-dot icon
                  color: Colors.black,
                ),
                onSelected: (String value) {
                  // Handle selected action
                  if (value == 'Edit') {
                    // Implement edit action
                    print('Edit tapped');
                  } else if (value == 'Delete') {
                    // Implement delete action
                    print('Delete tapped');
                  } else if (value == 'Info') {
                    // Implement info action
                    print('Info tapped');
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(value: 'Info', child: Text('Info')),

                    PopupMenuItem<String>(value: 'Edit', child: Text('Edit')),
                    PopupMenuItem<String>(
                      value: 'Delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Categories extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  const Categories({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPaddin),
      child: SizedBox(
        height: 25,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) => buildCategory(index),
        ),
      ),
    );
  }

  Widget buildCategory(int index) {
    return GestureDetector(
      onTap: () => onCategorySelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPaddin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              categories[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    selectedIndex == index
                        ? Colors.black
                        : Colors.deepPurpleAccent.shade200,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: kDefaultPaddin / 8),
              height: 2,
              width: 30,
              color: selectedIndex == index ? Colors.black : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

const kDefaultPaddin = 20.0;

class ChatData {
  final String category;
  final String title;
  final String? lastMessage;
  final String? time;

  ChatData({
    required this.category,
    required this.title,
    this.lastMessage,
    this.time,
  });
}

class Group {
  final String name;
  final int members;
  final String lastActivity;

  Group({
    required this.name,
    required this.members,
    required this.lastActivity,
  });
}

class Friend {
  final String name;
  final List<String> mutualGroups;

  Friend({required this.name, required this.mutualGroups});
}

class JournalEntry {
  final String text;
  final List<Uint8List> images;

  JournalEntry({required this.text, required this.images});
}
