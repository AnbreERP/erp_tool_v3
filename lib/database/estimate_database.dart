import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/estimate/models/estimate_row.dart';
import '../modules/estimate/models/woodwork_estimate.dart';

class EstimateDatabase {
  static const String baseUrl =
      "http://127.0.0.1:4000/api"; // Change to your AWS VM IP

  static Future<List<WoodworkEstimate>> getEstimates() async {
    try {
      // Retrieve the token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      print('Retrieved Token: $token'); // Debugging step

      if (token == null) {
        throw Exception("Token is missing. Please log in.");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/woodwork-estimates"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Include the token in the Authorization header
        },
      );

      // Check the status code and response body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          List<WoodworkEstimate> estimates =
              (jsonResponse['data'] as List).map((estimateJson) {
            List<EstimateRow> rows = (estimateJson['rows'] as List)
                .map((row) => EstimateRow.fromMap(row))
                .toList();
            return WoodworkEstimate.fromJson(estimateJson, rows);
          }).toList();

          return estimates;
        } else {
          throw Exception("Failed to load estimates");
        }
      } else {
        throw Exception(
            "Error fetching estimates. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
      throw Exception("Failed to fetch estimates: $e");
    }
  }

  // Fetch an estimate by ID
  static Future<Map<String, dynamic>> getEstimate(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print("✅ Token saved: $token");

    if (token == null) {
      print("❌ Token not found in SharedPreferences");
      throw Exception("User not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/woodwork-estimates-edit/$id"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Backend error: ${response.body}");
      throw Exception("Failed to load estimate: ${response.statusCode}");
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<WoodworkEstimate> getEstimateById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token'); // Make sure this is saved at login

    final response = await http.get(
      Uri.parse('$baseUrl/woodwork-estimates/$id'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<dynamic> rowsJson = data['rows'];
      List<EstimateRow> rows =
          rowsJson.map((row) => EstimateRow.fromMap(row)).toList();

      var estimateData = data['estimate'];

      return WoodworkEstimate(
        id: _parseInt(estimateData['id']),
        customerId: _parseInt(estimateData['customerId']),
        customerName: estimateData['customerName']?.toString() ?? 'Unknown',
        customerEmail: estimateData['customerEmail']?.toString() ?? 'Unknown',
        customerPhone: estimateData['customerPhone']?.toString() ?? 'Unknown',
        totalAmount: _parseDouble(estimateData['totalAmount']),
        totalAmount2: _parseDouble(estimateData['totalAmount2']),
        totalAmount3: _parseDouble(estimateData['totalAmount3']),
        discount: _parseDouble(estimateData['discount']),
        transportCost: _parseDouble(estimateData['transportCost']),
        gstPercentage: _parseDouble(estimateData['gstPercentage']),
        estimateType: estimateData['estimateType']?.toString() ?? 'woodwork',
        version: estimateData['version']?.toString() ?? '1.1',
        userId: _parseInt(estimateData['userId']),
        status: estimateData['status'],
        stage: estimateData['stage'],
        rows: rows,
      );
    } else {
      throw Exception('Failed to load estimate');
    }
  }

  static Future<Map<String, dynamic>> getLatestVersion(
      int customerId, String estimateType) async {
    final response = await http.get(
      Uri.parse(
          "$baseUrl/woodwork-estimates/$customerId/latest-version?estimateType=$estimateType"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Expects { "version": "1.1" }
    } else {
      throw Exception("Failed to load latest version");
    }
  }

  // Create a new estimate
  static Future<bool> createEstimate(Map<String, dynamic> estimateData) async {
    // Retrieve the token from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Retrieve the token
    print("✅ Token saved: $token");
    // Check if token is null
    if (token == null) {
      throw Exception("Token is missing. Please log in.");
    }

    // Send the POST request with the token in the header
    final response = await http.post(
      Uri.parse("$baseUrl/woodwork-estimates"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // Add the token here
      },
      body: jsonEncode(estimateData),
    );

    // Return true if the status code is 200, otherwise return false
    return response.statusCode == 200;
  }

  // Update an estimate
  static Future<bool> updateEstimate(
      int id, Map<String, dynamic> estimateData) async {
    final response = await http.put(
      Uri.parse("$baseUrl/estimates/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );

    return response.statusCode == 200;
  }

  // Delete an estimate
  static Future<bool> deleteEstimate(int id) async {
    final response = await http
        .delete(Uri.parse("$baseUrl/woodwork/delete-estimate/:estimateId"));

    return response.statusCode == 200;
  }
}
