class ChatMessage {
  final int id;
  final String message;
  final int senderId;
  final int roomId;
  final String senderName;
  final String sentAt;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.roomId,
    required this.senderName,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      message: json['message'] ?? '',
      senderId: json['sender_id'] ?? 0,
      roomId: json['room_id'] ?? 0,
      senderName: json['sender_name'] ?? 'Unknown',
      sentAt: json['sent_at'] ?? '',
    );
  }
}
