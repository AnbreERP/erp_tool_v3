import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GrassDatabaseHelper {
  static const String baseUrl = "http://127.0.0.1:4000/api"; // Change to AWS IP

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

  // ✅ Fetch all grass estimates
  static Future<List<Map<String, dynamic>>> getGrassEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse("$baseUrl/grass-estimates"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // ✅ Ensure the response is a list before casting
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            "Unexpected response format: Expected a list but got ${jsonData.runtimeType}");
      }
    } else {
      throw Exception("Failed to load grass estimates");
    }
  }

  // ✅ Fetch a single grass estimate by ID
  static Future<Map<String, dynamic>> getGrassEstimateById(int id) async {
    // Fetch main estimate data
    final response = await http.get(Uri.parse("$baseUrl/grass-estimates/$id"));

    if (response.statusCode == 200) {
      Map<String, dynamic> estimateData = jsonDecode(response.body);

      // Fetch rows (details) for the estimate
      List<Map<String, dynamic>> estimateRows =
          await fetchGrassEstimateDetails(id);

      // Combine the estimate data with the rows
      estimateData['rows'] = estimateRows;

      return estimateData;
    } else {
      throw Exception("Estimate not found");
    }
  }

  // ✅ Fetch grass estimate details by estimate ID
  static Future<List<Map<String, dynamic>>> fetchGrassEstimateDetails(
      int estimateId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/grass-estimates-details/$estimateId"));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // ✅ Case 1: If API returns a List, cast it directly
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      }

      // ✅ Case 2: If API returns a Map with a key containing the list, extract it
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('details')) {
        return (jsonData['details'] as List).cast<Map<String, dynamic>>();
      }

      // ✅ Case 3: If API returns a single Map, wrap it in a List
      if (jsonData is Map<String, dynamic>) {
        return [jsonData];
      }

      throw Exception(
          "Unexpected response format for estimate ID: $estimateId");
    } else {
      throw Exception("Failed to fetch estimate details for ID: $estimateId");
    }
  }

  // ✅ Add a new grass estimate
  static Future<bool> addGrassEstimate(
      Map<String, dynamic> estimateData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/grass-estimates"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );
    return response.statusCode == 200;
  }

  // ✅ Update grass estimate, creating a new version with the same estimateId
  static Future<bool> updateGrassEstimate(
      int id, Map<String, dynamic> estimateData) async {
    // Include the version and other details in the request; the server will increment the version and create a new record
    final response = await http.put(
      Uri.parse("$baseUrl/grass-estimates/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Failed to update estimate for ID: $id");
    }
  }

  // ✅ Delete grass estimate
  static Future<bool> deleteGrassEstimate(int id) async {
    final response =
        await http.delete(Uri.parse("$baseUrl/grass-estimates/$id"));
    return response.statusCode == 200;
  }

  // ✅ Fetch customer details by customerId
  static Future<Map<String, dynamic>> getCustomerById(int customerId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/customers/$customerId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch customer details for ID: $customerId");
    }
  }
}
