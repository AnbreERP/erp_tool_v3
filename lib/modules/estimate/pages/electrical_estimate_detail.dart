import 'package:flutter/material.dart';
import '../../../database/e_database_helper.dart';

class ElectricalEstimateDetailPage extends StatefulWidget {
  final int estimateId;

  const ElectricalEstimateDetailPage({super.key, required this.estimateId});

  @override
  _ElectricalEstimateDetailPageState createState() =>
      _ElectricalEstimateDetailPageState();
}

class _ElectricalEstimateDetailPageState
    extends State<ElectricalEstimateDetailPage> {
  bool _showBoqColumns =
      true; // This will control the visibility of the BOQ columns

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electrical Estimate Details'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon:
                Icon(_showBoqColumns ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showBoqColumns =
                    !_showBoqColumns; // Toggle BOQ column visibility
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: EDatabaseHelper.getEstimateById(
            widget.estimateId), // Fetch details for both estimate and rows
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found.'));
          } else {
            final estimate =
                snapshot.data!['estimate']; // Get main estimate data
            final rows = snapshot.data!['rows']; // Get rows data

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estimate Details:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal, // Horizontal scroll for the table
                    child: DataTable(
                      columns:
                          _buildColumns(), // Use a helper function to build the columns
                      rows: rows.map<DataRow>((row) {
                        return DataRow(
                            cells: _buildCells(
                                row)); // Use a helper function to build the cells
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Transport: ₹${estimate['transportCharges'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Grand Total: ₹${estimate['grandTotal'] ?? 'N/A'}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Delete Button
                  ElevatedButton(
                    onPressed: () => _deleteEstimate(context, estimate['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Delete Estimate',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Helper function to build columns with conditional BOQ columns
  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(label: Text('Floor')),
      const DataColumn(label: Text('Room')),
      const DataColumn(label: Text('Additional\nInfo')),
      const DataColumn(label: Text('Description')),
      const DataColumn(label: Text('Type')),
      const DataColumn(label: Text('Light Type')),
      const DataColumn(label: Text('Light Detail')),
      const DataColumn(label: Text('Quantity')),
      const DataColumn(label: Text('Material\nRate')),
      const DataColumn(label: Text('Labour\nRate')),
      const DataColumn(label: Text('Total\nAmount')),
      const DataColumn(label: Text('Net\nAmount')),
      if (_showBoqColumns) const DataColumn(label: Text('BOQ Material\nRate')),
      if (_showBoqColumns) const DataColumn(label: Text('BOQ Labour\nRate')),
      if (_showBoqColumns) const DataColumn(label: Text('BOQ Total\nAmount')),
    ];
  }

  // Helper function to build cells with conditional BOQ cells
  List<DataCell> _buildCells(Map<String, dynamic> row) {
    return [
      DataCell(Text('${row['floor'] ?? 'N/A'}')),
      DataCell(Text('${row['room'] ?? 'N/A'}')),
      DataCell(Text('${row['addInfo'] ?? 'N/A'}')),
      DataCell(Text('${row['description'] ?? 'N/A'}')),
      DataCell(Text('${row['type'] ?? 'N/A'}')),
      DataCell(Text('${row['lightType'] ?? 'N/A'}')),
      DataCell(Text('${row['lightName'] ?? 'N/A'}')),
      DataCell(Text('${row['quantity'] ?? 0}')),
      DataCell(Text('₹${row['materialRate'] ?? 0}')),
      DataCell(Text('₹${row['labourRate'] ?? 0}')),
      DataCell(Text('₹${row['totalAmount'] ?? 0}')),
      DataCell(Text('₹${row['netAmount'] ?? 0}')),
      if (_showBoqColumns) DataCell(Text('₹${row['boqMaterialRate'] ?? 0}')),
      if (_showBoqColumns) DataCell(Text('₹${row['boqLabourRate'] ?? 0}')),
      if (_showBoqColumns) DataCell(Text('₹${row['boqTotalAmount'] ?? 0}')),
    ];
  }

  // Function to delete the estimate
  Future<void> _deleteEstimate(BuildContext context, int estimateId) async {
    await EDatabaseHelper.deleteEstimate(
        estimateId); // Updated to wainscoting database
    Navigator.pop(context); // Close the current page after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estimate deleted successfully!')),
    );
  }
}
