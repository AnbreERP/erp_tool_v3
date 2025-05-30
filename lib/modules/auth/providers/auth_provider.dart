import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  int? _userId;
  String? _userRole;
  String? _authToken;
  String? _userName;
  String? _userProfilePicture;
  bool _isLoading = false;
  Map<String, String> _moduleRoles = {};
  List<String> _permissions = [];

  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _userId;
  String? get userRole => _userRole;
  String? get authToken => _authToken;
  String? get userName => _userName;
  String? get userProfilePicture => _userProfilePicture;
  bool get isLoading => _isLoading;

  Map<String, String> get moduleRoles => _moduleRoles;
  List<String> get permissions => _permissions;

  // Login method to authenticate the user and store session data
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/user-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim(), 'password': password.trim()}),
      );

      print('📩 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Decoded Response Data: $responseData');

        String? token = responseData['token'];
        Map<String, String> moduleRoles =
            Map<String, String>.from(responseData['moduleRoles'] ?? {});
        Map<String, dynamic> rawPermissions =
            Map<String, dynamic>.from(responseData['permissions'] ?? {});
        List<String> flatPermissions = rawPermissions.values
            .expand((permList) => List<String>.from(permList))
            .toList();
        int? userId = responseData['userId'];
        String? userName = responseData['name'];
        String? profilePicture = responseData['profilePicture'];

        if (token == null || userId == null) {
          print('❌ Error: Token or UserId is NULL');
          _isAuthenticated = false;
          _isLoading = false;
          notifyListeners();
          return;
        }

        // ✅ Store in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('moduleRoles', jsonEncode(moduleRoles));
        await prefs.setStringList('permissions', flatPermissions);
        await prefs.setInt('userId', userId);
        await prefs.setString('name', userName ?? '');
        await prefs.setString('profilePicture', profilePicture ?? '');

        // ✅ Assign to provider fields
        _authToken = token;
        _userRole = moduleRoles['estimate'] ?? 'None';
        _userId = userId;
        _userName = userName;
        _userProfilePicture = profilePicture;
        _moduleRoles = moduleRoles;
        _permissions = flatPermissions;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        _isAuthenticated = false;
        _isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      print('❌ Error logging in: $error');
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Logout method to clear session data
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('profilePicture');

    _authToken = null;
    _userRole = null;
    _userId = null;
    _userName = null;
    _userProfilePicture = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // ✅ Method to check if the user is already authenticated
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final int? userId = prefs.getInt('userId');
    final String? name = prefs.getString('name');
    final String? profilePicture = prefs.getString('profilePicture');
    final String? moduleRolesJson = prefs.getString('moduleRoles');
    final List<String> permissions = prefs.getStringList('permissions') ?? [];

    if (token != null && userId != null && moduleRolesJson != null) {
      _authToken = token;
      _userId = userId;
      _userName = name;
      _userProfilePicture = profilePicture;
      _moduleRoles = Map<String, String>.from(jsonDecode(moduleRolesJson));
      _permissions = permissions;
      _userRole = _moduleRoles['estimate'] ?? 'None';
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> checkEmailExists(String email) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return response.statusCode == 200;
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/api/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );

    return response.statusCode == 200;
  }
}
