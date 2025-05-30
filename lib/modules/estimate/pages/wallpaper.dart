import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../database/w_database_helper.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../modules/estimate/pages/WallpaperEstimateListPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';

class EstimateWRows {
  String type;
  String room;
  String status;
  String stage;
  int? amount;
  int? quantity;
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  bool includePrimer = false;

  EstimateWRows(
      {required this.type,
      this.room = 'Bed Room',
      required this.stage,
      required this.status});
}

class Wallpaper extends StatefulWidget {
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic> estimateData;

  const Wallpaper({
    super.key,
    required this.customerId,
    this.estimateId,
    this.customerInfo,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.estimateData,
  });

  @override
  _WallpaperState createState() => _WallpaperState();
}

class _WallpaperState extends State<Wallpaper> {
  static const double mmToFeet = 304.8;

  final List<EstimateWRows> _estimateRows = [
    EstimateWRows(type: 'Bed Room', stage: '', status: '')
  ];
  final List<List<double>> _measurements = [
    [0.0, 0.0]
  ];
  final List<List<double>> _areasAndAmounts = [
    [0.0, 0.0, 0.0]
  ];
  final List<bool> _columnVisibility = List<bool>.generate(13, (_) => true);

  double _gstamount = 0.0;
  double _grandTotal = 0.0;

  final TextEditingController gstController = TextEditingController();
  final TextEditingController transportController = TextEditingController();
  final TextEditingController labourController = TextEditingController();
  final TextEditingController primerController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  // Add a variable to hold the list of customers and selected customer
  bool _showExtras = false;
  static const double _gstPercentage = 18;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = true;

  // Method to fetch customers from the database
  void _fetchCustomers() async {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _checkAndLoadDraft();
    // if (widget.estimateId != null) {
    //   _loadEstimateData(widget.estimateId!);
    // } // Fetch customers when the page loads
    if (widget.estimateData.isNotEmpty) {
      _loadEstimateFromData(
          widget.estimateData); // Load directly from passed data
    } else if (widget.estimateId != null) {
      _loadEstimateData(widget.estimateId!); // Fallback to fetch from API
    }
    fetchNotifications().then((notifs) {
      setState(() {
        _notifications = notifs;
        _isLoadingNotifications = false;
      });
    });
  }

  //auto save
  Future<void> _saveDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final draftRows = _estimateRows
        .map((row) => {
              'room': row.room,
              'description': row.descriptionController.text,
              'length': row.lengthController.text,
              'height': row.heightController.text,
              'rate': row.rateController.text,
              'quantity': row.quantityController.text,
              'primerIncluded': row.includePrimer,
            })
        .toList();

    final draftData = {
      'rows': draftRows,
      'labour': labourController.text,
      'transport': transportController.text,
      'discount': discountController.text,
    };

    await prefs.setString('wallpaper_draft', jsonEncode(draftData));
    debugPrint("✅ Draft saved locally");
  }

  Future<void> _checkAndLoadDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('wallpaper_draft');
    debugPrint(" Loaded raw draft JSON: $raw");

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['rows'] is List) {
        _showRestoreDialog(decoded['rows']); // pass only the list of rows
      } else {
        debugPrint(" Draft is not valid or doesn't contain rows list.");
      }
    }
  }

  void _showRestoreDialog(List<dynamic> draftRows) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Restore Draft?"),
          content:
              const Text("We found a saved draft. Do you want to restore it?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                debugPrint("User declined to restore draft.");
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadDraftEstimate(draftRows);
              },
              child: const Text("Yes, Restore"),
            ),
          ],
        );
      },
    );
  }

  void _loadDraftEstimate(List<dynamic> draftRows) {
    setState(() {
      _estimateRows.clear();
      _measurements.clear();
      _areasAndAmounts.clear();

      for (var row in draftRows) {
        final newRow = EstimateWRows(
          type: row['room'] ?? 'Unknown',
          room: row['room'] ?? 'Unknown',
          stage: '',
          status: '',
        );
        newRow.descriptionController.text = row['description'] ?? '';
        newRow.lengthController.text = row['length'] ?? '';
        newRow.heightController.text = row['height'] ?? '';
        newRow.rateController.text = row['rate'] ?? '';
        newRow.quantityController.text = row['quantity'] ?? '';
        newRow.includePrimer = row['primerIncluded'] == true;
        _estimateRows.add(newRow);
        _measurements.add([0, 0]);
        _areasAndAmounts.add([0, 0, 0]);
      }

      for (int i = 0; i < _estimateRows.length; i++) {
        _calculateEstimate(i);
      }

      _calculateGrandTotal();
    });
  }

  Future<void> clearDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('wallpaper_draft');
    debugPrint(" Draft cleared");
  }

  //end

  //notification
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');
    print(" Fetching notifications for user $userId");

    final response = await http.get(
      Uri.parse("http://127.0.0.1:4000/api/notifications?user_id=$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    print(" Notification response: ${response.body}");

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Widget _buildNotificationBell(List<Map<String, dynamic>> notifications) {
    int unreadCount = notifications.where((n) => n['seen'] != 1).length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            _showNotificationsPopup(context, notifications);
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: Colors.red,
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsPopup(
      BuildContext context, List<Map<String, dynamic>> notifications) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade50,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🔔 Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (notifications.any((n) => n['seen'] != 1))
                TextButton(
                  onPressed: () async {
                    await markAllNotificationsAsRead();
                    Navigator.pop(context);
                    final updated = await fetchNotifications();
                    setState(() => _notifications = updated);
                  },
                  child: const Text("Mark All as Read",
                      style: TextStyle(fontSize: 12)),
                ),
              TextButton.icon(
                onPressed: () async {
                  await clearAllNotifications();
                  Navigator.pop(context);
                  final updated = await fetchNotifications();
                  setState(() => _notifications = updated);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Clear All'),
              )
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: notifications.isEmpty
                ? const Center(child: Text("You're all caught up 🎉"))
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final isUnread = notif['seen'] != 1;

                      return ListTile(
                        tileColor: isUnread ? Colors.orange.shade50 : null,
                        title: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif['message'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(notif['created_at']),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isUnread)
                              const Icon(Icons.circle,
                                  size: 10, color: Colors.red),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent, size: 20),
                              tooltip: 'Delete',
                              onPressed: () async {
                                await deleteNotification(notif['id']);
                                final updated = await fetchNotifications();
                                setState(() => _notifications = updated);
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          await markNotificationAsSeen(notif['id']);
                          Navigator.pop(context); // Close dialog
                          final updated = await fetchNotifications();
                          setState(() => _notifications = updated);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return '';
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> markNotificationAsSeen(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.patch(
      Uri.parse("http://127.0.0.1:4000/api/notifications/$id/seen"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print("✅ Notification $id marked as seen");
    } else {
      print("❌ Failed to mark as seen: ${response.body}");
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');

    if (token == null || userId == null) {
      print("❌ Cannot mark all as read: missing token/userId");
      return;
    }

    final response = await http.patch(
      Uri.parse("http://127.0.0.1:4000/api/notifications/mark-all"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      print("✅ All notifications marked as read");
    } else {
      print("❌ Failed to mark all as read: ${response.body}");
    }
  }

  Future<void> deleteNotification(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse("http://127.0.0.1:4000/api/notifications/$id"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print("🗑 Notification $id deleted");
    } else {
      print("❌ Failed to delete notification: ${response.body}");
    }
  }

  Future<void> clearAllNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? userId = prefs.getInt('userId');
    final response = await http.delete(
      Uri.parse(
          "http://127.0.0.1:4000/api/notifications/clear-all?user_id=$userId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      print(" All notifications cleared");
    } else {
      print(" Failed to clear notifications: ${response.body}");
    }
  }

  //end

  void _calculateEstimate(int rowIndex) {
    double length =
        double.tryParse(_estimateRows[rowIndex].lengthController.text) ?? 0;
    double height =
        double.tryParse(_estimateRows[rowIndex].heightController.text) ?? 0;
    double rate =
        double.tryParse(_estimateRows[rowIndex].rateController.text) ?? 0;
    double quantity = 0;
    double area;

    setState(() {
      _measurements[rowIndex][0] = (length / mmToFeet).ceilToDouble();
      _measurements[rowIndex][1] = (height / mmToFeet).ceilToDouble();
      area = (_measurements[rowIndex][0] * _measurements[rowIndex][1])
          .ceilToDouble();

      // Update quantity based on area (every 50 sq.ft adds +1 to quantity)
      quantity = (area / 50).ceilToDouble();

      _areasAndAmounts[rowIndex][0] = area;
      _areasAndAmounts[rowIndex][1] = quantity;

      // Apply rate validation here, only set a minimum if rate is lower
      if (rate < 3600 && rate != 0) {
        rate = 3600;
      }

      // Amount calculation: rate * quantity
      _areasAndAmounts[rowIndex][2] = quantity * rate;

      // If primer is included, add the primer amount to the total amount
      if (_estimateRows[rowIndex].includePrimer) {
// Assuming primer rate is fixed at ₹13 per sq.ft
      }

      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    double transport = double.tryParse(transportController.text) ?? 0;
    double labourRate = double.tryParse(labourController.text) ?? 0;
    double primerRate = 13;
    double discount = double.tryParse(discountController.text) ?? 0;

    // Ensure discount is at least 10%
    if (discount <= 10) {
      discount = 10;
      discountController.text = '';
    }

    double totalPrimerRate = _areasAndAmounts.fold(0, (sum, row) {
      double rowPrimerAmount = 0;
      if (_estimateRows[_areasAndAmounts.indexOf(row)].includePrimer) {
        rowPrimerAmount = row[0] * primerRate;
      }
      return sum + rowPrimerAmount;
    });

    // Total labour rate = labour rate * quantity
    double totalLabourRate =
        _areasAndAmounts.fold(0, (sum, row) => sum + row[1] * labourRate);

    // Total amount
    double totalAmount = _areasAndAmounts.fold(0, (sum, row) => sum + row[2]);

    // GST calculation
    _gstamount = (totalPrimerRate + totalLabourRate + transport + totalAmount) *
        _gstPercentage /
        100;

    // Grand total calculation
    double grandTotal =
        totalPrimerRate + totalLabourRate + transport + totalAmount;
    double discountAmount = grandTotal * (discount / 100);
    grandTotal -= discountAmount;

    setState(() {
      _gstamount = _gstamount.ceilToDouble();
      _grandTotal = (grandTotal + _gstamount).ceilToDouble();
    });
  }

  void _clearData() {
    setState(() {
      for (int i = 0; i < _estimateRows.length; i++) {
        _estimateRows[i].lengthController.clear();
        _estimateRows[i].heightController.clear();
        _estimateRows[i].descriptionController.clear();
        _estimateRows[i].rateController.clear();
        _estimateRows[i].quantityController.clear();
        _resetCalculation(i);
      }
      gstController.clear();
      transportController.clear();
      labourController.clear();
      primerController.clear();
      _grandTotal = 0;
    });
  }

  void _resetCalculation(int index) {
    _measurements[index] = [0, 0];
    _areasAndAmounts[index] = [0, 0, 0];
  }

  void _addRow() {
    setState(() {
      _estimateRows
          .add(EstimateWRows(type: 'Master Room', stage: '', status: ''));
      _measurements.add([0, 0]);
      _areasAndAmounts.add([0, 0, 0]);
    });
  }

  void _deleteRow(int index) {
    setState(() {
      if (_estimateRows.length > 1) {
        _estimateRows.removeAt(index);
        _measurements.removeAt(index);
        _areasAndAmounts.removeAt(index);
      }
    });
  }

  Widget _buildCustomerInfo() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Customer Name", widget.customerInfo?['name'] ?? "-"),
          _buildInfoRow("Email", widget.customerInfo?['email'] ?? "-"),
          _buildInfoRow("Phone", widget.customerInfo?['phone'] ?? "-"),
        ],
      ),
    );
  }

// Helper method to align label & value in the same margin
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    double gstAmount = (_grandTotal * 18 / 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                          "GST (18%)", "₹${gstAmount.toStringAsFixed(2)}",
                          isMobile: true),
                      _buildSummaryRow(
                          "Grand Total", "₹${_grandTotal.toStringAsFixed(2)}",
                          isBold: true, color: Colors.green, isMobile: true),
                      _buildInputRow("Discount", discountController,
                          isMobile: true),
                      if (_showExtras) ...[
                        _buildInputRow("Transport (₹)", transportController,
                            isMobile: true),
                        _buildInputRow("Labour (₹)", labourController,
                            isMobile: true),
                      ]
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow("GST (18%)",
                                "₹${gstAmount.toStringAsFixed(2)}"),
                            const SizedBox(height: 10),
                            _buildSummaryRow("Grand Total",
                                "₹${_grandTotal.toStringAsFixed(2)}",
                                isBold: true, color: Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputRow("Discount", discountController),
                            const SizedBox(height: 10),
                            if (_showExtras) ...[
                              _buildInputRow(
                                  "Transport (₹)", transportController),
                              const SizedBox(height: 10),
                              _buildInputRow("Labour (₹)", labourController),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller,
      {bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (_) => setState(_calculateGrandTotal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? color, bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateTable() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24.0,
          headingRowHeight: 50,
          dataRowHeight: 60,
          columns: _buildDataColumns(),
          rows: List.generate(_estimateRows.length, (index) {
            return DataRow(cells: _buildDataCells(index));
          }),
        ),
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    const columnNames = [
      'S.No',
      'Room',
      'Description',
      'Length (mm)',
      'Height (mm)',
      'Length (Feet)',
      'Height (Feet)',
      'Area (sq.ft)',
      'Quantity',
      'Rate',
      'Amount',
      'Primer',
      'Actions',
    ];

    return List.generate(columnNames.length, (index) {
      return _columnVisibility[index]
          ? DataColumn(label: Text(columnNames[index]))
          : null;
    }).whereType<DataColumn>().toList();
  }

  List<DataCell> _buildDataCells(int index) {
    return List.generate(13, (columnIndex) {
      if (!_columnVisibility[columnIndex]) return null;

      switch (columnIndex) {
        case 0:
          return DataCell(Text((index + 1).toString()));
        case 1:
          return DataCell(
            DropdownButton<String>(
              value: _estimateRows[index].room,
              items: const [
                DropdownMenuItem(
                    value: 'Master Room', child: Text('Master Room')),
                DropdownMenuItem(value: 'Bed Room', child: Text('Bed Room')),
                DropdownMenuItem(
                    value: 'Kid Bedroom', child: Text('Kid Bedroom')),
              ],
              onChanged: (value) {
                setState(() {
                  _estimateRows[index].room = value!;
                  _saveDraftLocally();
                });
              },
            ),
          );
        case 2:
          return DataCell(TextField(
            controller: _estimateRows[index].descriptionController,
            decoration: const InputDecoration(
              hintText: 'Description',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ));
        case 3:
          return _buildTextFieldCell(
              _estimateRows[index].lengthController, 'Length (mm)', index);
        case 4:
          return _buildTextFieldCell(
              _estimateRows[index].heightController, 'Height (mm)', index);
        case 5:
          return DataCell(
              Text('${_measurements[index][0].toStringAsFixed(2)} ft'));
        case 6:
          return DataCell(
              Text('${_measurements[index][1].toStringAsFixed(2)} ft'));
        case 7:
          return DataCell(Text('${_areasAndAmounts[index][0].ceil()} sq.ft'));
        case 8:
          return DataCell(Text('${_areasAndAmounts[index][1].ceil()}'));
        case 9:
          return _buildTextFieldCell(
              _estimateRows[index].rateController, 'Rate', index);
        case 10:
          return DataCell(Text('${_areasAndAmounts[index][2].ceil()}'));
        case 11:
          return DataCell(Checkbox(
            value: _estimateRows[index].includePrimer,
            onChanged: (value) {
              setState(() {
                _estimateRows[index].includePrimer = value!;
                _calculateEstimate(index);
                _saveDraftLocally();
              });
            },
          ));
        case 12:
          return DataCell(
            IconButton(
              onPressed: () => _deleteRow(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          );
        default:
          return null;
      }
    }).whereType<DataCell>().toList();
  }

  DataCell _buildTextFieldCell(
      TextEditingController controller, String label, int index) {
    return DataCell(
      TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Enter',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) {
          _calculateEstimate(index);
          _saveDraftLocally(); // ✅ Save draft after any input change
        },
      ),
    );
  }

  Widget _buildGSTTransportLabourTable() {
    double gstAmount = (_grandTotal * 18 / 100);

    return FractionallySizedBox(
      alignment: Alignment.topLeft,
      widthFactor: 0.2,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelAndInput('Transport (₹)', transportController),
              _buildLabelAndInput('Labour (₹)    ', labourController),
              _buildLabelAndInput('Discount      ', discountController),
              const SizedBox(height: 10),
              Text(
                'GST (18%): ₹${gstAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              Text(
                'Grand Total: ₹${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelAndInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) {
                _calculateGrandTotal();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallpaper Estimation"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear Draft',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear Draft?"),
                  content: const Text(
                      "Are you sure you want to remove the saved draft?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel")),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Clear")),
                  ],
                ),
              );
              if (confirm == true) {
                await clearDraftLocally();
              }
            },
          ),

          IconButton(
            icon: Icon(
              _showExtras ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showExtras = !_showExtras;
              });
            },
          ),

          // 🔔 Notification Bell with Count
          if (!_isLoadingNotifications) _buildNotificationBell(_notifications),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Start New Wallpaper Estimation',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Add the customer dropdown here
              // _buildCustomerDropdown(),
              // Display customer information at the top of the page
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isMobile = constraints.maxWidth < 600;

                          if (isMobile) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCustomerInfo(),
                                const SizedBox(height: 16),
                                Divider(
                                    color: Colors.grey.shade300, thickness: 1),
                                const SizedBox(height: 16),
                                _buildSummaryCard(), // Already responsive inside
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 400, child: _buildCustomerInfo()),
                                Container(
                                  width: 2,
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                Expanded(child: _buildSummaryCard()),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildEstimateTable(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: _addRow,
                      child: const Text('Add Row'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _saveEstimateToDatabase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _onSaveAndGeneratePDF,
                      child: const Text('Generate PDF'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        SidebarController.of(context)
                            ?.openPage(const WallpaperEstimateListPage());
                      },
                      child: const Text('View Saved Estimates'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _clearData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEstimateToDatabase() async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api/wallpaper";
      double latestVersion = 0.0;
      String newVersion = '';

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      int? userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        print(' Error: Token or UserId is missing');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      final latestVersionResponse = await http.get(
        Uri.parse("$baseUrl/latest/${widget.customerId}"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (latestVersionResponse.statusCode == 200) {
        var data = jsonDecode(latestVersionResponse.body);
        latestVersion = double.tryParse(data['version'].toString()) ?? 0.0;
      } else {
        throw Exception("Failed to fetch the latest version.");
      }

      print(
          " Latest version for customer ${widget.customerId}: $latestVersion");

      if (latestVersion == 0.0) {
        newVersion = "1.1";
      } else {
        List<String> versionParts = latestVersion.toString().split('.');
        int major = int.parse(versionParts[0]);
        int minor = versionParts.length > 1 ? int.parse(versionParts[1]) : 0;

        if (minor >= 9) {
          major += 1;
          minor = 0;
        } else {
          minor += 1;
        }
        newVersion = "$major.$minor";
      }

      String getStageFromVersion(String version) {
        int major = int.tryParse(version.split('.').first) ?? 1;
        if (major == 1) return 'Sales';
        if (major == 2) return 'Pre-Designer';
        if (major == 3) return 'Designer';
        return 'Sales';
      }

      String computedStage = getStageFromVersion(newVersion);

      //  Check for at least one estimate row
      if (_estimateRows.isEmpty) {
        print(" No estimate rows provided.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please add at least one estimate row.")),
        );
        return;
      }

      Map<String, dynamic> estimateData = {
        'customerId': widget.customerId,
        'userId': userId,
        'discount': double.tryParse(discountController.text) ?? 0.0,
        'labour': double.tryParse(labourController.text) ?? 0.0,
        'transportCost': double.tryParse(transportController.text) ?? 0.0,
        'gstPercentage': _gstPercentage,
        'totalAmount': _grandTotal,
        'version': newVersion,
        'status': 'InProgress',
        'stage': computedStage,
        'estimateType': 'wallpaper',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse("$baseUrl/estimates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(estimateData),
      );

      final responseData = jsonDecode(response.body);
      print("🧾 Estimate Header Response: $responseData");

      if (response.statusCode != 201 || responseData['id'] == null) {
        throw Exception(
            " Estimate header failed or missing ID. Response: $responseData");
      }

      int estimateId = responseData['id'];
      print(" New estimate ID: $estimateId for version $newVersion");
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();

      List<Map<String, dynamic>> estimateRows = _estimateRows.map((row) {
        return {
          'estimateId': estimateId,
          'room': row.room,
          'description': row.descriptionController.text,
          'length': double.tryParse(row.lengthController.text) ?? 0.0,
          'height': double.tryParse(row.heightController.text) ?? 0.0,
          'rate': double.tryParse(row.rateController.text) ?? 0.0,
          'quantity': row.quantity,
          'amount': row.amount,
          'primerIncluded': row.includePrimer ? 1 : 0,
        };
      }).toList();

      final detailsResponse = await http.post(
        Uri.parse("$baseUrl/estimate-rows"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({'details': estimateRows}),
      );

      if (detailsResponse.statusCode != 201) {
        var detailsError = jsonDecode(detailsResponse.body);
        print(' Error saving detail rows: ${detailsResponse.body}');
        throw Exception(
            "Failed to save estimate details: ${detailsError['error']}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Estimate saved (version $newVersion)")),
      );
    } catch (e) {
      print(' Error saving estimate: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving estimate: $e')),
      );
    }
  }

  void _generatePDF(List<Map<String, dynamic>> estimateData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Wallpaper Estimation',
                  style: const pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(context: context, data: <List<String>>[
                <String>[
                  'Room',
                  'Description',
                  'Length',
                  'Height',
                  'Rate',
                  'Quantity',
                  'Amount',
                  'Primer Included'
                ],
                ...estimateData.map((row) => [
                      row['room'],
                      row['description'],
                      row['length'].toString(),
                      row['height'].toString(),
                      row['rate'].toString(),
                      row['quantity'].toString(),
                      row['amount'].toString(),
                      row['primerIncluded'] == 1 ? 'Yes' : 'No',
                    ])
              ]),
              pw.SizedBox(height: 24),
              pw.Text('Grand Total: ₹$_grandTotal',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    // Save PDF to device
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/estimate.pdf");
    await file.writeAsBytes(await pdf.save());

    // Optionally open the PDF file using the open_file package
    OpenFile.open(file.path);
  }

  void _onSaveAndGeneratePDF() async {
    for (int i = 0; i < _estimateRows.length; i++) {
      _saveEstimateToDatabase;
    }

    List<Map<String, dynamic>> estimateData =
        await WDatabaseHelper.getWallpaperEstimates();
    _generatePDF(estimateData);
  }

  void _loadEstimateFromData(Map<String, dynamic> estimateData) {
    try {
      print('Loading estimate from passed data');

      setState(() {
        discountController.text = (estimateData['discount'] ?? 0).toString();
        labourController.text = (estimateData['labour'] ?? 0).toString();
        transportController.text =
            (estimateData['transportCost'] ?? 0).toString();
        gstController.text = (estimateData['gstPercentage'] ?? 18).toString();

        List<dynamic> rows = estimateData['rows'] ?? [];

        _estimateRows.clear();

        for (var row in rows) {
          final newRow = EstimateWRows(
            type: row['room'] ?? 'Unknown Room',
            room: row['room'] ?? 'Unknown Room',
            stage: '',
            status: '',
          );
          newRow.descriptionController.text = row['description'] ?? '';
          newRow.lengthController.text = row['length'].toString();
          newRow.heightController.text = row['height'].toString();
          newRow.rateController.text = row['rate'].toString();
          newRow.quantityController.text = row['quantity'].toString();
          newRow.includePrimer = row['primerIncluded'] == 1;

          _estimateRows.add(newRow);
        }

        // ✅ Recalculate all estimates
        for (int i = 0; i < _estimateRows.length; i++) {
          _calculateEstimate(i);
        }

        // ✅ Recalculate grand total
        _calculateGrandTotal();
      });
    } catch (e) {
      print('Error loading estimate data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading estimate data: $e')),
      );
    }
  }

  void _loadEstimateData(int estimateId) async {
    try {
      print('Loading estimate data for estimateId: $estimateId');

      // ✅ Fetch estimate details from the Node.js API
      Map<String, dynamic>? estimateData =
          await WDatabaseHelper.getWallpaperEstimateById(estimateId);

      setState(() async {
        discountController.text = estimateData['discount'].toString();
        labourController.text = estimateData['labour'].toString();
        transportController.text = estimateData['transportCost'].toString();
        gstController.text = estimateData['gstPercentage'].toString();

        // ✅ Fetch estimate rows
        List<Map<String, dynamic>> estimateDetails =
            await WDatabaseHelper.fetchEstimateDetails(estimateId);

        _estimateRows.clear();

        for (var row in estimateDetails) {
          final newRow = EstimateWRows(
            type: row['room'] ?? 'Unknown Room',
            room: row['room'] ?? 'Unknown Room',
            stage: '',
            status: '',
          );
          newRow.descriptionController.text = row['description'] ?? '';
          newRow.lengthController.text = row['length'].toString();
          newRow.heightController.text = row['height'].toString();
          newRow.rateController.text = row['rate'].toString();
          newRow.quantityController.text = row['quantity'].toString();
          newRow.includePrimer = row['primerIncluded'] == 1;

          _estimateRows.add(newRow);
        }

        // ✅ Recalculate all estimates
        for (int i = 0; i < _estimateRows.length; i++) {
          _calculateEstimate(i);
        }

        // ✅ Recalculate grand total
        _calculateGrandTotal();
      });
    } catch (e) {
      print('Error loading estimate data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading estimate data: $e')),
      );
    }
  }
}
