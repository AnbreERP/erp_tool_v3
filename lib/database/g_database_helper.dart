import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GraniteDatabaseHelper {
  static const String baseUrl =
      "http://127.0.0.1:4000/api/granite"; // Change to AWS IP

  // ✅ Fetch all granite estimates
  static Future<List<dynamic>> getGraniteEstimates() async {
    final token = await _getToken(); // Get token from SharedPreferences

    final response = await http.get(
      Uri.parse("$baseUrl/granite-estimates"),
      headers: {
        'Authorization': 'Bearer $token', // Pass token in Authorization header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load granite estimates");
    }
  }

  // ✅ Add a new granite estimate
  static Future<bool> addGraniteEstimate(
      Map<String, dynamic> estimateData) async {
    try {
      final token = await _getToken(); // Get token from SharedPreferences
      print("Sending estimate data: $estimateData");

      final response = await http.post(
        Uri.parse("$baseUrl/save-full-granite-estimate"),
        headers: {
          'Authorization':
              'Bearer $token', // Pass token in Authorization header
          "Content-Type": "application/json"
        },
        body: jsonEncode(estimateData),
      );

      if (response.statusCode == 201) {
        print("Estimate saved successfully.");
        print("Response body: ${response.body}");
        return true;
      } else {
        print("Failed to save estimate. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error saving estimate: $e");
      return false;
    }
  }

  // ✅ Fetch a single estimate by ID
  static Future<Map<String, dynamic>> getGraniteEstimateById(
      int estimateId) async {
    final token = await _getToken(); // Get token from SharedPreferences

    final response = await http.get(
      Uri.parse("$baseUrl/granite-estimates/$estimateId/details"),
      headers: {
        'Authorization': 'Bearer $token', // Pass token in Authorization header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Estimate not found");
    }
  }

  // ✅ Fetch Granite Stone Estimate (if a separate endpoint exists)
  static Future<List<Map<String, dynamic>>> fetchGraniteStoneEstimate() async {
    try {
      final token = await _getToken(); // Retrieve token

      final response = await http.get(
        Uri.parse("$baseUrl/granite-estimates"),
        headers: {
          'Authorization':
              'Bearer $token', // Pass token in Authorization header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception("Failed to fetch granite stone estimates");
      }
    } catch (e) {
      print("❌ Error: $e");
      throw Exception("Failed to fetch granite stone estimates: $e");
    }
  }

  // ✅ Fetch a single estimate by ID with token authentication
  static Future<Map<String, dynamic>> fetchEstimateDetails(
      int estimateId) async {
    try {
      final token = await _getToken(); // Get token from SharedPreferences

      final response = await http.get(
        Uri.parse("$baseUrl/estimates/$estimateId"),
        headers: {
          'Authorization':
              'Bearer $token', // Pass token in Authorization header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch estimate details.");
      }
    } catch (e) {
      print("❌ Error: $e");
      throw Exception("Failed to fetch estimate details: $e");
    }
  }

  // ✅ Clear all granite estimates (if applicable)
  static Future<bool> clearData() async {
    final token = await _getToken(); // Get token from SharedPreferences

    final response = await http.delete(
      Uri.parse("$baseUrl/granite-estimates/clear"),
      headers: {
        'Authorization': 'Bearer $token', // Pass token in Authorization header
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  // ✅ Fetch granite estimate details with token
  static Future<Map<String, dynamic>> getGraniteEstimateWithDetails(
      int estimateId) async {
    final token = await _getToken(); // Get token from SharedPreferences

    final response = await http.get(
      Uri.parse("$baseUrl/granite-estimates/$estimateId/details"),
      headers: {
        'Authorization': 'Bearer $token', // Pass token in Authorization header
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch granite estimate with details.");
    }
  }

  // ✅ Delete a granite estimate
  static Future<bool> deleteGraniteEstimate(int id) async {
    final token = await _getToken(); // Get token from SharedPreferences

    final response = await http.delete(
      Uri.parse("$baseUrl/granite-estimates/$id"),
      headers: {
        'Authorization': 'Bearer $token', // Pass token in Authorization header
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  // Helper function to get the token from SharedPreferences
  static Future<String> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      throw Exception("Token is missing. Please log in.");
    }

    return token;
  }
}
