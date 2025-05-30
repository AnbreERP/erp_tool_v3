import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_provider.dart';
import 'chat_message.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ChatRoomPage extends StatefulWidget {
  final int roomId;
  final String roomName;
  final void Function(File file) onFilePicked;

  const ChatRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.onFilePicked,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.fetchMessages(widget.roomId);
    chatProvider.initSocket(widget.roomId);
    chatProvider.initCurrentUser();
  }

  @override
  void didUpdateWidget(covariant ChatRoomPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.fetchMessages(widget.roomId).then((_) => _scrollToBottom());
      chatProvider.initSocket(widget.roomId);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final userId = chatProvider.currentUserId;
    final senderName = prefs.getString('name') ?? "You";

    chatProvider.sendMessageViaSocket(
      widget.roomId,
      text,
      userId,
      senderName,
    );

    await chatProvider.sendMessage(widget.roomId, text);
    _scrollToBottom();
    _messageController.clear();
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat.jm().format(dt); // 7:45 PM
    } catch (_) {
      return '';
    }
  }

  void _toggleEmojiPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      widget.onFilePicked(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final messages =
        chatProvider.messages.where((m) => m.roomId == widget.roomId).toList();
    int? newMessageIndex;
    final lastSeenId = chatProvider.lastSeenMessageIdPerRoom[widget.roomId];
    if (lastSeenId != null) {
      newMessageIndex = messages.indexWhere((m) => m.id > lastSeenId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Add Members',
            onPressed: () => _showAddMembersDialog(context, widget.roomId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text("No messages yet"))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      if (newMessageIndex != null && index == newMessageIndex) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "New Messages",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildMessageBubble(messages[index], chatProvider),
                          ],
                        );
                      }

                      return _buildMessageBubble(messages[index], chatProvider);
                    },
                  ),
          ),
          const Divider(height: 1),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text += emoji.emoji;
                },
                config: const Config(
                    columns: 7, emojiSizeMax: 32, bgColor: Color(0xFFF2F2F2)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                    onPressed: _toggleEmojiPicker,
                    icon: const Icon(Icons.emoji_emotions)),
                IconButton(
                    onPressed: _pickFile, icon: const Icon(Icons.attach_file)),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ChatProvider chatProvider) {
    final isMe = msg.senderId == chatProvider.currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue.shade100 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.senderName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(msg.message),
            Text(msg.sentAt,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context, int roomId) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final users = await chatProvider.fetchAllUsersExceptSelf();
    List<int> selectedUserIds = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Add Members to Room"),
            content: SizedBox(
              height: 300,
              width: 300,
              child: ListView(
                children: users.map((user) {
                  final userId = user['id'];
                  final userName = user['name'];
                  return CheckboxListTile(
                    title: Text(userName),
                    value: selectedUserIds.contains(userId),
                    onChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          selectedUserIds.add(userId);
                        } else {
                          selectedUserIds.remove(userId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('token');

                  final response = await http.post(
                    Uri.parse(
                        'http://127.0.0.1:4000/api/chat/rooms/$roomId/members'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({'memberIds': selectedUserIds}),
                  );

                  Navigator.pop(context);
                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Members added!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to add members")),
                    );
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
        );
      },
    );
  }
}
