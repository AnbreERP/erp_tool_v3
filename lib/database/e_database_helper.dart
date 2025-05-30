import 'dart:convert';
import 'package:http/http.dart' as http;

class EDatabaseHelper {
  static const String baseUrl = "http://127.0.0.1:4000/api/e-estimate";
  static const Map<String, String> headers = {
    "Content-Type": "application/json"
  };

  /*__________________________________________________________________________________*/
  // ✅ Common HTTP Request Functions

  static Future<dynamic> _get(String endpoint) async {
    try {
      final Uri url = Uri.parse("$baseUrl/$endpoint");
      print("📤 GET Request: $url");

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      print("❌ GET Request Failed: $endpoint, Error: $e");
      throw Exception("❌ Network error: $e");
    }
  }

  static Future<bool> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final Uri url = Uri.parse("$baseUrl/$endpoint");
      print("📤 POST Request: $url");
      print("📦 Request Body: ${jsonEncode(data)}");

      final response =
          await http.post(url, headers: headers, body: jsonEncode(data));
      return _handleResponseBoolean(response);
    } catch (e) {
      print("❌ POST Request Failed: $endpoint, Error: $e");
      throw Exception("❌ Network error: $e");
    }
  }

  static Future<bool> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final Uri url = Uri.parse("$baseUrl/$endpoint");
      print("📤 PUT Request: $url");
      print("📦 Request Body: ${jsonEncode(data)}");

      final response =
          await http.put(url, headers: headers, body: jsonEncode(data));
      return _handleResponseBoolean(response);
    } catch (e) {
      print("❌ PUT Request Failed: $endpoint, Error: $e");
      throw Exception("❌ Network error: $e");
    }
  }

  static Future<bool> _delete(String endpoint) async {
    try {
      final Uri url = Uri.parse("$baseUrl/$endpoint");
      print("📤 DELETE Request: $url");

      final response = await http.delete(url, headers: headers);
      return _handleResponseBoolean(response);
    } catch (e) {
      print("❌ DELETE Request Failed: $endpoint, Error: $e");
      throw Exception("❌ Network error: $e");
    }
  }

  static dynamic _handleResponse(http.Response response) {
    print("📥 Response Code: ${response.statusCode}");
    print("📜 Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return []; // ✅ Handle empty responses
      final data = jsonDecode(response.body);
      return data is List ? data : data ?? {}; // ✅ Always return valid object
    } else if (response.statusCode == 404) {
      print("⚠️ No data found for request: ${response.request?.url}");
      return []; // ✅ Prevent UI crashes
    } else {
      throw Exception(
          "⚠️ Request failed: ${response.statusCode}, Response: ${response.body}");
    }
  }

  static bool _handleResponseBoolean(http.Response response) {
    print("📥 Response Code: ${response.statusCode}");
    print("📜 Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return !(data is Map &&
          data.containsKey("error")); // ✅ Ensure response has no errors
    }
    return false;
  }

  /*__________________________________________________________________________________*/
  // ✅ Descriptions CRUD Operations

  static Future<List<Map<String, dynamic>>> getDescriptions() async {
    final response = await _get("descriptions");
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<bool> addDescription(
      Map<String, dynamic> descriptionData) async {
    return _post("descriptions", descriptionData);
  }

  static Future<bool> updateDescription(
      int id, Map<String, dynamic> descriptionData) async {
    return _put("descriptions/$id", descriptionData);
  }

  static Future<bool> deleteDescription(int id) async {
    return _delete("descriptions/$id");
  }

  /*__________________________________________________________________________________*/
  // ✅ Types CRUD Operations

  static Future<List<Map<String, dynamic>>> getTypes(int descriptionId) async {
    final response = await _get("types/$descriptionId");
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<bool> addType(Map<String, dynamic> typeData) async {
    return _post("types", typeData);
  }

  static Future<bool> updateType(int id, Map<String, dynamic> typeData) async {
    return _put("types/$id", typeData);
  }

  static Future<bool> deleteType(int id) async {
    return _delete("types/$id");
  }

  /*__________________________________________________________________________________*/
  // ✅ Light Types CRUD Operations

  static Future<List<Map<String, dynamic>>> getLightTypes(int typeId) async {
    final response = await _get("light-types/$typeId");
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<bool> addLightType(Map<String, dynamic> lightTypeData) async {
    return _post("light-types", lightTypeData);
  }

  static Future<bool> updateLightType(
      int id, Map<String, dynamic> lightTypeData) async {
    return _put("light-types/$id", lightTypeData);
  }

  static Future<bool> deleteLightType(int id) async {
    return _delete("light-types/$id");
  }

  /*__________________________________________________________________________________*/
  // ✅ Light Details CRUD Operations

  static Future<List<Map<String, dynamic>>> getLightDetails(
      int lightTypeId) async {
    final response = await _get("light-details/$lightTypeId");
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  static Future<bool> addLightDetails(
      Map<String, dynamic> lightDetailsData) async {
    return _post("light-details", lightDetailsData);
  }

  static Future<bool> updateLightDetails(
      int id, Map<String, dynamic> lightDetailsData) async {
    return _put("light-details/$id", lightDetailsData);
  }

  static Future<bool> deleteLightDetails(int id) async {
    return _delete("light-details/$id");
  }

  /*__________________________________________________________________________________*/
  // ✅ Estimates CRUD Operations

  static Future<List<Map<String, dynamic>>> getEstimates() async {
    final response = await _get("estimates");

    if (response is Map && response.containsKey("estimates")) {
      return List<Map<String, dynamic>>.from(
          response["estimates"]); // ✅ Extract estimates list
    }

    return [];
  }

  static Future<Map<String, dynamic>> getEstimateById(int id) async {
    final response = await _get("estimates/$id");
    return response ?? {}; // ✅ Ensure response is an object
  }

  static Future<bool> addEstimate(Map<String, dynamic> estimateData) async {
    final response = await _post("estimates", estimateData);
    return response;
  }

  static Future<bool> updateEstimate(
      int id, Map<String, dynamic> estimateData) async {
    final response = await _put("estimates/$id", estimateData);
    return response;
  }

  static Future<bool> deleteEstimate(int id) async {
    return _delete("estimates/$id");
  }

  /*----------------------------------------------------------------------------------------*/
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
