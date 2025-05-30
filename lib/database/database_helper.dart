import 'dart:convert';
import 'package:http/http.dart' as http;

class MaterialDatabase {
  static const String baseUrl =
      "http://127.0.0.1:4000/api/materials"; // Change to AWS IP

  // ✅ Fetch all materials
  static Future<List<dynamic>> getMaterials() async {
    final response = await http.get(Uri.parse("$baseUrl/materials"));
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("Failed to load materials");
  }

  // ✅ Add a new material
  static Future<bool> addMaterial(Map<String, dynamic> materialData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/materials"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(materialData),
    );
    return response.statusCode == 200;
  }

  // ✅ Update a material
  static Future<bool> updateMaterial(
      int id, Map<String, dynamic> materialData) async {
    final response = await http.put(
      Uri.parse("$baseUrl/all-material/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(materialData),
    );
    return response.statusCode == 200;
  }

  // ✅ Delete a material
  static Future<bool> deleteMaterial(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/materials/$id"));
    return response.statusCode == 200;
  }
}
