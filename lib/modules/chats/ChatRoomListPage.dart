import 'dart:io';

import 'package:erp_tool/widgets/MainScaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ChatRoomPage.dart';
import 'chat_provider.dart';
import 'direct_chat_page.dart';

class ChatMainPage extends StatefulWidget {
  const ChatMainPage({super.key});

  @override
  State<ChatMainPage> createState() => _ChatMainPageState();
}

class _ChatMainPageState extends State<ChatMainPage> {
  int? selectedRoomId;
  String? selectedRoomName;
  bool isPrivateChat = false;
  dynamic selectedItemId;
  String? selectedItemName;

  List<Map<String, dynamic>> privateUsers = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("❌ Token missing in ChatMainPage init");
      return;
    }

    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.fetchRooms();
    await _loadPrivateUsers();
  }

  Future<void> _loadPrivateUsers() async {
    try {
      final users = await Provider.of<ChatProvider>(context, listen: false)
          .fetchAllUsersExceptSelf();
      setState(() => privateUsers = users);
    } catch (e) {
      debugPrint("Failed to load users: $e");
    }
  }

  void _selectRoom(int roomId, String roomName, {bool private = false}) {
    setState(() {
      selectedRoomId = roomId;
      selectedRoomName = roomName;
      isPrivateChat = private;
      selectedItemId = roomId;
      selectedItemName = roomName;
    });
  }

  void _selectItem(dynamic id, String name, {bool private = false}) {
    setState(() {
      selectedItemId = id;
      selectedItemName = name;
      isPrivateChat = private;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final rooms = chatProvider.rooms;

    return MainScaffold(
      title: "Chat",
      actions: [
        IconButton(
          icon: const Icon(Icons.add_comment),
          onPressed: () => _showCreateRoomDialog(context),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 300,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey)),
            ),
            child: _buildSidebar(chatProvider),
          ),
          Expanded(
            child: selectedItemId == null
                ? const Center(child: Text("Select a chat to start"))
                : isPrivateChat
                    ? DirectChatPage(
                        key: ValueKey('dm_$selectedItemId'),
                        targetUserId: selectedItemId!,
                        targetUserName: selectedItemName!,
                        onSend: (String) {},
                        onFilePicked: (File file) {},
                      )
                    : ChatRoomPage(
                        key: ValueKey('room_$selectedRoomId'),
                        roomId: selectedRoomId!,
                        roomName: selectedRoomName!,
                        onFilePicked: (File file) {},
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ChatProvider chatProvider) {
    final rooms = chatProvider.rooms;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Rooms", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...rooms.map((room) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Text(_getInitials(room.name)),
            ),
            title: Text(room.name ?? 'Room #${room.id}'),
            trailing: chatProvider.unreadCounts[room.id] != null &&
                    chatProvider.unreadCounts[room.id]! > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chatProvider.unreadCounts[room.id]!.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
            selected: !isPrivateChat && selectedItemId == room.id,
            selectedTileColor: Colors.blue.shade50,
            onTap: () => _selectRoom(room.id, room.name ?? '', private: false),
          );
        }),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Direct Messages",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...privateUsers.map((user) {
          final userId = user['id'];
          return ListTile(
            leading: CircleAvatar(child: Text(user['name'][0].toUpperCase())),
            title: Text(user['name']),
            trailing: (chatProvider.directUnreadCounts[userId] ?? 0) > 0
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chatProvider.directUnreadCounts[userId].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                : null,
            selected: isPrivateChat && selectedItemId == userId,
            selectedTileColor: Colors.green.shade50,
            onTap: () => _selectItem(user['id'], user['name'], private: true),
          );
        }),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "?";
    final words = name.trim().split(" ");
    return words.length == 1
        ? words.first[0].toUpperCase()
        : (words[0][0] + words[1][0]).toUpperCase();
  }

  void _showCreateRoomDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    bool isGroup = true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Room"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Room Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Is Group Chat"),
                  const Spacer(),
                  StatefulBuilder(builder: (context, setState) {
                    return Switch(
                      value: isGroup,
                      onChanged: (val) => setState(() => isGroup = val),
                    );
                  }),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final chatProvider =
                    Provider.of<ChatProvider>(context, listen: false);
                final roomId =
                    await chatProvider.createRoom(name: name, isGroup: isGroup);
                if (roomId != null) {
                  Navigator.pop(context);
                  _selectRoom(roomId, name);
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }
}
