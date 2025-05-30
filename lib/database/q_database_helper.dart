import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QDatabaseHelper {
  static const String baseUrl = "http://127.0.0.1:4000/api"; // Change to AWS IP

  // ✅ Fetch all quartz estimates
  static Future<List<Map<String, dynamic>>> getQuartzEstimates() async {
    String? token = await _getTokenFromPrefs();
    final response = await http.get(
      Uri.parse("$baseUrl/quartz-slab-estimates"),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token in the header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception("Unexpected data format from the server.");
      }
    } else {
      throw Exception("Failed to load quartz estimates");
    }
  }

  // ✅ Add a new quartz estimate
  static Future<bool> addQuartzEstimate(
      Map<String, dynamic> estimateData) async {
    String? token = await _getTokenFromPrefs();
    try {
      print("📤 Sending estimate data: ${jsonEncode(estimateData)}");

      final response = await http.post(
        Uri.parse("$baseUrl/save-estimates"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Pass the token in the header
        },
        body: jsonEncode(estimateData),
      );

      print("📩 Response Status: ${response.statusCode}");
      print("📩 Response Body: ${response.body}");

      return response.statusCode == 201; // Expecting 201 instead of 200
    } catch (error) {
      print("❌ Error sending estimate data: $error");
      return false;
    }
  }

  // ✅ Add quartz estimate details (multiple rows)
  static Future<bool> addQuartzEstimateDetails(
      List<Map<String, dynamic>> estimateDetails) async {
    String? token = await _getTokenFromPrefs();
    final response = await http.post(
      Uri.parse("$baseUrl/quartz-estimate-details"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Pass the token in the header
      },
      body: jsonEncode({'details': estimateDetails}),
    );
    return response.statusCode == 200;
  }

  // ✅ Fetch a single estimate by ID
  static Future<Map<String, dynamic>> getQuartzEstimateById(
      int estimateId) async {
    String? token = await _getTokenFromPrefs();
    final response = await http.get(
      Uri.parse('$baseUrl/quartz-slab-estimates/$estimateId'),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token in the header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(
          response.body); // Should return { "estimate": {...}, "rows": [...] }
    } else {
      throw Exception('Failed to load estimate');
    }
  }

  // ✅ Delete a quartz estimate
  static Future<bool> deleteQuartzEstimate(int id) async {
    String? token = await _getTokenFromPrefs();
    final response = await http.delete(
      Uri.parse("$baseUrl/quartz-estimates/$id"),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token in the header
      },
    );
    return response.statusCode == 200;
  }

  // ✅ Fetch detailed quartz estimate information
  static Future<Map<String, dynamic>> fetchEstimateDetails(
      int estimateId) async {
    String? token = await _getTokenFromPrefs();
    print("📤 Fetching details for estimateId: $estimateId");

    final response = await http.get(
      Uri.parse("$baseUrl/quartz-estimates/$estimateId/details"),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token in the header
        'Content-Type': 'application/json',
      },
    );

    print("📩 Response Status: ${response.statusCode}");
    print("📩 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to fetch quartz estimate details for ID: $estimateId. Response: ${response.body}");
    }
  }

  // Clear Data
  static Future<bool> clearData() async {
    String? token = await _getTokenFromPrefs();
    final response = await http.delete(
      Uri.parse("$baseUrl/quartz-estimates/clear"),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token in the header
      },
    );
    return response.statusCode == 200;
  }

  // Helper function to retrieve token from SharedPreferences
  static Future<String?> _getTokenFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('token'); // Retrieve the token from shared preferences
  }
}
