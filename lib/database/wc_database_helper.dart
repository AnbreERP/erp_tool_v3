import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WcDatabaseHelper {
  static const String baseUrl =
      "http://127.0.0.1:4000/api/weinscoating"; // Change to AWS IP

  // ✅ Fetch all wainscoting estimates
  static Future<List<dynamic>> getWeinscoatingEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('"Token is missing. User is not authenticated."');
    }
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/estimates"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ); // Corrected API URL

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          print("⚠️ No estimates found.");
        }

        return data;
      } else {
        print("❌ Error: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to load estimates: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Error fetching estimates: $e");
      throw Exception("Failed to fetch estimates.");
    }
  }

  // ✅ Fetch a single wainscoting estimate by ID
  static Future<Map<String, dynamic>> getWeinscoatingEstimateById(
      int id) async {
    final response =
        await http.get(Uri.parse("$baseUrl/weinscoating-estimates/$id"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Estimate not found");
  }

  // ✅ Fetch a single wainscoting estimate by ID
  static Future<Map<String, dynamic>> DeleteEstimateById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/delete-estimates/$id"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Estimate not found");
  }

  static Future<List<Map<String, dynamic>>> fetchAllEstimates() async {
    try {
      // Retrieve the token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token =
          prefs.getString('token'); // Retrieve token from SharedPreferences

      if (token == null) {
        throw Exception("Token is missing. Please log in.");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/estimates"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Pass token in Authorization header
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedResponse = jsonDecode(response.body);
        if (decodedResponse.isEmpty) {
          print("⚠️ No estimates found.");
        }
        return decodedResponse.cast<Map<String, dynamic>>();
      } else {
        print("❌ Error: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to fetch estimates: ${response.statusCode}");
      }
    } catch (e) {
      print("🔥 Error fetching estimates: $e");
      throw Exception("Failed to fetch estimates.");
    }
  }

  // ✅ Add a new wainscoting estimate
  static Future<bool> addWeinscoatingEstimate(
      Map<String, dynamic> estimateData) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/save-estimate"), // ✅ Fixed API URL
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(estimateData),
      );

      if (response.statusCode == 201) {
        // ✅ Expecting 201 Created
        print("✅ Estimate saved successfully!");
        return true;
      } else {
        print("❌ Failed to save estimate. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("🔥 Error in addWeinscoatingEstimate: $e");
      return false;
    }
  }
}
