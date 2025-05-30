import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'chat_message.dart';
import 'chat_room.dart';

class ChatProvider with ChangeNotifier {
  int currentUserId = 0;

  List<ChatRoom> _rooms = [];
  List<ChatMessage> _messages = [];

  IO.Socket? _socket;

  List<ChatRoom> get rooms => _rooms;
  List<ChatMessage> get messages => _messages;
  Map<int, int> privateChatRoomMap = {}; // userId -> roomId
  Map<int, int> unreadCounts = {};
  Map<int, int> lastSeenMessageIdPerRoom = {};
  Map<int, List<ChatMessage>> directMessages = {}; // userId -> messages
  Map<int, int> unreadDMCounts = {}; // userId -> count
  Map<int, int> directUnreadCounts = {}; // userId -> unread count

  IO.Socket? get socket => _socket;

  Future<void> initCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('userId') ?? 0;
  }

  void sendMessageViaSocket(
      int roomId, String text, int userId, String senderName) {
    final message = {
      'roomId': roomId,
      'message': text,
      'senderId': userId,
      'senderName': senderName,
      'sentAt': DateTime.now().toIso8601String(),
    };
    socket?.emit('send_message', message);
  }

  Future<void> fetchRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("❌ Token is null inside fetchRooms");
      return; // prevent making the API call
    }

    print('✅ fetchRooms token: $token');

    final res = await http.get(
      Uri.parse('http://127.0.0.1:4000/api/chat/rooms'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      _rooms = data.map((r) => ChatRoom.fromJson(r)).toList();
      notifyListeners();
    } else {
      print("❌ Failed fetchRooms: ${res.statusCode} ${res.body}");
    }
    await fetchUnreadCounts();
  }

  Future<void> fetchMessages(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print("❌ Token is null - user may not be logged in");
      return;
    }

    final url = Uri.parse('http://127.0.0.1:4000/api/chat/messages/$roomId');
    print("📤 Fetching messages for room: $roomId");
    print("🔐 Using token: $token");

    try {
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("📥 Status Code: \${res.statusCode}");
      print("📥 Response Body: \${res.body}");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        _messages = data.map((m) => ChatMessage.fromJson(m)).toList();
        print("✅ Messages fetched: \${_messages.length}");
        notifyListeners();
      } else {
        print("❌ Failed to fetch messages. Code: \${res.statusCode}");
      }
    } catch (e) {
      print("❌ Exception while fetching messages: \$e");
      print("❌ Exception while fetching messages: $e");
    }
  }

  Future<void> sendMessage(int roomId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.post(
      Uri.parse('http://127.0.0.1:4000/api/chat/messages'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'roomId': roomId, 'message': text}),
    );

    await fetchMessages(roomId);
  }

  Future<int?> createRoom({String? name, bool isGroup = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/chat/rooms'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'isGroup': isGroup}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await fetchRooms();
      return data['roomId'];
    } else {
      print('❌ Failed to create room: \${response.body}');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllUsersExceptSelf() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception("Token missing");

    final res = await http.get(
      Uri.parse('http://127.0.0.1:4000/api/chat/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List<dynamic> users = jsonDecode(res.body);
      return users.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> fetchUnreadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('http://127.0.0.1:4000/api/chat/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      unreadCounts = {
        for (var entry in data.entries) int.parse(entry.key): entry.value as int
      };
      notifyListeners();
    } else {
      print("❌ Failed to fetch unread counts: ${res.statusCode}");
    }
  }

  Future<void> markMessageSeen(int messageId, int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/chat/messages/$messageId/seen'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      // Optionally: remove from unreadCounts or trigger fetchUnreadCounts
      print("✅ Marked message $messageId as seen");
    } else {
      print("❌ Failed to mark message as seen: ${res.statusCode}");
    }
    if (lastSeenMessageIdPerRoom[roomId] == null ||
        messageId > lastSeenMessageIdPerRoom[roomId]!) {
      lastSeenMessageIdPerRoom[roomId] = messageId;
      notifyListeners();
    }
  }

  void initSocket(int roomId) {
    if (_socket != null) {
      print("🔌 Socket already initialized");
      return;
    }

    _socket = IO.io('http://127.0.0.1:4000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();
    _socket!.onConnect((_) {
      print("✅ Socket connected");
      _socket!.emit("join_room", roomId);
    });

    _socket!.on("receive_message", (data) {
      print("📩 Received real-time message: \$data");
      final newMsg = ChatMessage.fromJson(data);
      _messages.add(newMsg);
      notifyListeners();
    });

    _socket!.onDisconnect((_) => print("🔌 Socket disconnected"));
  }

  Future<int?> createPrivateRoom(int targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/chat/private-room'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'targetUserId': targetUserId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['roomId'];
    } else {
      print('❌ Failed to create private room: ${response.body}');
      return null;
    }
  }

  Future<void> sendDirectMessage(int receiverId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await http.post(
      Uri.parse('http://127.0.0.1:4000/api/chat/dm/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiverId': receiverId, 'message': text}),
    );
  }

  Future<void> fetchDMs(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('http://127.0.0.1:4000/api/chat/dm/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      final msgs = data.map((m) => ChatMessage.fromJson(m)).toList();
      directMessages[userId] = msgs;
      notifyListeners();
    }
  }

  Future<String?> uploadFile(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse("http://127.0.0.1:4000/api/chat/upload");

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      return data['url']; // 🔗 File URL from backend
    } else {
      return null;
    }
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    print("🧹 Socket disposed");
  }
}
