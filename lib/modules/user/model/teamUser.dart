class TeamUser {
  final int id;
  final String name;
  final String role;
  final String? reportsTo;

  TeamUser(
      {required this.id,
      required this.name,
      required this.role,
      this.reportsTo});

  factory TeamUser.fromJson(Map<String, dynamic> json) {
    return TeamUser(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      reportsTo: json['reportsTo'],
    );
  }
}
