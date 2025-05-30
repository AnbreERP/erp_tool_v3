import 'package:flutter/material.dart';
import '../../estimate/pages/Quartz_Slab_Page.dart';
import '../../estimate/pages/charcoal_estimate.dart';
import '../../estimate/pages/electrical_estimate_page.dart';
import '../../estimate/pages/estimate_list_page.dart';
import '../../estimate/pages/false_ceiling_estimate_page.dart';
import '../../estimate/pages/granite_stone_estimate.dart';
import '../../estimate/pages/new_woodwork_estimate_page.dart';
import '../../estimate/pages/wallpaper.dart';
import '../../estimate/pages/weinscoating_estimate.dart';

class CustomerDetailPage extends StatelessWidget {
  final Map<String, dynamic> customer;
  const CustomerDetailPage({super.key, required this.customer});

  // Method to navigate to different estimate pages
  void _navigateToEstimatePage(BuildContext context, String estimateType) {
    Widget page;
    switch (estimateType) {
      case 'Woodwork':
        page = NewWoodworkEstimatePage(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
        );
        break;
      case 'Electrical':
        page = ElectricalEstimatePage(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
        );
        break;
      case 'False Ceiling':
        page = FalseCeilingEstimatePage(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
        );
        break;
      case 'Quartz':
        page = QuartzSlabPage(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
          estimateData: const {},
        );
        break;
      case 'Granite':
        page = GraniteStoneEstimate(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
          estimateData: const {},
        );
        break;
      case 'Wallpaper':
        page = Wallpaper(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
          estimateData: const {},
        );
        break;
      case 'Weinscoating':
        page = WeinscoatingEstimatePage(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
        );
        break;
      case 'Charcoal':
        page = CharcoalEstimate(
          customerId: customer['id'],
          customerName: customer['name'],
          customerEmail: customer['email'],
          customerPhone: customer['phone'],
          estimateData: const {},
        );
        break;
      default:
        page = EstimateListPage(customerId: customer['id']);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          customer['name'],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Details Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Customer Details Header
                    const Text(
                      "Customer Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ Customer Info Row
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow("Name", customer['name'])),
                        Expanded(child: _buildDetailRow("Email", customer['email'])),
                        Expanded(child: _buildDetailRow("Phone", customer['phone'])),
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      "Address Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // ✅ Address Row
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow("Street", customer['street'])),
                        Expanded(child: _buildDetailRow("City", customer['city'])),
                        Expanded(child: _buildDetailRow("Postal Code", customer['postalCode'])),
                      ],
                    ),

                    const SizedBox(height: 15),
                    const Text(
                      "Site Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // ✅ Site Details Row
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow("Site Street", customer['siteStreet'])),
                        Expanded(child: _buildDetailRow("Site City", customer['siteCity'])),
                        Expanded(child: _buildDetailRow("Site Postal Code", customer['sitePostalCode'])),
                      ],
                    ),

                    const SizedBox(height: 15),
                    const Text(
                      "Project Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // ✅ Project Details Row
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow("Project Name", customer['projectName'])),
                        Expanded(child: _buildDetailRow("Project Type", customer['projectType'])),
                        Expanded(child: _buildDetailRow("Type", customer['type'])),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Estimates Section
            const Text("Create Estimate",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                )),
            const SizedBox(height: 10),

            // Estimates Grid (Separate Buttons for Each)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildEstimateButton(context, "Woodwork"),
                _buildEstimateButton(context, "Electrical"),
                _buildEstimateButton(context, "False Ceiling"),
                _buildEstimateButton(context, "Quartz"),
                _buildEstimateButton(context, "Granite"),
                _buildEstimateButton(context, "Wallpaper"),
                _buildEstimateButton(context, "Weinscoating"),
                _buildEstimateButton(context, "Charcoal"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Customer detail row (Key-Value Pair)
  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value != null ? value.toString() : "N/A", // ✅ Handle null values
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Estimate Button Widget
  Widget _buildEstimateButton(BuildContext context, String estimateType) {
    return ElevatedButton(
      onPressed: () => _navigateToEstimatePage(context, estimateType),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        estimateType,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }
}
