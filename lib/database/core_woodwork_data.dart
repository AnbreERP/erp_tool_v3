import 'dart:convert';
import 'package:http/http.dart' as http;

class CoreWoodworkDatabase {
  static const String baseUrl =
      "http://127.0.0.1:4000/api/core-woodwork"; // Change to AWS IP

  // ✅ Fetch all wooden items
  static Future<List<dynamic>> getWoodenItems() async {
    final response = await http.get(Uri.parse("$baseUrl/wooden-items"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Failed to load wooden items");
  }

  // ✅ Add a new wooden item
  static Future<bool> addWoodenItem(Map<String, dynamic> itemData) async {
    try {
      // Debug: Print the request data
      print("📤 Sending request with data: ${jsonEncode(itemData)}");

      final response = await http.post(
        Uri.parse("$baseUrl/save-parts"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(itemData),
      );

      // Debug: Print the response status and body
      print("📩 Response Status: ${response.statusCode}");
      print("📨 Response Body: ${response.body}");

      // Check if the response is successful (200 OK)
      return response.statusCode == 200;
    } catch (e) {
      // Debug: Catch and print any error that occurs
      print("❌ Error sending data: $e");
      return false;
    }
  }

  // ✅ Delete a wooden item
  static Future<bool> deleteWoodenItem(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/wooden-items/$id"));
    return response.statusCode == 200;
  }

  // ✅ Fetch all woodwork finishes
  static Future<List<dynamic>> getWoodworkFinishes() async {
    final response = await http.get(Uri.parse("$baseUrl/woodwork-finishes"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Failed to load finishes");
  }

  // ✅ Fetch wooden item parts with finishes
  static Future<List<dynamic>> getItemPartsWithFinish(int woodenItemId) async {
    final response =
        await http.get(Uri.parse("$baseUrl/wooden-item-parts/$woodenItemId"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Failed to load item parts");
  }

// ✅ Fetch wooden item by ID
  static Future<Map<String, dynamic>> getWoodenItemById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/wooden-items/$id"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception("Wooden item not found");
    } else {
      throw Exception("Failed to load wooden item");
    }
  }
}
