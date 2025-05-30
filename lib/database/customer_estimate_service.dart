import 'dart:convert';
import 'package:http/http.dart' as http;

class EstimateService {
  static const String baseUrl = "http://127.0.0.1:4000/api/customer";

  static Future<List<Map<String, dynamic>>> getAllEstimatesByCustomerId(
      int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/all-estimates/$customerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      print('❌ Failed to load estimates: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching all estimates: $e');
    }
    return [];
  }

  /// Fetch all estimates
  static Future<List<Map<String, dynamic>>> fetchAllEstimates() async {
    final response = await http.get(Uri.parse("$baseUrl/all-estimates"));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch estimates.");
    }
  }

  Future<List<Map<String, dynamic>>> fetchVersionEstimatesForCustomer(
      int customerId, String version) async {
    try {
      final uri = Uri.parse('$baseUrl/selected-estimate/$customerId');
      final response = await http.get(
        uri.replace(queryParameters: {'version': version}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('❌ Failed to load estimates: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching estimates: $e');
      return [];
    }
  }

  /// Fetch estimate details by ID
  static Future<Map<String, dynamic>> fetchEstimateDetails(
      int estimateId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/estimates/$estimateId/details"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch estimate details.");
    }
  }

  /// Fetch customer name by ID
  static Future<String> getCustomerNameByCustomerId(int customerId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/customers/$customerId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['customerName'];
    } else {
      throw Exception("Failed to fetch customer name.");
    }
  }

  /// Fetch estimate types for a specific customer
  static Future<List<String>> fetchEstimateTypesForCustomer(
      int customerId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/estimates/customer/$customerId/types"));

    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to fetch estimate types.");
    }
  }

  // ✅ Fetch all estimates for a specific customer
  static Future<List<Map<String, dynamic>>> fetchAllEstimatesForCustomer(
      int customerId) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/all-estimates/$customerId"));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ Error fetching estimates: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Exception in fetchAllEstimatesForCustomer: $e");
      return [];
    }
  }

  /// ✅ Get all estimates with details by customerId and estimateType
  static Future<List<Map<String, dynamic>>> getEstimatesByCustomerId(
      int customerId, String estimateType) async {
    try {
      final response = await http.get(
          // Uri.parse('$baseUrl/estimates/customer/$customerId/$estimateType'),
          Uri.parse('$baseUrl/all-estimates/$customerId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      print('❌ Failed to load estimates: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching estimates: $e');
    }
    return [];
  }

  /// ✅ Get estimate details by estimateId and estimateType
  static Future<List<Map<String, dynamic>>> getEstimatesByEstimateId(
      int estimateId, String estimateType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estimates/$estimateType/$estimateId/details'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      print('❌ Failed to load estimate details: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching estimate details: $e');
    }
    return [];
  }

  /// ✅ Fetch estimates by type and customerId
  static Future<List<Map<String, dynamic>>> fetchEstimatesByType(
      int customerId, String estimateType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estimates/type/$estimateType/customer/$customerId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      print('❌ Failed to load estimates by type: ${response.statusCode}');
    } catch (e) {
      print('❌ Error fetching estimates by type: $e');
    }
    return [];
  }

  /// ✅ Get granite estimate details by estimateId
  static Future<Map<String, dynamic>> getEstimateDetailsById(int id) async {
    final response =
        await http.get(Uri.parse("$baseUrl/estimates/granite/:estimateId/$id"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Estimate not found");
  }

  Future<Map<String, dynamic>> getEstimateData(int estimateId) async {
    // Simulate the fetching of estimate details from an API or local DB
    // You would replace this with an actual function call to your backend or local DB
    final response =
        await http.get(Uri.parse('$baseUrl/estimate-details/$estimateId'));
    if (response.statusCode == 200) {
      return jsonDecode(response
          .body); // Assuming response contains a JSON object with the details
    } else {
      throw Exception('Failed to fetch estimate details');
    }
  }

  static Future<Map<String, dynamic>?> fetchCustomerInfoById(
      int customerId) async {
    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:4000/api/customer-info/$customerId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']; // ✅ return just the customer info
        }
      }
      print("❌ Failed to fetch customer info: ${response.body}");
    } catch (e) {
      print("❌ Error fetching customer info: $e");
    }
    return null;
  }
}
