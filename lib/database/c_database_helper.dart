import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CDatabaseHelper {
  static const String baseUrl = "http://127.0.0.1:4000/api/charcoal";

  static Future<List<dynamic>> getEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('"Token is missing. User is not authenticated."');
    }
    final response = await http.get(
      Uri.parse("$baseUrl/charcoal-estimates"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Failed to load estimates");
  }

  static Future<Map<String, dynamic>> getEstimate(int id) async {
    final response =
        await http.get(Uri.parse("$baseUrl/charcoal-estimates/$id"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Failed to load estimate");
  }

  static Future<bool> createEstimate(Map<String, dynamic> estimateData) async {
    final requestUrl = Uri.parse("$baseUrl/save-estimates");

    if (!estimateData.containsKey("discount")) {
      estimateData["discount"] = 0.0;
    }
    if (!estimateData.containsKey("timestamp")) {
      estimateData["timestamp"] = DateTime.now().toIso8601String();
    }

    if (estimateData.containsKey("rows")) {
      List<Map<String, dynamic>> rows =
          List<Map<String, dynamic>>.from(estimateData["rows"]);
      for (var row in rows) {
        row.remove("estimateId"); // 🚀 Remove `estimateId`
      }
      estimateData["rows"] = rows;
    }

    print("🔥 Sending POST request to: $requestUrl");
    print("📝 Request Body (JSON Format): ${jsonEncode(estimateData)}");

    try {
      final response = await http.post(
        requestUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(estimateData),
      );

      print("📩 Response Status Code: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("❌ Error sending request: $e");
      return false;
    }
  }

  static Future<bool> updateEstimate(
      int id, Map<String, dynamic> estimateData) async {
    final response = await http.put(
      Uri.parse("$baseUrl/charcoal-estimates/$id"), // ✅ Fixed path
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteEstimate(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('"Token is missing. User is not authenticated."');
    }
    final response = await http.delete(
      Uri.parse("$baseUrl/charcoal-estimates/$id"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> fetchEstimateById(int estimateId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/charcoal-estimates/details/$estimateId"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load estimate data");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllCharcoalEstimates() async {
    try {
      // Retrieve the token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("Token is missing. Please log in.");
      }

      // Send GET request with token in the header
      final response = await http.get(
        Uri.parse("$baseUrl/charcoal-estimates"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Check for successful response
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception(
            "Failed to fetch charcoal estimates. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
      throw Exception("Failed to fetch charcoal estimates: $e");
    }
  }

  static Future<Map<String, dynamic>> fetchCharcoalEstimateById(
      int estimateId) async {
    try {
      // Retrieve the token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token =
          prefs.getString('token'); // Retrieve token from SharedPreferences

      if (token == null) {
        throw Exception("Token is missing. Please log in.");
      }

      // Send GET request with token in the header
      final response = await http.get(
        Uri.parse("$baseUrl/charcoal-estimates/$estimateId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Pass token in Authorization header
        },
      );

      // Check for successful response
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            "Failed to fetch charcoal estimate. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
      throw Exception("Failed to fetch charcoal estimate: $e");
    }
  }
}
