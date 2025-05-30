// direct_chat_page.dart
import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class DirectChatPage extends StatefulWidget {
  final int targetUserId;
  final String targetUserName;
  final void Function(String) onSend;
  final void Function(File file) onFilePicked;

  const DirectChatPage({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.onSend,
    required this.onFilePicked,
  });

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final TextEditingController _controller = TextEditingController();

  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    Provider.of<ChatProvider>(context, listen: false)
        .fetchDMs(widget.targetUserId);
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
      final provider = Provider.of<ChatProvider>(context, listen: false);

      final fileUrl = await provider.uploadFile(file);
      if (fileUrl != null) {
        // Send file link as message
        await provider.sendDirectMessage(widget.targetUserId, ' $fileUrl');
        await provider.fetchDMs(widget.targetUserId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed')),
        );
      }
    }
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.sendDirectMessage(widget.targetUserId, text);
    await provider.fetchDMs(widget.targetUserId); // refresh
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final messages = provider.directMessages[widget.targetUserId] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.targetUserName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == provider.currentUserId;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isMe ? Colors.green.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.message, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(msg.sentAt,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black45)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _controller.text += emoji.emoji;
                },
                config: const Config(
                  columns: 7,
                  emojiSizeMax: 32,
                  bgColor: Color(0xFFF2F2F2),
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: _toggleEmojiPicker,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
