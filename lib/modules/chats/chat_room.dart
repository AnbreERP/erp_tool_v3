class ChatRoom {
  final int id;
  final String? name;
  final bool isGroup;

  ChatRoom({required this.id, this.name, required this.isGroup});

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      isGroup: json['is_group'] == 1,
    );
  }
}
