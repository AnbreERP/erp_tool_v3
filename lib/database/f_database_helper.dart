import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FDatabaseHelper {
  static const String baseUrl = "http://127.0.0.1:4000/api/false-ceiling";

  // ✅ Fetch all False Ceiling estimates
  static Future<List<Map<String, dynamic>>> getFalseCeilingEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      print('token is null');
    }
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/false-ceiling-estimates"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("📩 Response Code: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      return _handleResponseList(response);
    } catch (e) {
      print("❌ Error fetching estimates: $e");
      throw Exception("Failed to fetch estimates. Error: $e");
    }
  }

  // ✅ Add a new False Ceiling estimate
  static Future<bool> addFalseCeilingEstimate(
      Map<String, dynamic> estimateData) async {
    final response = await _postRequest("$baseUrl/estimates", estimateData);
    return response.statusCode == 201;
  }

  // ✅ Fetch a single False Ceiling estimate by ID
  static Future<Map<String, dynamic>> getFalseCeilingEstimateById(
      int id) async {
    final url = Uri.parse(
        "$baseUrl/false-ceiling-estimates/$id/details"); // ✅ Corrected

    print("📡 Sending GET request to: $url"); // ✅ Debugging Log

    final response = await http.get(url);

    print("📩 Response Code: ${response.statusCode}");
    print("📨 Response Body: ${response.body}");

    return _handleResponseMap(response);
  }

  // ✅ Fetch False Ceiling Estimate Details (Main + Rows)
  static Future<Map<String, dynamic>> fetchEstimateDetails(
      int estimateId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/estimates/$estimateId/details"));
    return _handleResponseMap(response);
  }

  // ✅ Fetch all False Ceiling Estimate Rows for a given Estimate ID
  static Future<List<Map<String, dynamic>>> getFalseCeilingEstimateRows(
      int estimateId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/estimates/$estimateId/rows"));
    return _handleResponseList(response);
  }

  // ✅ Update an existing False Ceiling estimate
  static Future<bool> updateFalseCeilingEstimate(
      int id, Map<String, dynamic> estimateData) async {
    final response = await _putRequest("$baseUrl/estimates/$id", estimateData);
    return response.statusCode == 200;
  }

  // ✅ Delete a False Ceiling estimate
  static Future<bool> deleteFalseCeilingEstimate(int id) async {
    try {
      // Retrieve the token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("Token is missing. User is not authenticated.");
      }

      // Make the DELETE request with the token in the Authorization header
      final response = await http.delete(
        Uri.parse("$baseUrl/false-ceiling-estimates/$id"),
        headers: {
          'Authorization': 'Bearer $token', // Pass the token here
        },
      );

      // Check if the request was successful (status code 200)
      return response.statusCode == 200;
    } catch (e) {
      // Handle errors (e.g., network issues, token issues)
      print("Error deleting estimate: $e");
      return false;
    }
  }

  // ✅ Save a new False Ceiling estimate
  static Future<int> saveEstimate(Map<String, dynamic> estimateData) async {
    String requestUrl = "$baseUrl/save-full-estimate";

    print("🔥 Debug: Sending request to $requestUrl");
    print("📝 Estimate Data: ${jsonEncode(estimateData)}");

    try {
      // Retrieve the token from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception("Token is missing. User is not authenticated.");
      }

      // Send POST request to backend with the token in the Authorization header
      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Include token here
        },
        body: jsonEncode(estimateData),
      );

      print("📩 Response Code: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      // Check if the response status code is 201 (Created)
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Ensure the response contains the 'estimateId' key
        if (data.containsKey('estimateId')) {
          return data['estimateId'];
        } else {
          throw Exception(
              "Failed to save estimate: Missing 'estimateId' in response.");
        }
      } else {
        // Handle non-201 responses
        throw Exception(
            "Failed to save estimate. Server responded with status: ${response.statusCode}");
      }
    } catch (e) {
      // Handle network or other errors
      print("❌ Error during request: $e");
      throw Exception("Error saving estimate: $e");
    }
  }

  // ✅ Save multiple False Ceiling estimate rows
  static Future<bool> saveEstimateRows(
      List<Map<String, dynamic>> estimateRows) async {
    final response =
        await _postRequest("$baseUrl/estimate-rows", {"details": estimateRows});
    return response.statusCode == 201;
  }

  // ✅ Common method to handle GET request responses (List)
  static List<Map<String, dynamic>> _handleResponseList(
      http.Response response) {
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch data: ${response.statusCode}");
    }
  }

  // ✅ Common method to handle GET request responses (Map)
  static Map<String, dynamic> _handleResponseMap(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch data: ${response.statusCode}");
    }
  }

  // ✅ Common method to handle POST requests
  static Future<http.Response> _postRequest(
      String url, Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }

  // ✅ Common method to handle PUT requests
  static Future<http.Response> _putRequest(
      String url, Map<String, dynamic> data) async {
    return await http.put(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
  }

  // ✅ Extract ID from response

  static Future<Map<String, dynamic>?> fetchCustomerById(int customerId) async {
    const String apiUrl = 'http://127.0.0.1:4000/api/customers';

    try {
      final response = await http.get(Uri.parse("$apiUrl/$customerId"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        print('❌ Error: Customer not found.');
        return null;
      } else {
        print('❌ Error fetching customer: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return null;
    }
  }
}
