import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WDatabaseHelper {
  static const String baseUrl =
      "http://127.0.0.1:4000/api/wallpaper"; // Change to AWS IP

  // ✅ Fetch latest estimate for a customer
  static Future<Map<String, dynamic>> fetchLatestEstimate(
      int customerId) async {
    final response = await http.get(Uri.parse("$baseUrl/latest/$customerId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to fetch latest estimate for customer $customerId");
    }
  }

  // ✅ Fetch all estimates for a customer
  static Future<List<dynamic>> fetchEstimateVersions(int customerId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/estimates/$customerId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch estimates for customer $customerId");
    }
  }

  // ✅ Fetch all wallpaper estimates
  static Future<List<Map<String, dynamic>>> getWallpaperEstimates() async {
    // Retrieve the token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      throw Exception("Token is missing. User is not authenticated.");
    }
    print(token);
    // Add the token to the headers
    final response = await http.get(
      Uri.parse("$baseUrl/wallpaper-estimates"),
      headers: {
        "Authorization": "Bearer $token", // Attach the token here
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // Ensure the response is a list before casting
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            "Unexpected response format: Expected a list but got ${jsonData.runtimeType}");
      }
    } else {
      throw Exception("Failed to load wallpaper estimates");
    }
  }

  // Fetch wallpaper estimate including details
  static Future<Map<String, dynamic>> getWallpaperEstimateById(int id) async {
    // Get the token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Ensure token is stored correctly
    print("Token retrieved from SharedPreferences: $token");
    if (token == null) {
      throw Exception("Token is missing");
    }

    // Make the request with the token included in the headers
    final response = await http.get(
      Uri.parse("$baseUrl/wallpaper-estimates/$id"),
      headers: {
        'Authorization': 'Bearer $token', // Add the token here
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception("Estimate not found.");
    } else {
      throw Exception(
          "Failed to fetch estimate. Status: ${response.statusCode}");
    }
  }

  // ✅ Fetch wallpaper estimate details by estimate ID
  static Future<Map<String, dynamic>> fetchWallpaperEstimateDetails(
      int estimateId) async {
    // Get the token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Ensure token is stored correctly
    print("Token retrieved from SharedPreferences: $token");

    if (token == null) {
      throw Exception("Token is missing");
    }

    // Make the request with the token included in the headers
    final response = await http.get(
      Uri.parse("$baseUrl/wallpaper-estimates/$estimateId"),
      headers: {
        'Authorization': 'Bearer $token', // Add the token here
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // Check if the response contains the required keys
      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('estimate') &&
          jsonData.containsKey('rows')) {
        return jsonData;
      } else {
        throw Exception("Invalid response format from API.");
      }
    } else if (response.statusCode == 404) {
      throw Exception("Estimate not found for ID: $estimateId");
    } else {
      throw Exception(
          "Failed to fetch estimate details. Status code: ${response.statusCode}");
    }
  }

  // ✅ Add a new wallpaper estimate
  static Future<bool> addWallpaperEstimate(
      Map<String, dynamic> estimateData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/wallpaper-estimates"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );
    return response.statusCode == 200;
  }

  // ✅ Update wallpaper estimate
  static Future<bool> updateWallpaperEstimate(
      int id, Map<String, dynamic> estimateData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Ensure token is stored correctly

    if (token == null) {
      throw Exception("Token is missing");
    }
    final response = await http.put(
      Uri.parse("$baseUrl/wallpaper-estimates/$id"),
      headers: {
        'Authorization': 'Bearer $token', // Add the token here
        'Content-Type': 'application/json'
      },
      body: jsonEncode(estimateData),
    );
    return response.statusCode == 200;
  }

  // ✅ Delete wallpaper estimate
  static Future<bool> deleteWallpaperEstimate(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Ensure token is stored correctly
    print("Token retrieved from SharedPreferences: $token");

    if (token == null) {
      throw Exception("Token is missing");
    }
    final response = await http.delete(
      Uri.parse("$baseUrl/wallpaper-estimates/$id"),
      headers: {
        'Authorization': 'Bearer $token', // Add the token here
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  // ✅ Fetch estimate details (rows) for a specific estimate ID
  static Future<List<Map<String, dynamic>>> fetchEstimateDetails(
      int estimateId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token =
        prefs.getString('token'); // Ensure token is stored correctly
    print("Token retrieved from SharedPreferences: $token");

    if (token == null) {
      throw Exception("Token is missing");
    }
    final response = await http.get(
      Uri.parse("$baseUrl/estimate-details/$estimateId"),
      headers: {
        'Authorization': 'Bearer $token', // Add the token here
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
          "Failed to fetch estimate details for estimate ID: $estimateId");
    }
  }
}
