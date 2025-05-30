import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:4000/api';

  // 🔐 Login User
  Future<bool> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/user-login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim(), 'password': password.trim()}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String token = responseData['token'];

        // ✅ Save JWT Token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        return true; // ✅ Login Successful
      } else {
        return false; // ❌ Login Failed
      }
    } catch (error) {
      print('Error logging in: $error');
      return false;
    }
  }

  // 🔓 Logout User
  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ✅ Check if User is Logged In
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
}
