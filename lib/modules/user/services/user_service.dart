import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user.dart';

class UserService {
  static const String _baseUrl = 'http://127.0.0.1:4000/api/user';
  // This function sends a POST request to the backend to create a new user
  Future<bool> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required List<String> roleIds,
    required List<int> permissions,
    required String department,
    required Map<String, String> moduleRoles,
    int? teamId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Ensure token is stored correctly
    print("Token retrieved from SharedPreferences: $token");

    if (token == null) {
      throw Exception("Token is missing");
    }
    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/user/create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'roleIds': roleIds,
        'permissions': permissions,
        'department': department,
        'teamId': teamId,
        'moduleRoles': moduleRoles ?? {},
      }),
    );

    return response.statusCode == 201;
  }

  // Function to fetch departments from the backend
  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    const url =
        'http://127.0.0.1:4000/api/user/departments'; // Your backend URL

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse the response body as a list of departments
        List<dynamic> departments = json.decode(response.body);

        // Return the departments as a list of Map<String, dynamic>
        return List<Map<String, dynamic>>.from(departments);
      } else {
        throw Exception('Failed to load departments');
      }
    } catch (e) {
      print('Error fetching departments: $e');
      return []; // Return an empty list in case of an error
    }
  }

  // Fetch roles from the backend
  Future<List<String>> fetchRoles() async {
    const url =
        'http://127.0.0.1:4000/api/user/roles'; // Endpoint to fetch roles

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> roles = json.decode(response.body);
        return roles
            .map((role) => role['role_name'] as String)
            .toList(); // Get the role names
      } else {
        throw Exception('Failed to load roles');
      }
    } catch (e) {
      print('Error fetching roles: $e');
      return [];
    }
  }

  // Fetch permissions from the backend
  Future<List<String>> fetchPermissions() async {
    const url =
        'http://127.0.0.1:4000/api/user/permissions'; // Endpoint to fetch permissions

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> permissions = json.decode(response.body);
        return permissions
            .map((permission) => permission['permission_name'] as String)
            .toList(); // Get the permission names
      } else {
        throw Exception('Failed to load permissions');
      }
    } catch (e) {
      print('Error fetching permissions: $e');
      return [];
    }
  }

  // Fetch permissions for a specific role
  Future<List<String>> fetchPermissionsForRole(String role) async {
    const url =
        'http://127.0.0.1:4000/api/user/roles/permissions'; // Endpoint to fetch permissions for a role

    try {
      final response = await http.get(Uri.parse('$url/$role'));

      if (response.statusCode == 200) {
        // Parse the response body as a list of permissions
        List<dynamic> permissions = json.decode(response.body);
        return permissions
            .map((permission) => permission['permission_name'] as String)
            .toList(); // Return the permission names
      } else {
        throw Exception('Failed to load permissions for role');
      }
    } catch (e) {
      print('Error fetching permissions for role: $e');
      return [];
    }
  }

  // Fetch users from the backend
  Future<List<User>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/all-users'));

      if (response.statusCode == 200) {
        // ✅ Print raw response for debugging
        print('Raw API Response: ${response.body}');

        // ✅ Parse the response
        final List<dynamic> usersJson = json.decode(response.body);

        // ✅ Print parsed JSON
        print('Parsed JSON: $usersJson');

        // ✅ Convert to User objects
        List<User> userList =
            usersJson.map((json) => User.fromJson(json)).toList();

        // ✅ Print mapped User objects
        print('Mapped User List: $userList');

        return userList;
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      print('Error fetching users: $error');
      throw Exception('Failed to load users');
    }
  }

  Future<List<Map<String, dynamic>>> fetchGroupedPermissions() async {
    final response = await http
        .get(Uri.parse('http://127.0.0.1:4000/api/user/permissions/grouped'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load permissions');
    }
  }

  Future<List<int>> fetchDefaultPermissionsForRole(String role) async {
    final response = await http.get(Uri.parse(
        'http://127.0.0.1:4000/api/user/roles/default-permissions/$role'));

    if (response.statusCode == 200) {
      final List<dynamic> ids = jsonDecode(response.body);
      return ids.cast<int>();
    } else {
      throw Exception('Failed to fetch default permissions');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPermissionsWithIds() async {
    const url =
        'http://127.0.0.1:4000/api/user/permissions'; // Adjust endpoint as needed
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data
            .map((perm) =>
                {'id': perm['id'], 'permission_name': perm['permission_name']})
            .toList();
      } else {
        throw Exception('Failed to load permissions');
      }
    } catch (e) {
      print('Error fetching permissions: $e');
      return [];
    }
  }

  //Teams
  Future<int?> createTeam(String name, int? leadId, List<int> memberIds) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/user/teams/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'team_lead_id': leadId,
        'member_ids': memberIds,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['teamId'];
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTeams() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:4000/api/user/teams'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTeamMembers(int teamId) async {
    final response = await http
        .get(Uri.parse('http://127.0.0.1:4000/api/user/teams/$teamId/members'));
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> fetchUsersAsMap() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:4000/api/user/all-users'));
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<bool> assignUserToTeam(int userId, int teamId) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/user/teams/$teamId/add-user'),
      body: jsonEncode({'userId': userId}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

//
}
