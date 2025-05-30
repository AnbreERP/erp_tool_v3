import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerDatabaseService {
  static final CustomerDatabaseService instance =
      CustomerDatabaseService._internal();

  factory CustomerDatabaseService() => instance;

  CustomerDatabaseService._internal();

  // Set AWS Public IP + Node.js API Port
  static const String baseUrl = "http://127.0.0.1:4000";

  // Fetch all customers
  Future<Map<String, dynamic>> fetchCustomers(
      {int page = 1, int perPage = 10}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/api/customers?page=$page&limit=$perPage"));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (jsonData.containsKey('customers') &&
            jsonData.containsKey('totalCustomers')) {
          return {
            'customers': List<Map<String, dynamic>>.from(jsonData['customers']),
            'totalCustomers': jsonData['totalCustomers'],
          };
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        throw Exception("Failed to fetch customers: ${response.reasonPhrase}");
      }
    } catch (e) {
      throw Exception("Error fetching customers: $e");
    }
  }

  // Add a new customer
  Future<bool> addCustomer(Map<String, dynamic> customer) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customer),
      );

      if (response.statusCode == 201) {
        print("✅ Customer added successfully!");
        return true;
      } else {
        print("❌ Error adding customer: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
      return false;
    }
  }

  // 🔹 Update customer details
  Future<bool> updateCustomer(int id, Map<String, dynamic> customer) async {
    final String apiUrl = '$baseUrl/api/customers/$id';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(customer),
      );

      if (response.statusCode == 200) {
        print("✅ Customer updated successfully!");
        return true;
      } else {
        print("❌ Error updating customer: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
      return false;
    }
  }

  // 🔹 Delete a customer
  Future<void> deleteCustomer(int id) async {
    final String apiUrl = '$baseUrl/api/customers/$id';

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print("✅ Customer deleted successfully!");
      } else {
        print("❌ Error deleting customer: ${response.body}");
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
    }
  }

  // 🔹 Get customer details by ID
  Future<Map<String, dynamic>?> fetchCustomerById(int customerId) async {
    final String apiUrl = '$baseUrl/api/customers/$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty ? data : null;
      } else if (response.statusCode == 404) {
        print("❌ Customer not found.");
        return null;
      } else {
        print("❌ Error fetching customer: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Exception occurred: $e");
      return null;
    }
  }

  // 🔹 Get estimates for a specific customer
  Future<List<Map<String, dynamic>>> getEstimatesByCustomerId(
      int customerId) async {
    final String apiUrl = '$baseUrl/api/customers/$customerId/estimates';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .map((estimate) => estimate as Map<String, dynamic>)
            .toList();
      } else {
        print('❌ Error fetching estimates: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return [];
    }
  }

  // 🔹 Fetch multiple customers by ID
  Future<List<Map<String, dynamic>>> getCustomersByIds(
      List<int> customerIds) async {
    if (customerIds.isEmpty) return [];

    const String apiUrl = '$baseUrl/api/customers/by-ids';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'customerIds': customerIds}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .map((customer) => customer as Map<String, dynamic>)
            .toList();
      } else {
        print('❌ Error fetching customers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return [];
    }
  }

  // 🔹 Get only customer name by ID
  Future<String?> getCustomerNameById(int customerId) async {
    final String apiUrl = '$baseUrl/api/customers/$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['name'];
      } else {
        print('❌ Error fetching customer: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return null;
    }
  }

  // 🔹 Fetch all customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    const String apiUrl = '$baseUrl/api/customers';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data
            .map((customer) => customer as Map<String, dynamic>)
            .toList();
      } else {
        print('❌ Error fetching customers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return [];
    }
  }

  Future<Map<String, String>?> getCustomerInfoById(int customerId) async {
    final String apiUrl = '$baseUrl/api/customers/$customerId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? 'Unknown',
          'phone': data['phone'] ?? 'Unknown',
        };
      } else if (response.statusCode == 404) {
        print('❌ Error: Customer not found.');
        return null;
      } else {
        print('❌ Error fetching customer info: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception occurred: $e');
      return null;
    }
  }
}
