import 'dart:convert';
import 'package:http/http.dart' as http;

class FlooringEstimateDatabaseHelper {
  static const String baseUrl =
      "http://127.0.0.1:4000/api"; // Replace with production URL

  // ✅ Fetch the latest version for a customer
  static Future<Map<String, dynamic>> fetchLatestEstimate(
      int customerId) async {
    final response = await http.get(Uri.parse("$baseUrl/latest/$customerId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Failed to fetch latest flooring estimate for customer $customerId");
    }
  }

  // ✅ Fetch all flooring estimates (optional filtering by flooring type)
  static Future<List<Map<String, dynamic>>> getFlooringEstimates(
      {String? type}) async {
    final uri = (type != null)
        ? Uri.parse("$baseUrl/flooring-estimates?type=$type")
        : Uri.parse("$baseUrl/flooring-estimates");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            "Unexpected response format: Expected a list but got ${jsonData.runtimeType}");
      }
    } else {
      throw Exception("Failed to load flooring estimates");
    }
  }

  // ✅ Modified: Fetch a single flooring estimate (summary + rows) by estimateId and flooringType
  static Future<Map<String, dynamic>> getFlooringEstimateById(
      int estimateId, String flooringType) async {
    final response = await http.get(
        Uri.parse("$baseUrl/flooring-estimates/$flooringType/$estimateId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // contains summary and rows
    } else if (response.statusCode == 404) {
      throw Exception(
          "Flooring estimate not found for ID: $estimateId and type: $flooringType");
    } else {
      throw Exception(
          "Failed to fetch flooring estimate (status ${response.statusCode})");
    }
  }

  // ✅ Add a new flooring estimate (summary + rows together)
  static Future<int?> addFlooringEstimate(
      Map<String, dynamic> estimateData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/flooring-estimates"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    }
    return null;
  }

  // ✅ Update a flooring estimate (summary + rows together)
  static Future<bool> updateFlooringEstimate(
      int id, Map<String, dynamic> estimateData) async {
    final response = await http.put(
      Uri.parse("$baseUrl/flooring-estimates/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(estimateData),
    );
    return response.statusCode == 200;
  }

  // ✅ Delete a flooring estimate (summary + rows)
  static Future<bool> deleteFlooringEstimate(int id) async {
    final response =
        await http.delete(Uri.parse("$baseUrl/flooring-estimates/$id"));
    return response.statusCode == 200;
  }

  // ✅ Fetch customer details
  static Future<Map<String, dynamic>> getCustomerById(int customerId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/customers/$customerId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch customer details for ID: $customerId");
    }
  }

  // ✅ Fetch all flooring estimates for a customer
  static Future<List<Map<String, dynamic>>> getFlooringEstimatesByCustomer(
      int customerId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/flooring-estimates/customer/$customerId"));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            "Unexpected response format: Expected a list but got ${jsonData.runtimeType}");
      }
    } else {
      throw Exception(
          "Failed to load flooring estimates for customer ID $customerId");
    }
  }
}
