class ChatMessage {
  final int senderId;
  final String senderName;
  final String message;
  final String sentAt;
  final int roomId; // ✅ Add this field

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.sentAt,
    required this.roomId, // ✅ Initialize
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['senderId'],
      senderName: json['senderName'],
      message: json['message'],
      sentAt: json['sentAt'],
      roomId: json['roomId'], // ✅ Parse from API
    );
  }
}
