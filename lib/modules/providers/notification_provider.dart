// lib/providers/notification_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get notifications => _notifications;

  Future<void> fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');

    final response = await http.get(
      Uri.parse("http://127.0.0.1:4000/api/notifications?user_id=$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      _notifications =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));
      notifyListeners(); //  this triggers UI update
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  // Define this alias method (optional, but helps if you're calling `refreshNotifications`)
  Future<void> refreshNotifications() => fetchNotifications();

  Future<void> markAsSeenOnServer(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse("http://127.0.0.1:4000/api/notifications/$id/seen"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      markAsSeen(id);
    } else {
      throw Exception("Failed to mark as seen");
    }
  }

  void setNotifications(List<Map<String, dynamic>> newList) {
    _notifications = newList;
    notifyListeners();
  }

  void addNotification(Map<String, dynamic> newNotif) {
    _notifications.insert(0, newNotif); // add to top
    notifyListeners();
  }

  void removeNotification(int id) {
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();
  }

  void markAsSeen(int id) {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['seen'] = 1;
      notifyListeners();
    }
  }

  void markAllAsSeen() {
    for (var n in _notifications) {
      n['seen'] = 1;
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
