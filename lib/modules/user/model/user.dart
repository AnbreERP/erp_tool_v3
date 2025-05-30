class User {
  final int id; // ✅ Change to int
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final List<int> permissions;

  User({
    required this.id, // ✅ Now correctly typed as an int
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.permissions,
  });

  // Factory method to create a User from a JSON object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ??
              0, // ✅ Correctly parsing as int
      firstName: json['first_name'] ?? 'Unknown',
      lastName: json['last_name'] ?? 'Unknown',
      email: json['email'] ?? 'No Email',
      role: json['roles'] ?? 'No Role',
      permissions: json['permissions'] != null
          ? List<int>.from(json['permissions'])
          : [], // ✅ Handle null safely
    );
  }
}
