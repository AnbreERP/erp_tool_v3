import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  static const String baseUrl = "http://127.0.0.1:4000"; // Change this!

  // Fetch all customers from MySQL
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/customers"));

      if (response.statusCode == 200) {
        List<dynamic> customers = json.decode(response.body);
        return customers
            .map((customer) => customer as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
            "Failed to fetch customers. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching customers: $e");
    }
  }

  // Add a new customer to MySQL
  Future<void> addCustomer(String name, String phone, String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/add-customers"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"name": name, "phone": phone, "email": email}),
      );

      if (response.statusCode == 201) {
        print("Customer added successfully!");
      } else {
        throw Exception("Failed to add customer: ${response.body}");
      }
    } catch (e) {
      print("Error adding customer: $e");
    }
  }

  // Update a customer in MySQL
  Future<void> updateCustomer(
      int id, String name, String phone, String email) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/customers/$id"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"name": name, "phone": phone, "email": email}),
      );

      if (response.statusCode == 200) {
        print("Customer updated successfully!");
      } else {
        throw Exception("Failed to update customer: ${response.body}");
      }
    } catch (e) {
      print("Error updating customer: $e");
    }
  }

  // Delete a customer from MySQL
  Future<void> deleteCustomer(int id) async {
    try {
      final response =
          await http.delete(Uri.parse("$baseUrl/api/customers/$id"));

      if (response.statusCode == 200) {
        print("✅ Customer deleted successfully!");
      } else {
        throw Exception("Failed to delete customer: ${response.body}");
      }
    } catch (e) {
      print("Error deleting customer: $e");
    }
  }

  // Fetch all estimates from MySQL
  Future<List<Map<String, dynamic>>> fetchEstimates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('"Token is missing. User is not authenticated."');
    }
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/estimates"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> estimates = json.decode(response.body);
        return estimates
            .map((estimate) => estimate as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
            "Failed to fetch estimates. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching estimates: $e");
    }
  }

  // Add a new estimate to MySQL
  Future<void> addEstimate(
      int customerId, String estimateType, double amount) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/add-estimate"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "customer_id": customerId,
          "estimate_type": estimateType,
          "amount": amount
        }),
      );

      if (response.statusCode == 201) {
        print("Estimate added successfully!");
      } else {
        throw Exception("Failed to add estimate: ${response.body}");
      }
    } catch (e) {
      print("Error adding estimate: $e");
    }
  }

  // Delete an estimate from MySQL
  Future<void> deleteEstimate(int id) async {
    try {
      final response =
          await http.delete(Uri.parse("$baseUrl/api/estimates/$id"));

      if (response.statusCode == 200) {
        print("Estimate deleted successfully!");
      } else {
        throw Exception("Failed to delete estimate: ${response.body}");
      }
    } catch (e) {
      print("Error deleting estimate: $e");
    }
  }
}
