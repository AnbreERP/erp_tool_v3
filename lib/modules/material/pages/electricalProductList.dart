import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../widgets/sidebar_menu.dart';
import 'electrical_Description.dart';

class ElectricalProductListPage extends StatefulWidget {
  const ElectricalProductListPage({super.key});

  @override
  _ElectricalProductListPageState createState() =>
      _ElectricalProductListPageState();
}

class _ElectricalProductListPageState extends State<ElectricalProductListPage> {
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // ✅ Fetch Data from Backend API
  Future<void> _loadAllData() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/api/e-estimate/all-data'),
      );

      print('API Response: ${response.body}'); // Debugging Log

      if (response.statusCode == 200) {
        final List<dynamic> allData = json.decode(response.body);

        setState(() {
          _allData = List<Map<String, dynamic>>.from(allData);
          _isLoading = false;
        });

        print('Parsed Data: $_allData'); // Debugging Log
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching all data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Electrical Material List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('Add Material', style: TextStyle(fontSize: 16)),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () {
              SidebarController.of(context)?.openPage(const DescriptionPage());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allData.isEmpty
              ? const Center(
                  child: Text(
                    'No data found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTable(),
                    ),
                  ),
                ),
    );
  }

  // ✅ Helper Function: Create Table Layout with Padding & Spacing
  Widget _buildTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: FixedColumnWidth(50), // Serial No.
            1: FixedColumnWidth(150), // Description
            2: FixedColumnWidth(200), // Type
            3: FixedColumnWidth(130), // Light Type
            4: FixedColumnWidth(300), // Light Name
            5: FixedColumnWidth(100), // Material Rate
            6: FixedColumnWidth(100), // Labour Rate
            7: FixedColumnWidth(130), // BOQ Material Rate
            8: FixedColumnWidth(130), // BOQ Labour Rate
          },
          border:
              TableBorder.all(color: Colors.black, style: BorderStyle.solid),
          children: [
            // ✅ Table Headers with Better Styling
            TableRow(
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(5),
              ),
              children: [
                _buildHeaderCell('Sr. No.'),
                _buildHeaderCell('Description'),
                _buildHeaderCell('Type'),
                _buildHeaderCell('Light Type'),
                _buildHeaderCell('Light Name'),
                _buildHeaderCell('Material Rate'),
                _buildHeaderCell('Labour Rate'),
                _buildHeaderCell('BOQ Material Rate'),
                _buildHeaderCell('BOQ Labour Rate'),
              ],
            ),
            // ✅ Table Data Rows with Alternating Colors
            ..._allData.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> row = entry.value;
              return _buildTableRow(index + 1, row, index);
            }),
          ],
        ),
      ],
    );
  }

  // ✅ Helper Function: Create Header Cell with Padding & Bold Text
  TableCell _buildHeaderCell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ✅ Helper Function: Create Table Row with Alternating Row Colors
  TableRow _buildTableRow(
      int serialNumber, Map<String, dynamic> row, int index) {
    return TableRow(
      decoration: BoxDecoration(
        color: index.isEven
            ? Colors.white
            : Colors.grey[100], // Alternating Row Colors
      ),
      children: [
        _buildTableCell('$serialNumber', true),
        _buildTableCell(row['description'] ?? 'N/A', false),
        _buildTableCell(row['type'] ?? 'N/A', false),
        _buildTableCell(row['lightType'] ?? 'N/A', false),
        _buildTableCell(row['lightName'] ?? 'N/A', false),
        _buildTableCell(row['materialRate']?.toString() ?? 'N/A', false),
        _buildTableCell(row['labourRate']?.toString() ?? 'N/A', false),
        _buildTableCell(row['boqMaterialRate']?.toString() ?? 'N/A', false),
        _buildTableCell(row['boqLabourRate']?.toString() ?? 'N/A', false),
      ],
    );
  }

  // ✅ Helper Function: Create Table Cell with Padding and Centered Text
  TableCell _buildTableCell(String text, bool isNumber) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isNumber ? Colors.black87 : Colors.black,
              fontWeight: isNumber ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
