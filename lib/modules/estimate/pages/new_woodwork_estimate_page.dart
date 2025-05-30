import 'dart:io';
import 'package:erp_tool/modules/estimate/pages/woodwork_estimate_list_page.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../database/estimate_database.dart';
import '../../../services/customer_database_service.dart';
import '../../../widgets/sidebar_menu.dart';
import '../../providers/notification_provider.dart';
import '../models/estimate_row.dart';
import '../models/woodwork_estimate.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:math_expressions/math_expressions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:math_expressions/math_expressions.dart' as math_expr;

class NewWoodworkEstimatePage extends StatefulWidget {
  final int? estimateId;
  final int customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic>? customerInfo;
  final WoodworkEstimate? existingEstimate;
  final Map<String, dynamic>? estimateData;
  const NewWoodworkEstimatePage({
    super.key,
    this.estimateId,
    this.existingEstimate,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.customerInfo,
    this.estimateData,
  });

  @override
  _NewWoodworkEstimatePageState createState() =>
      _NewWoodworkEstimatePageState();
}

class _NewWoodworkEstimatePageState extends State<NewWoodworkEstimatePage> {
  // final List<EstimateRow> _estimateRows = [EstimateRow()]; // Initial empty row
  List<EstimateRow> _estimateRows = [EstimateRow()]; // List for storing rows
  int? _estimateId;
  double _overallTotal = 0.0;
  double _overallTotal2 = 0.0;
  double _overallTotal3 = 0.0;
  double _transportCost = 20000;
  double _gstPercentage = 18; // State variable for GST percentage
  bool _isLoading = true;

  bool _isTransportHidden = true; // State variable to control visibility
  final TextEditingController _uniqueTransportCostController =
      TextEditingController();

  double _discountPercentage = 0; // To store the discount percentage
  double _discountedOverallTotal = 0.0;
  double _discountedOverallTotal2 = 0.0;
  double _discountedOverallTotal3 = 0.0;

  double _hikePercentage = 20;

  // List to manage column visibility
  final List<bool> _columnVisibility = List<bool>.generate(34, (index) => true);

  //customer info section

  final List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;
  bool _showSecondFinish = false;
  bool _showThirdFinish = false;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  final Map<String, Color> roomColorMap = {
    'Kitchen': Colors.green.shade50,
    'Living Room': Colors.pink.shade50,
    'Bedroom': Colors.blue.shade50,
    'Study': Colors.yellow.shade50,
    'Pooja': Colors.cyan.shade50,
    'Balcony': Colors.orange.shade50,
    'Utility': Colors.lime.shade50,
    'Other': Colors.purple.shade50,
  };

  Color _getRoomColor(String? room) {
    if (room == null || room.isEmpty) return Colors.white;
    return roomColorMap[room] ?? Colors.grey.shade100; // fallback color
  }

  Future<void> _fetchCustomers() async {
    final dbService = CustomerDatabaseService();
    final response = await dbService.fetchCustomers();
    setState(() {
      _customers.clear();
      _customers.addAll(response['customers']);
    });
  }

  void exportToExcel() async {
    try {
      var excel = Excel.createExcel(); // Create a new Excel document
      Sheet sheet = excel['Sheet1']; // Get the default sheet

      // Add header row with `CellValue`
      sheet.appendRow([
        'S.No',
        'Unit Name',
        'Description',
        'Width (MM)',
        'Height (MM)',
        'Width (Feet)',
        'Height (Feet)',
        'Square Feet',
        'Quantity',
        'Finish',
        'Rate',
        'Amount',
        'Total Amount',
        'Finish Type 2',
        'Rate 2',
        'Amount 2',
        'Total Amount 2',
        'Finish Type 3',
        'Rate 3',
        'Amount 3',
        'Total Amount 3',
        'Side Panel 1',
        'Rate 1',
        'Quantity 1',
        'Amount 1',
        'Side Panel 2',
        'Rate 2',
        'Quantity 2',
        'Amount 2',
        'Side Panel 3',
        'Rate 3',
        'Quantity 3',
        'Amount 3'
      ].map((e) => TextCellValue(e)).toList());

      // Add data rows
      for (var row in _estimateRows) {
        sheet.appendRow([
          row.sNo,
          row.selectedUnit ?? '',
          row.description ?? '',
          row.widthMM,
          row.heightMM,
          row.widthInFeet,
          row.heightInFeet,
          row.squareFeet,
          row.quantity,
          row.selectedFinish ?? '',
          row.selectedFinishRate,
          row.amount,
          // row.totalAmount,
          row.selectedSecondFinish ?? '',
          row.selectedFinishRate2,
          row.secondAmount,
          // row.totalAmount2,
          row.selectedThirdFinish ?? '',
          row.selectedFinishRate3,
          row.thirdAmount,
          // row.totalAmount3,
          row.selectedSidePanel1 ?? '',
          row.sidePanelRate1,
          row.sidePanelQuantity1,
          row.sidePanelAmount1,
          row.selectedSidePanel2 ?? '',
          row.sidePanelRate2,
          row.sidePanelQuantity2,
          row.sidePanelAmount2,
          row.selectedSidePanel3 ?? '',
          row.sidePanelRate3,
          row.sidePanelQuantity3,
          row.sidePanelAmount3,
        ].map((e) {
          if (e is String) return TextCellValue(e);
          if (e is int) return IntCellValue(e);
          if (e is double) return DoubleCellValue(e);
          return TextCellValue(e.toString());
        }).toList());
      }

      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          "${directory.path}/Woodwork_Estimate_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(filePath);

      // Save the file
      await file.writeAsBytes(excel.encode()!);

      // Notify user about the file path
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Exported to $filePath")));
    } catch (e) {
      print("Error exporting to Excel: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to export to Excel")));
    }
  }

  Future<void> importFromExcel() async {
    // Pick the Excel file
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

    if (result != null) {
      // Get the selected file
      File file = File(result.files.single.path!);

      // Read the Excel file
      var bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      // Get the first sheet
      var sheet = excel.tables.keys.first;

      // Parse the data and import it into your application
      var rows = excel.tables[sheet]?.rows;

      if (rows != null) {
        // Skip the first row if it contains headers
        for (var i = 1; i < rows.length; i++) {
          var row = rows[i];

          // Example: Assuming the columns are in the same order as in the export
          String description = row[0] as String;
          double widthMM = double.tryParse(row[1].toString()) ?? 0.0;
          double heightMM = double.tryParse(row[2].toString()) ?? 0.0;
          int quantity = int.tryParse(row[3].toString()) ?? 0;
          double rate = double.tryParse(row[4].toString()) ?? 0.0;
          double amount = double.tryParse(row[5].toString()) ?? 0.0;

          // Add to your rows list or process as needed
          _estimateRows.add(EstimateRow(
            description: description,
            widthMM: widthMM,
            heightMM: heightMM,
            quantity: quantity,
            selectedFinishRate: rate,
            amount: amount,
          ));
        }

        // Update the UI or perform any necessary actions after importing
        setState(() {});
      }
    } else {
      // User canceled the file selection
      print('No file selected');
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchCustomers();

    // ✅ If estimateData is passed directly, use it
    if (widget.estimateData != null) {
      print("📦 Estimate data received from CustomerEstimatePage:");
      print(widget.estimateData);

      // You can initialize values like this:
      _estimateId = widget.estimateData!['estimateId'];
      _discountPercentage = widget.estimateData!['discount'] ?? 0;
      _transportCost = widget.estimateData!['transportCost'] ?? 0;
      _gstPercentage = widget.estimateData!['gstPercentage'] ?? 0;
      _overallTotal = widget.estimateData!['totalAmount'] ?? 0;

      // ✅ If you already have rows, assign here too (optional)
      // _estimateRows = widget.estimateData!['rows']; // Only if rows are available

      // Then proceed with normal fetch
    }

    _fetchFinishTypesAndRates().then((_) {
      if (widget.estimateId != null) {
        _loadEstimateData(widget.estimateId!).then((_) {
          setState(() => _isLoading = false);
        });
      } else if (widget.existingEstimate != null) {
        _estimateRows = widget.existingEstimate!.rows;
        _overallTotal = widget.existingEstimate!.totalAmount;
        _discountPercentage = widget.existingEstimate!.discount;
        _transportCost = widget.existingEstimate!.transportCost;
        _gstPercentage = widget.existingEstimate!.gstPercentage;
        _isLoading = false;
      } else {
        _loadAll().then((_) {
          _calculateOverallTotal();
          setState(() => _isLoading = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  //end

  //Auto save

  Future<void> _loadAll() async {
    if (widget.estimateId != null) {
      await _loadEstimateData(widget.estimateId!);
    } else if (widget.existingEstimate != null) {
      _estimateRows = widget.existingEstimate!.rows;
      _overallTotal = widget.existingEstimate!.totalAmount;
      _discountPercentage = widget.existingEstimate!.discount;
      _transportCost = widget.existingEstimate!.transportCost;
      _gstPercentage = widget.existingEstimate!.gstPercentage;
    } else {
      await _loadDraftIfAvailable();
    }
  }

  Future<void> _saveDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> rowData = _estimateRows
        .where((row) =>
            row.selectedUnit != null ||
            row.description?.isNotEmpty == true ||
            row.widthMM > 0 ||
            row.heightMM > 0 ||
            row.selectedFinishRate > 0 ||
            row.sidePanelAmount1 > 0)
        .map((row) => row.toJson())
        .toList();

    await prefs.setString('draftEstimateRows', jsonEncode(rowData));
    await prefs.setDouble('draftTransportCost', _transportCost);
    await prefs.setDouble('draftGst', _gstPercentage);
    await prefs.setDouble('draftDiscount', _discountPercentage);
    await prefs.setDouble('draftHike', _hikePercentage);
  }

  Future<void> _loadDraftIfAvailable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? rowsJson = prefs.getString('draftEstimateRows');

    if (rowsJson != null) {
      debugPrint('[Draft] Checking for local draft...');
      bool restore = await _showRestoreDialog();

      debugPrint('[Draft] User choice: ${restore ? 'Restore' : 'Discard'}');
      if (restore) {
        List<dynamic> data = jsonDecode(rowsJson);
        debugPrint('[Draft] Raw JSON data: $data');

        List<EstimateRow> restoredRows =
            data.map((e) => EstimateRow.fromJson(e)).toList();

        // 👇 Initialize controllers for each restored row
        for (var row in restoredRows) {
          row.initControllers(); // <-- Make sure you have this method in EstimateRow
          if (row.selectedUnit != null &&
              unitMeasurements.containsKey(row.selectedUnit)) {
            row.availableFinishTypes = unitMeasurements[row.selectedUnit]!;
          }
        }

        debugPrint('[Draft] Decoded ${restoredRows.length} rows');

        setState(() {
          _estimateRows = restoredRows;
          _transportCost = prefs.getDouble('draftTransportCost') ?? 0.0;
          _gstPercentage = prefs.getDouble('draftGst') ?? 0.0;
          _discountPercentage = prefs.getDouble('draftDiscount') ?? 0.0;
          _hikePercentage = prefs.getDouble('draftHike') ?? 0.0;
        });

        _calculateOverallTotal();
      } else {
        await _clearLocalDraft();
      }
    }
  }

  Future<void> _clearLocalDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('draftEstimateRows');
    await prefs.remove('draftTransportCost');
    await prefs.remove('draftGst');
    await prefs.remove('draftDiscount');
    await prefs.remove('draftHike');
  }

  //end
// auto focus
  void _focusNextField(int rowIndex, String currentField) {
    final row = _estimateRows[rowIndex];

    switch (currentField) {
      case 'width':
        FocusScope.of(context).requestFocus(row.heightFocus);
        break;
      case 'height':
        FocusScope.of(context).requestFocus(row.quantityFocus);
        break;
      case 'description':
        FocusScope.of(context).requestFocus(row.widthFocus);
        break;
      case 'quantity':
        FocusScope.of(context).unfocus(); // Done
        break;
      default:
        FocusScope.of(context).unfocus();
    }
  }

  //
  Future<bool> _showRestoreDialog() async {
    bool result = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Unsaved Estimate?'),
        content: const Text(
            'You have an unsaved estimate. Would you like to restore it?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              result = false;
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              result = true;
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result;
  }

  // Fetch estimate data based on the estimateId
  Future<void> _loadEstimateData(int estimateId) async {
    try {
      // Fetch the estimate data from the database
      final estimateData = await EstimateDatabase.getEstimate(estimateId);

      // Check the structure of the returned data
      print("Fetched estimate data: $estimateData");

      // Check if 'rows' exist in the response
      if (estimateData.containsKey('rows')) {
        final rows = estimateData['rows'] as List;
        print("Rows data: $rows");

        // Set the state with fetched rows data
        setState(() {
          _estimateRows = rows.map((row) {
            return EstimateRow(
              sNo: _parseInt(row['sNo']),
              room: row['room'],
              selectedUnit: row['selectedUnit'],
              description: row['description'],
              widthInput: row['widthInput'],
              widthMM: _parseDouble(row['widthMM']),
              heightInput: row['heightInput'],
              heightMM: _parseDouble(row['heightMM']),
              widthInFeet: _parseDouble(row['widthFeet']),
              heightInFeet: _parseDouble(row['heightFeet']),
              squareFeet: _parseDouble(row['squareFeet']),
              quantity: _parseInt(row['quantity']),
              selectedFinish: row['finishType1'],
              selectedFinishRate: _parseDouble(row['selectedFinishRate']),
              amount: _parseDouble(row['amount1']),
              selectedSecondFinish: row['finishType2'],
              selectedFinishRate2: _parseDouble(row['selectedFinishRate2']),
              secondAmount: _parseDouble(row['amount2']),
              selectedThirdFinish: row['finishType3'],
              selectedFinishRate3: _parseDouble(row['selectedFinishRate3']),
              thirdAmount: _parseDouble(row['amount3']),
              selectedSidePanel1: row['sidePanel1'],
              sidePanelRate1: _parseDouble(row['sideRate1']),
              sidePanelQuantity1: _parseInt(row['sideQuantity1']),
              sidePanelAmount1: _parseDouble(row['sideAmount1']),
              selectedSidePanel2: row['sidePanel2'],
              sidePanelRate2: _parseDouble(row['sideRate2']),
              sidePanelQuantity2: _parseInt(row['sideQuantity2']),
              sidePanelAmount2: _parseDouble(row['sideAmount2']),
              selectedSidePanel3: row['sidePanel3'],
              sidePanelRate3: _parseDouble(row['sideRate3']),
              sidePanelQuantity3: _parseInt(row['sideQuantity3']),
              sidePanelAmount3: _parseDouble(row['sideAmount3']),
            );
          }).toList();

          // ✅ Initialize controllers and finish types after parsing
          for (var row in _estimateRows) {
            row.initControllers(); // Make sure EstimateRow has this method
            if (row.selectedUnit != null &&
                unitMeasurements.containsKey(row.selectedUnit)) {
              row.availableFinishTypes = unitMeasurements[row.selectedUnit]!;
            }
          }

          // ✅ Auto-toggle Finish Type 2/3 columns if any row has data
          _showSecondFinish = _estimateRows.any((row) =>
              (row.selectedSecondFinish != null &&
                  row.selectedSecondFinish!.isNotEmpty) ||
              row.secondAmount > 0 ||
              row.sidePanelAmount2 > 0);

          _showThirdFinish = _estimateRows.any((row) =>
              (row.selectedThirdFinish != null &&
                  row.selectedThirdFinish!.isNotEmpty) ||
              row.thirdAmount > 0 ||
              row.sidePanelAmount3 > 0);
        });
      } else {
        print('No rows found in the fetched data.');
      }
    } catch (e) {
      print("Error loading estimate: $e");
      // Handle the error if something goes wrong with fetching the data
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Unit options
  final Map<String, Map<String, double>> unitMeasurements = {};

  // Method to fetch finish types and rates from the database

  Future<void> _fetchFinishTypesAndRates() async {
    try {
      const url = "http://127.0.0.1:4000/api/core-woodwork/get-Finish-and-rate";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> finishes = jsonDecode(response.body);

        final Map<String, Map<String, double>> fetchedUnitMeasurements = {};

        for (var row in finishes) {
          String unitType = row['unitType'];
          String finish = row['finish'];
          double rate = double.tryParse(row['rate'].toString()) ?? 0.0;

          if (!fetchedUnitMeasurements.containsKey(unitType)) {
            fetchedUnitMeasurements[unitType] = {};
          }
          fetchedUnitMeasurements[unitType]![finish] = rate;
        }

        setState(() {
          unitMeasurements.clear();
          unitMeasurements.addAll(fetchedUnitMeasurements);
        });
      } else {
        throw Exception("Error fetching finishes: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching finish types and rates: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching finish types: $e")),
      );
    }
  }

  final Map<String, double> sideOptions = {
    'Side Panel - Laminate - Gloss/Tex/MR - SP': 2400,
    'Side Panel - UV': 15000,
  };

  void _addRow() {
    setState(() {
      _estimateRows.add(EstimateRow());
    });
    _saveDraftLocally();
  }

  void _duplicateRow(int index) {
    setState(() {
      final currentMaxSno = _estimateRows
          .map((e) => e.sNo)
          .fold<int>(0, (prev, sno) => sno > prev ? sno : prev);
      final duplicated =
          _estimateRows[index].copyWithNextSerial(currentMaxSno + 1);
      _estimateRows.insert(index + 1, duplicated);
    });
  }

  void _calculateOverallTotal() {
    double total = 0.0;
    double total2 = 0.0;
    double total3 = 0.0;

    // Correct hike multiplier formula
    double gstMultiplier = (100 + _gstPercentage) / 100; // GST as a multiplier
    double hikeMultiplier =
        1 / (1 - (_hikePercentage / 100)); // Correct hike multiplier

    // Calculate base totals for proportions
    double baseTotal = 0.0;
    double baseTotal2 = 0.0;
    double baseTotal3 = 0.0;

    for (var row in _estimateRows) {
      baseTotal += row.baseAmount;
      baseTotal2 += row.baseSecondAmount;
      baseTotal3 += row.baseThirdAmount;
    }

    for (var row in _estimateRows) {
      // Proportional transport cost split
      double transportCostSplit =
          (_transportCost * (row.baseAmount / baseTotal)).isNaN
              ? 0.0
              : _transportCost * (row.baseAmount / baseTotal);
      double transportCostSplit2 =
          (_transportCost * (row.baseSecondAmount / baseTotal2)).isNaN
              ? 0.0
              : _transportCost * (row.baseSecondAmount / baseTotal2);
      double transportCostSplit3 =
          (_transportCost * (row.baseThirdAmount / baseTotal3)).isNaN
              ? 0.0
              : _transportCost * (row.baseThirdAmount / baseTotal3);

      // Apply GST, hike, and transport cost directly to the row amounts
      row.amount = row.baseAmount * hikeMultiplier * gstMultiplier +
          row.sidePanelAmount1 +
          transportCostSplit;
      row.secondAmount = row.baseSecondAmount * hikeMultiplier * gstMultiplier +
          row.sidePanelAmount2 +
          transportCostSplit2;
      row.thirdAmount = row.baseThirdAmount * hikeMultiplier * gstMultiplier +
          row.sidePanelAmount3 +
          transportCostSplit3;

      // Add the calculated amounts to totals
      total += row.amount;
      total2 += row.secondAmount;
      total3 += row.thirdAmount;
    }

    setState(() {
      // Update overall totals with GST and hike
      _overallTotal = total.roundToDouble(); // Rounded to nearest whole number
      _overallTotal2 =
          total2.roundToDouble(); // Rounded to nearest whole number
      _overallTotal3 =
          total3.roundToDouble(); // Rounded to nearest whole number

      // Apply discounts
      double discountAmount = (_overallTotal * _discountPercentage) / 100;
      _discountedOverallTotal = (_overallTotal - discountAmount)
          .roundToDouble(); // Rounded to nearest whole number

      discountAmount = (_overallTotal2 * _discountPercentage) / 100;
      _discountedOverallTotal2 = (_overallTotal2 - discountAmount)
          .roundToDouble(); // Rounded to nearest whole number

      discountAmount = (_overallTotal3 * _discountPercentage) / 100;
      _discountedOverallTotal3 = (_overallTotal3 - discountAmount)
          .roundToDouble(); // Rounded to nearest whole number
    });
  }

  Future<void> _saveEstimate() async {
    try {
      // Step 1: Retrieve userId and token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');
      String? token = prefs.getString('token');

      if (userId == null) throw Exception("User is not authenticated.");
      if (token == null) throw Exception("Token is missing.");

      // Step 2: Get latest version
      Map<String, dynamic> latestVersionData =
          await EstimateDatabase.getLatestVersion(
              widget.customerId, "Woodwork");

      String latestVersionStr = latestVersionData['version'].toString();
      double latestVersion = double.tryParse(latestVersionStr) ?? 0.0;

      // Step 3: Calculate new version
      String newVersion;
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

      // Step 4: Auto-assign stage based on version
      String getStageFromVersion(String version) {
        int major = int.tryParse(version.split('.').first) ?? 1;
        if (major == 1) return 'Sales';
        if (major == 2) return 'Pre-Designer';
        if (major == 3) return 'Designer';
        return 'Sales';
      }

      String computedStage = getStageFromVersion(newVersion);

      // Step 5: Build rows
      List<EstimateRow> rows = _estimateRows.map((row) {
        return EstimateRow(
          sNo: _estimateRows.indexOf(row) + 1,
          room: row.room,
          selectedUnit: row.selectedUnit,
          description: row.description,
          widthInput: row.widthInput,
          widthMM: double.tryParse(row.widthController.text) ?? 0.0,
          heightInput: row.heightInput,
          heightMM: double.tryParse(row.heightController.text) ?? 0.0,
          widthInFeet: row.widthInFeet,
          heightInFeet: row.heightInFeet,
          squareFeet: row.squareFeet,
          quantity: row.quantity ?? 0,
          selectedFinish: row.selectedFinish ?? '',
          selectedProfileHandle: row.selectedProfileHandle ?? '',
          selectedSecondFinish: row.selectedSecondFinish ?? '',
          selectedThirdFinish: row.selectedThirdFinish ?? '',
          selectedFinishRate: row.selectedFinishRate,
          selectedFinishRate2: row.selectedFinishRate2,
          selectedFinishRate3: row.selectedFinishRate3,
          baseAmount: row.baseAmount,
          baseSecondAmount: row.baseSecondAmount,
          baseThirdAmount: row.baseThirdAmount,
          amount: row.amount,
          secondAmount: row.secondAmount,
          thirdAmount: row.thirdAmount,
          selectedSidePanel1: row.selectedSidePanel1 ?? '',
          sidePanelRate1: row.sidePanelRate1,
          sidePanelQuantity1: row.sidePanelQuantity1,
          sidePanelAmount1: row.sidePanelAmount1,
          selectedSidePanel2: row.selectedSidePanel2 ?? '',
          sidePanelRate2: row.sidePanelRate2,
          sidePanelQuantity2: row.sidePanelQuantity2,
          sidePanelAmount2: row.sidePanelAmount2,
          selectedSidePanel3: row.selectedSidePanel3 ?? '',
          sidePanelRate3: row.sidePanelRate3,
          sidePanelQuantity3: row.sidePanelQuantity3,
          sidePanelAmount3: row.sidePanelAmount3,
        );
      }).toList();

      // Step 6: Create estimate object
      WoodworkEstimate newEstimate = WoodworkEstimate(
        customerId: widget.customerId,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
        totalAmount: _overallTotal,
        totalAmount2: _overallTotal2,
        totalAmount3: _overallTotal3,
        discount: _discountPercentage,
        transportCost: _transportCost,
        gstPercentage: _gstPercentage,
        estimateType: "Woodwork",
        version: newVersion,
        rows: rows,
        userId: userId,
        status: 'InProgress',
        stage: computedStage, //  auto stage based on version
      );

      // Step 7: Save to DB
      final estimateId =
          await EstimateDatabase.createEstimate(newEstimate.toMap());

      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();

      if (estimateId == -1) {
        throw Exception('Failed to insert estimate into database.');
      }

      _showSaveDialog("Estimate saved successfully!");

      // Redirect
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WoodworkEstimateListPage(),
          ),
        );
      });
    } catch (error, stackTrace) {
      print('Error saving estimate: $error\n$stackTrace');
      _showSaveDialog("Failed to save estimate: $error");
    }
  }

  void _showSaveDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Estimate'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (message.contains("successfully")) {
                  Navigator.pop(context);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // For Kitchen and Bedroom Flow
  void _calculateKitchenBedroomAmount(int index) {
    final widthMM = _estimateRows[index].widthMM; // Use evaluated value
    final heightMM = _estimateRows[index].heightMM;

    double roundToNearest76_2(double value) {
      final remainder = value % 76.2;
      return remainder <= 3 ? value - remainder : value + (76.2 - remainder);
    }

    final roundedHeightMM = roundToNearest76_2(heightMM);
    final roundedWidthMM = roundToNearest76_2(widthMM);

    final heightFeet = roundedHeightMM / 304.8;
    final widthFeet = roundedWidthMM / 304.8;

    final squareFeet = heightFeet * widthFeet;

    final rate = _estimateRows[index]
            .availableFinishTypes[_estimateRows[index].selectedFinish] ??
        0.0;
    final secondFinishRate = _estimateRows[index]
            .availableFinishTypes[_estimateRows[index].selectedSecondFinish] ??
        0.0;
    final thirdFinishRate = _estimateRows[index]
            .availableFinishTypes[_estimateRows[index].selectedThirdFinish] ??
        0.0;

    final gstMultiplier = (100 + _gstPercentage) / 100;

    setState(() {
      _estimateRows[index].heightInFeet = heightFeet;
      _estimateRows[index].widthInFeet = widthFeet;
      _estimateRows[index].squareFeet = squareFeet;

      // Base amounts
      _estimateRows[index].baseAmount = squareFeet * rate;
      _estimateRows[index].baseSecondAmount = squareFeet * secondFinishRate;
      _estimateRows[index].baseThirdAmount = squareFeet * thirdFinishRate;

      // Apply GST
      _estimateRows[index].amount =
          _estimateRows[index].baseAmount * gstMultiplier;
      _estimateRows[index].secondAmount =
          _estimateRows[index].baseSecondAmount * gstMultiplier;
      _estimateRows[index].thirdAmount =
          _estimateRows[index].baseThirdAmount * gstMultiplier;
    });

    // Recalculate totals to reflect changes
    _calculateOverallTotal();
  }

  // For Other Options
  void _calculateOtherItemsAmount(int index) {
    final quantity =
        int.tryParse(_estimateRows[index].quantityController.text) ?? 0;
    final rate = _estimateRows[index]
            .availableFinishTypes[_estimateRows[index].selectedFinish] ??
        0.0;
    final secondFinishRate = _estimateRows[index]
            .availableFinishTypes[_estimateRows[index].selectedSecondFinish] ??
        0.0;
    final thirdFinishRate = _estimateRows[index]
            .availableFinishTypes[_estimateRows[index].selectedThirdFinish] ??
        0.0;

    final gstMultiplier = (100 + _gstPercentage) / 100;
    final hikeMultiplier = 1 / (1 - (_hikePercentage / 100));

    setState(() {
      // Calculate base amounts
      _estimateRows[index].baseAmount = quantity * rate;
      _estimateRows[index].baseSecondAmount = quantity * secondFinishRate;
      _estimateRows[index].baseThirdAmount = quantity * thirdFinishRate;

      // Apply GST
      double amountWithGST = _estimateRows[index].baseAmount * gstMultiplier;
      double secondAmountWithGST =
          _estimateRows[index].baseSecondAmount * gstMultiplier;
      double thirdAmountWithGST =
          _estimateRows[index].baseThirdAmount * gstMultiplier;

      // Apply hike
      _estimateRows[index].amount = amountWithGST * hikeMultiplier;
      _estimateRows[index].secondAmount = secondAmountWithGST * hikeMultiplier;
      _estimateRows[index].thirdAmount = thirdAmountWithGST * hikeMultiplier;

      // Recalculate overall totals
      _calculateOverallTotal();
    });
  }

  void _calculateSidePanelAmounts(int rowIndex) {
    final gstMultiplier = _gstPercentage > 0
        ? (100 + _gstPercentage) / 100
        : 1.0; // If GST is 0, no change in value

    setState(() {
      // Base values * GST (if any)
      _estimateRows[rowIndex].sidePanelAmount1 =
          _estimateRows[rowIndex].sidePanelRate1 *
              _estimateRows[rowIndex].sidePanelQuantity1 *
              gstMultiplier;

      _estimateRows[rowIndex].sidePanelAmount2 =
          _estimateRows[rowIndex].sidePanelRate2 *
              _estimateRows[rowIndex].sidePanelQuantity2 *
              gstMultiplier;

      _estimateRows[rowIndex].sidePanelAmount3 =
          _estimateRows[rowIndex].sidePanelRate3 *
              _estimateRows[rowIndex].sidePanelQuantity3 *
              gstMultiplier;

      _calculateOverallTotal(); // Update totals after side panel change
    });
  }

  void _unhideColumn() {
    setState(() {
      _isTransportHidden =
          !_isTransportHidden; // Set visibility to false, showing the hidden field
    });
  }

  List<bool> _selectedRows =
      List<bool>.generate(33, (index) => false); // To track selected rows

  Future<void> _deleteSelectedRows() async {
    try {
      // Step 1: Collect selected row indices
      List<int> selectedRowIndices = [];
      for (int i = 0; i < _selectedRows.length; i++) {
        if (_selectedRows[i]) {
          selectedRowIndices.add(i); // Add index of selected rows
        }
      }

      if (selectedRowIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rows selected for deletion')),
        );
        return; // Exit if no rows are selected
      }

      // Step 2: Remove the selected rows from the local list (UI)
      setState(() {
        // Remove rows from _estimateRows where their index is in selectedRowIndices
        _estimateRows.removeWhere((row) {
          int index = _estimateRows.indexOf(row);
          return selectedRowIndices.contains(index); // Check if row is selected
        });

        // Reset the selected row indicators
        _selectedRows = List<bool>.generate(
          _estimateRows.length,
          (index) => false,
        );

        _calculateOverallTotal(); // Recalculate totals after removal
      });

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected rows removed from the table')),
      );
    } catch (e) {
      // Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove selected rows')),
      );
    }
  }

  void _clearAllRows() {
    setState(() {
      _estimateRows.clear();
      _selectedRows.clear();
      _calculateOverallTotal(); // Recalculate the totals after clearing the rows
    });
  }

  double evaluateExpression(String input) {
    try {
      if (input.isEmpty) return 0.0; // Handle empty input
      if (input.startsWith('=')) {
        String expression = input.substring(1); // Remove '='
        var parser = math_expr.Parser(); // Using math_expressions
        Expression exp = parser.parse(expression);
        ContextModel context = ContextModel();
        return exp.evaluate(EvaluationType.REAL, context);
      } else {
        // If no '=' prefix, treat it as a plain number
        double? value = double.tryParse(input);
        if (value == null) throw const FormatException("Invalid number");
        return value;
      }
    } catch (e) {
      print('Error evaluating expression "$input": $e');
      return 0.0; // Default to 0 if there's an error
    }
  }

  void _showEditInputDialog({
    required BuildContext context,
    required String title,
    required String initialValue,
    required Function(String) onSubmitted,
  }) {
    TextEditingController inputController =
        TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: inputController,
            decoration: const InputDecoration(
              hintText: 'Enter new value',
            ),
            keyboardType: TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSubmitted(inputController.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _estimateRowWidget() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) => const Color(0xFFF8C794),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              columnSpacing: 16.0,
              columns: List.generate(35, (index) {
                if (index == 0) return const DataColumn(label: Text('Select'));
                int actualColumnIndex = index - 1;

                if (((actualColumnIndex >= 18 && actualColumnIndex <= 21) ||
                        (actualColumnIndex >= 22 && actualColumnIndex <= 25)) &&
                    !_showSecondFinish) {
                  return null;
                }

                if (((actualColumnIndex >= 26 && actualColumnIndex <= 29) ||
                        (actualColumnIndex >= 30 && actualColumnIndex <= 33)) &&
                    !_showThirdFinish) {
                  return null;
                }

                if (!_columnVisibility[actualColumnIndex]) return null;

                return DataColumn(
                  label: _buildHeaderCell(_getColumnName(actualColumnIndex)),
                );
              }).whereType<DataColumn>().toList(),
              rows: List.generate(_estimateRows.length, (rowIndex) {
                final roomColor = _getRoomColor(_estimateRows[rowIndex].room);
                return DataRow(
                  selected:
                      _selectedRows[rowIndex], // Highlight the row if selected
                  color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(100);
                      }
                      return roomColor;
                    },
                  ),
                  cells: [
                    // Checkbox for row selection in the first column
                    DataCell(
                      Checkbox(
                        value: _selectedRows[
                            rowIndex], // Bind to the selection state
                        onChanged: (bool? value) {
                          setState(() {
                            _selectedRows[rowIndex] =
                                value ?? false; // Update selection
                          });
                        },
                      ),
                    ),
                    // Add other data cells for the row
                    ...List.generate(34, (columnIndex) {
                      if (((columnIndex >= 18 && columnIndex <= 21) ||
                              (columnIndex >= 22 && columnIndex <= 25)) &&
                          !_showSecondFinish) {
                        return null;
                      }

                      if (((columnIndex >= 26 && columnIndex <= 30) ||
                              (columnIndex >= 30 && columnIndex <= 33)) &&
                          !_showThirdFinish) {
                        return null;
                      }

                      if (!_columnVisibility[columnIndex]) return null;

                      return _generateDataCell(rowIndex, columnIndex);
                    }).whereType<DataCell>(),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white, // 🔸 Header text color
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Helper function to generate DataCell
  DataCell _generateDataCell(int rowIndex, int columnIndex) {
    switch (columnIndex) {
      case 0: // Unit Name
        return DataCell(Text((rowIndex + 1).toString()));
      case 1: // Room
        return DataCell(
          DropdownButton<String>(
            value: _estimateRows[rowIndex].room,
            items: _estimateRows[rowIndex].availableRooms.map((room) {
              return DropdownMenuItem(
                value: room,
                child: Text(room),
              );
            }).toList(),
            hint: const Text('Select Room'),
            onChanged: (selectedRoom) {
              setState(() {
                _estimateRows[rowIndex].room = selectedRoom;
                _saveDraftLocally();
              });
            },
          ),
        );

      case 2: // Unit Type (DropdownButton for units)
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex].selectedUnit, // The selected value
          items: unitMeasurements.keys.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit),
            );
          }).toList(),
          onChanged: (selectedUnit) {
            setState(() {
              // If selectedUnit is valid (exists in the unitMeasurements.keys), update it
              if (unitMeasurements.keys.contains(selectedUnit)) {
                _estimateRows[rowIndex].selectedUnit = selectedUnit;
              } else {
                // If invalid, reset to null (or to a valid default unit)
                _estimateRows[rowIndex].selectedUnit = null;
              }

              // Reset finishes and related fields
              _estimateRows[rowIndex].selectedFinish = null;
              _estimateRows[rowIndex].selectedSecondFinish = null;
              _estimateRows[rowIndex].selectedThirdFinish = null;

              // Update available finishes based on selected unit
              _estimateRows[rowIndex].availableFinishTypes =
                  unitMeasurements[selectedUnit] ?? {};
            });
            _saveDraftLocally();
          },
          hint: const Text("Select Unit"),
          // Add a hint in case of no value selected // Added hint for better user experience
        ));
      case 3: // Description
        return DataCell(TextField(
          controller: _estimateRows[rowIndex].descriptionController,
          focusNode: _estimateRows[rowIndex].descriptionFocus,
          decoration:
              const InputDecoration.collapsed(hintText: 'Enter description'),
          onSubmitted: (value) {
            setState(() {
              _estimateRows[rowIndex].description = value;
            });
            _focusNextField(rowIndex, 'description');
          },
        ));
      case 4: // Width (MM)
        return DataCell(
          _estimateRows[rowIndex].selectedUnit != null &&
                  ['KitchenFinishTypes', 'BedroomFinishTypes']
                      .contains(_estimateRows[rowIndex].selectedUnit)
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _estimateRows[rowIndex].widthController,
                        focusNode: _estimateRows[rowIndex].widthFocus,
                        decoration: const InputDecoration.collapsed(
                            hintText: '(e.g., =100+20)'),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          _estimateRows[rowIndex].widthInput = value;
                        },
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus(); // Close keyboard

                          setState(() {
                            final input =
                                _estimateRows[rowIndex].widthInput ?? '';
                            final evaluatedValue = evaluateExpression(input);

                            _estimateRows[rowIndex].widthMM = evaluatedValue;
                            _estimateRows[rowIndex].widthController.text =
                                evaluatedValue.toStringAsFixed(2);

                            _calculateKitchenBedroomAmount(rowIndex);
                            _calculateOverallTotal();
                            _saveDraftLocally();
                          });
                          _focusNextField(rowIndex, 'width');
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          'Raw Input: ${_estimateRows[rowIndex].widthInput ?? 'N/A'}',
                      child: IconButton(
                        icon: const Icon(Icons.info,
                            size: 18, color: Colors.grey),
                        onPressed: () {
                          _showEditInputDialog(
                            context: context,
                            title: 'Edit Width Input',
                            initialValue:
                                _estimateRows[rowIndex].widthInput ?? '',
                            onSubmitted: (newValue) {
                              setState(() {
                                _estimateRows[rowIndex].widthInput = newValue;

                                double evaluatedValue =
                                    evaluateExpression(newValue);
                                _estimateRows[rowIndex].widthMM =
                                    evaluatedValue;
                                _estimateRows[rowIndex].widthController.text =
                                    evaluatedValue.toString();

                                _calculateKitchenBedroomAmount(rowIndex);
                                _calculateOverallTotal();
                                _saveDraftLocally();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Text('-'),
        );

      case 5: // Height (MM)
        return DataCell(
          _estimateRows[rowIndex].selectedUnit != null &&
                  ['KitchenFinishTypes', 'BedroomFinishTypes']
                      .contains(_estimateRows[rowIndex].selectedUnit)
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _estimateRows[rowIndex].heightController,
                        focusNode: _estimateRows[rowIndex].heightFocus,
                        decoration: const InputDecoration.collapsed(
                            hintText: '(e.g., =100+20)'),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          _estimateRows[rowIndex].heightInput = value;
                        },
                        onEditingComplete: () {
                          FocusScope.of(context).unfocus(); // Close keyboard

                          setState(() {
                            final input =
                                _estimateRows[rowIndex].heightInput ?? '';
                            final evaluatedValue = evaluateExpression(input);

                            _estimateRows[rowIndex].heightMM = evaluatedValue;
                            _estimateRows[rowIndex].heightController.text =
                                evaluatedValue.toStringAsFixed(2);

                            _calculateKitchenBedroomAmount(rowIndex);
                            _calculateOverallTotal();
                            _saveDraftLocally();
                          });
                          _focusNextField(rowIndex, 'height');
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          'Raw Input: ${_estimateRows[rowIndex].heightInput ?? 'N/A'}',
                      child: IconButton(
                        icon: const Icon(Icons.info,
                            size: 18, color: Colors.grey),
                        onPressed: () {
                          _showEditInputDialog(
                            context: context,
                            title: 'Edit Height Input',
                            initialValue:
                                _estimateRows[rowIndex].heightInput ?? '',
                            onSubmitted: (newValue) {
                              setState(() {
                                _estimateRows[rowIndex].heightInput = newValue;

                                double evaluatedValue =
                                    evaluateExpression(newValue);
                                _estimateRows[rowIndex].heightMM =
                                    evaluatedValue;
                                _estimateRows[rowIndex].heightController.text =
                                    evaluatedValue.toString();

                                _calculateKitchenBedroomAmount(rowIndex);
                                _calculateOverallTotal();
                                _saveDraftLocally();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )
              : const Text('-'),
        );

      case 6: // Width (Feet)
        return DataCell(
          _estimateRows[rowIndex].selectedUnit != null &&
                  ['KitchenFinishTypes', 'BedroomFinishTypes']
                      .contains(_estimateRows[rowIndex].selectedUnit)
              ? Text(
                  '${_estimateRows[rowIndex].widthInFeet.toStringAsFixed(2)} ft')
              : const Text('-'),
        );
      case 7: // Height (Feet)
        return DataCell(
          _estimateRows[rowIndex].selectedUnit != null &&
                  ['KitchenFinishTypes', 'BedroomFinishTypes']
                      .contains(_estimateRows[rowIndex].selectedUnit)
              ? Text(
                  '${_estimateRows[rowIndex].heightInFeet.toStringAsFixed(2)} ft')
              : const Text('-'),
        );
      case 8: // Square Feet
        return DataCell(
          _estimateRows[rowIndex].selectedUnit != null &&
                  ['KitchenFinishTypes', 'BedroomFinishTypes']
                      .contains(_estimateRows[rowIndex].selectedUnit)
              ? Text(
                  '${_estimateRows[rowIndex].squareFeet.toStringAsFixed(2)} sq. ft.')
              : const Text('-'),
        );
      case 9: // Quantity
        return DataCell(
          _estimateRows[rowIndex].selectedUnit != null &&
                  !['KitchenFinishTypes', 'BedroomFinishTypes']
                      .contains(_estimateRows[rowIndex].selectedUnit)
              ? TextField(
                  controller: _estimateRows[rowIndex].quantityController,
                  decoration: const InputDecoration.collapsed(hintText: ''),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _estimateRows[rowIndex].quantity =
                          int.tryParse(value) ?? 0;
                      _calculateOtherItemsAmount(rowIndex);
                      _calculateOverallTotal();
                    });
                  },
                )
              : const Text('-'),
        );
      case 10: // Finish Type (Dropdown for Finish Types)
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex]
                  .availableFinishTypes
                  .containsKey(_estimateRows[rowIndex].selectedFinish)
              ? _estimateRows[rowIndex].selectedFinish
              : null,
          items:
              _estimateRows[rowIndex].availableFinishTypes.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.key),
            );
          }).toList(),
          hint: const Text("Select Finish Type 1"),
          onChanged: (selected) {
            setState(() {
              _estimateRows[rowIndex].selectedFinish = selected;
              _estimateRows[rowIndex].selectedFinishRate =
                  _estimateRows[rowIndex].availableFinishTypes[selected] ?? 0.0;
              _calculateKitchenBedroomAmount(rowIndex);
              _calculateOverallTotal();
              _saveDraftLocally();
            });
          },
        ));

      case 11: // Finish Type 1 Rate
        // Trace the selected finish and its corresponding rate
        final selectedFinish = _estimateRows[rowIndex].selectedFinish;

        // Retrieve the finish rate from availableFinishTypes
        final selectedFinishRate =
            _estimateRows[rowIndex].availableFinishTypes[selectedFinish] ?? 0.0;

        return DataCell(Text('₹${selectedFinishRate.toStringAsFixed(2)}'));

      case 12: // Amount (With GST)
        return DataCell(
          Text(
              '₹${(_estimateRows[rowIndex].amount.roundToDouble()).toStringAsFixed(2)}'),
        );

      case 13: // Total Amount 1 (With GST)
        return DataCell(
          Text('₹${_discountedOverallTotal.toStringAsFixed(2)}'),
        );
      case 14: // Side Panel 1
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex].selectedSidePanel1 != null &&
                  sideOptions
                      .containsKey(_estimateRows[rowIndex].selectedSidePanel1)
              ? _estimateRows[rowIndex].selectedSidePanel1
              : null,
          items: sideOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.key),
            );
          }).toList(),
          hint: const Text("Select Side Panel 1"),
          onChanged: (selected) {
            setState(() {
              _estimateRows[rowIndex].selectedSidePanel1 = selected;
              _estimateRows[rowIndex].sidePanelRate1 =
                  sideOptions[selected!] ?? 0.0;
              _calculateSidePanelAmounts(rowIndex);
            });
          },
        ));
      case 15: // Rate 1
        return DataCell(
          Text('₹${_estimateRows[rowIndex].sidePanelRate1.toStringAsFixed(2)}'),
        );
      case 16: // Quantity 1
        return DataCell(TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration.collapsed(hintText: 'Enter Qty'),
          onChanged: (value) {
            setState(() {
              _estimateRows[rowIndex].sidePanelQuantity1 =
                  int.tryParse(value) ?? 0;
              _calculateSidePanelAmounts(rowIndex);
            });
          },
        ));
      case 17: // Amount 1
        return DataCell(
          Text(
              '₹${_estimateRows[rowIndex].sidePanelAmount1.toStringAsFixed(2)}'),
        );
      case 18: // Finish Type 2
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex]
                  .availableFinishTypes
                  .containsKey(_estimateRows[rowIndex].selectedSecondFinish)
              ? _estimateRows[rowIndex].selectedSecondFinish
              : null,
          items:
              _estimateRows[rowIndex].availableFinishTypes.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.key),
            );
          }).toList(),
          hint: const Text("Select Finish Type 2"),
          onChanged: (selected) {
            setState(() {
              _estimateRows[rowIndex].selectedSecondFinish = selected;
              _estimateRows[rowIndex].selectedFinishRate2 =
                  _estimateRows[rowIndex].availableFinishTypes[selected] ?? 0.0;
              _calculateKitchenBedroomAmount(rowIndex);
              _calculateOverallTotal();
              _saveDraftLocally();
            });
          },
        ));

      case 19: // Finish Type 2 Rate
        final finish2Rate = _estimateRows[rowIndex].availableFinishTypes[
                _estimateRows[rowIndex].selectedSecondFinish] ??
            0.0; // Rate for Finish Type 2
        return DataCell(
          Text('₹${finish2Rate.toStringAsFixed(2)}'),
        );
      case 20: // Amount 2
        return DataCell(
          Text(
              ' ₹${_estimateRows[rowIndex].secondAmount.roundToDouble().toStringAsFixed(2)}'),
        );
      case 21: // Total Amount 2
        return DataCell(
          Text(' ₹${_discountedOverallTotal2.toStringAsFixed(2)}'),
        );
      case 22: // Side Panel 2
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex].selectedSidePanel2 != null &&
                  sideOptions
                      .containsKey(_estimateRows[rowIndex].selectedSidePanel2)
              ? _estimateRows[rowIndex].selectedSidePanel2
              : null,
          items: sideOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.key),
            );
          }).toList(),
          hint: const Text("Select Side Panel 2"),
          onChanged: (selected) {
            setState(() {
              _estimateRows[rowIndex].selectedSidePanel2 = selected;
              _estimateRows[rowIndex].sidePanelRate2 =
                  sideOptions[selected!] ?? 0.0;
              _calculateSidePanelAmounts(rowIndex);
            });
          },
        ));
      case 23: // Rate 2
        return DataCell(
          Text('₹${_estimateRows[rowIndex].sidePanelRate2.toStringAsFixed(2)}'),
        );
      case 24: // Quantity 2
        return DataCell(TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration.collapsed(hintText: 'Enter Qty'),
          onChanged: (value) {
            setState(() {
              _estimateRows[rowIndex].sidePanelQuantity2 =
                  int.tryParse(value) ?? 0;
              _calculateSidePanelAmounts(rowIndex);
            });
          },
        ));
      case 25: // Amount 2

        return DataCell(
          Text(
              '₹${_estimateRows[rowIndex].sidePanelAmount2.toStringAsFixed(2)}'),
        );
      case 26: // Finish Type 3
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex]
                  .availableFinishTypes
                  .containsKey(_estimateRows[rowIndex].selectedThirdFinish)
              ? _estimateRows[rowIndex].selectedThirdFinish
              : null,
          items:
              _estimateRows[rowIndex].availableFinishTypes.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.key),
            );
          }).toList(),
          hint: const Text("Select Finish Type 3"),
          onChanged: (selected) {
            setState(() {
              _estimateRows[rowIndex].selectedThirdFinish = selected;
              _estimateRows[rowIndex].selectedFinishRate3 =
                  _estimateRows[rowIndex].availableFinishTypes[selected] ?? 0.0;
              _calculateKitchenBedroomAmount(rowIndex);
              _calculateOverallTotal();
              _saveDraftLocally();
            });
          },
        ));

      case 27: // Finish Type 3 Rate
        final finish3Rate = _estimateRows[rowIndex].availableFinishTypes[
                _estimateRows[rowIndex].selectedThirdFinish] ??
            0.0; // Rate for Finish Type 3
        return DataCell(
          Text('₹${finish3Rate.toStringAsFixed(2)}'),
        );
      case 28: // Amount 3
        return DataCell(
          Text(
              ' ₹${_estimateRows[rowIndex].thirdAmount.roundToDouble().toStringAsFixed(2)}'),
        );
      case 29: // Total Amount 3
        return DataCell(
          Text(' ₹${_discountedOverallTotal3.toStringAsFixed(2)}'),
        );

      case 30: // Side Panel 3
        return DataCell(DropdownButton<String>(
          value: _estimateRows[rowIndex].selectedSidePanel3 != null &&
                  sideOptions
                      .containsKey(_estimateRows[rowIndex].selectedSidePanel3)
              ? _estimateRows[rowIndex].selectedSidePanel3
              : null,
          items: sideOptions.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.key),
            );
          }).toList(),
          hint: const Text("Select Side Panel 3"),
          onChanged: (selected) {
            setState(() {
              _estimateRows[rowIndex].selectedSidePanel3 = selected;
              _estimateRows[rowIndex].sidePanelRate3 =
                  sideOptions[selected!] ?? 0.0;
              _calculateSidePanelAmounts(rowIndex);
            });
          },
        ));
      case 31: // Rate 3
        return DataCell(
          Text('₹${_estimateRows[rowIndex].sidePanelRate3.toStringAsFixed(2)}'),
        );
      case 32: // Quantity 3
        return DataCell(TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration.collapsed(hintText: 'Enter Qty'),
          onChanged: (value) {
            setState(() {
              _estimateRows[rowIndex].sidePanelQuantity3 =
                  int.tryParse(value) ?? 0;
              _calculateSidePanelAmounts(rowIndex);
            });
          },
        ));
      case 33: // Amount 3
        return DataCell(
          Text(
              '₹${_estimateRows[rowIndex].sidePanelAmount3.toStringAsFixed(2)}'),
        );
      default:
        return const DataCell(Text('-'));
    }
  }

  void _showColumnToggleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Toggle Columns'),
          content: SingleChildScrollView(
            // Add scrollable view here
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_columnVisibility.length, (index) {
                return Row(
                  children: [
                    Checkbox(
                      value: _columnVisibility[index],
                      onChanged: (value) {
                        setState(() {
                          _columnVisibility[index] = value!;
                        });
                        Navigator.of(context).pop();
                        _showColumnToggleDialog(); // Refresh dialog
                      },
                    ),
                    Text(_getColumnName(index)),
                  ],
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _printWoodworkEstimate(BuildContext context) async {
    final pdf = pw.Document();

    // Load the logo image
    final Uint8List logoBytes =
        (await rootBundle.load('assets/Black logo on White-01.jpg'))
            .buffer
            .asUint8List();
    print("Logo loaded successfully!");
    final pw.MemoryImage logo = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Logo Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo,
                    width: 50,
                    height: 50), // Adjust the width and height as needed
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Woodwork Estimate Details',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Generated on: ${DateTime.now().toLocal()}',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),

            // Table Section
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
              children: [
                // Table Header
                pw.TableRow(
                  children: [
                    _buildTableHeader('S.No'),
                    _buildTableHeader('Unit Name'),
                    _buildTableHeader('Description'),
                    _buildTableHeader('Width (MM)'),
                    _buildTableHeader('Height (MM)'),
                    _buildTableHeader('Width (Feet)'),
                    _buildTableHeader('Height (Feet)'),
                    _buildTableHeader('Square Feet'),
                    _buildTableHeader('Quantity'),
                    _buildTableHeader('Finish'),
                    _buildTableHeader('Rate'),
                    _buildTableHeader('Amount'),
                    _buildTableHeader('Total Amount'),
                    _buildTableHeader('Finish'),
                    _buildTableHeader('Rate'),
                    _buildTableHeader('Amount'),
                    _buildTableHeader('Total Amount'),
                    _buildTableHeader('Finish'),
                    _buildTableHeader('Rate'),
                    _buildTableHeader('Amount'),
                    _buildTableHeader('Total Amount'),
                  ],
                ),
                // Table Rows
                ..._estimateRows.map((row) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${row.sNo}'),
                      _buildTableCell(row.selectedUnit ?? 'N/A'),
                      _buildTableCell(row.descriptionController.text),
                      _buildTableCell('${row.widthMM}'),
                      _buildTableCell('${row.heightMM}'),
                      _buildTableCell('${row.widthInFeet}'),
                      _buildTableCell('${row.heightInFeet}'),
                      _buildTableCell('${row.squareFeet}'),
                      _buildTableCell('${row.quantity}'),
                      _buildTableCell(row.selectedFinish ?? 'N/A'),
                      _buildTableCell(
                          '₹${row.selectedFinishRate.toStringAsFixed(2)}'),
                      _buildTableCell('₹${row.baseAmount.toStringAsFixed(2)}'),
                      _buildTableCell('₹${row.amount.toStringAsFixed(2)}'),
                      _buildTableCell(row.selectedSecondFinish ?? 'N/A'),
                      _buildTableCell(
                          '₹${row.selectedFinishRate2.toStringAsFixed(2)}'),
                      _buildTableCell(
                          '₹${row.baseSecondAmount.toStringAsFixed(2)}'),
                      _buildTableCell(
                          '₹${row.secondAmount.toStringAsFixed(2)}'),
                      _buildTableCell(row.selectedThirdFinish ?? 'N/A'),
                      _buildTableCell(
                          '₹${row.selectedFinishRate3.toStringAsFixed(2)}'),
                      _buildTableCell(
                          '₹${row.baseThirdAmount.toStringAsFixed(2)}'),
                      _buildTableCell('₹${row.thirdAmount.toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),

            // Totals Section
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildTotal('Total Amount 1:', _overallTotal),
                _buildTotal('Total Amount 2:', _overallTotal2),
                _buildTotal('Total Amount 3:', _overallTotal3),
              ],
            ),

            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildTotal(
                  'Discounted Total 1:',
                  _discountedOverallTotal,
                  color: PdfColors.green,
                ),
                _buildTotal(
                  'Discounted Total 2:',
                  _discountedOverallTotal2,
                  color: PdfColors.green,
                ),
                _buildTotal(
                  'Discounted Total 3:',
                  _discountedOverallTotal3,
                  color: PdfColors.green,
                ),
              ],
            ),

            pw.SizedBox(height: 16),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Helper Functions
  pw.Widget _buildTableHeader(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 8),
    );
  }

  pw.Widget _buildTotal(String label, double amount, {PdfColor? color}) {
    return pw.Text(
      '$label ₹${amount.toStringAsFixed(2)}',
      style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.black),
    );
  }

  // Helper method to get column names based on index
  String _getColumnName(int index) {
    const columnNames = [
      'S.No',
      'Room',
      'Unit Name',
      'Description',
      'Width (MM)',
      'Height (MM)',
      'Width (Feet)',
      'Height (Feet)',
      'Square Feet',
      'Quantity',
      'Finish Type 1',
      'Rate 1',
      'Amount 1 ',
      'Total Amount 1',
      'Side Panel 1',
      'Rate 1',
      'Quantity 1',
      'Amount-1',
      'Finish Type 2',
      'Rate 2',
      'Amount 2',
      'Total Amount 2',
      'Side Panel 2',
      'Rate 2',
      'Quantity 2',
      'Amount-2',
      'Finish Type 3',
      'Rate 3',
      'Amount 3',
      'Total Amount 3',
      'Side Panel 3',
      'Rate 3',
      'Quantity 3',
      'Amount-3',
    ];
    return index < columnNames.length ? columnNames[index] : 'Unknown Column';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope(
      canPop: false, // Prevent default back unless confirmed
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Don't block actual pop

        bool shouldLeave = await _confirmLeaveDialog();
        if (shouldLeave) {
          Navigator.of(context).pop(result); // Pass back result if needed
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Woodwork Estimate'),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              onPressed: _unhideColumn, // Trigger export
            ),
            // Export Icon
            // IconButton(
            //   icon: const Icon(Icons.download),
            //   onPressed: exportToExcel, // Trigger export
            // ),
            // Import Icon
            IconButton(
              icon: const Icon(Icons.upload),
              onPressed: importFromExcel, // Trigger import
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                _printWoodworkEstimate(context);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (String result) {
                switch (result) {
                  case 'Settings':
                    _showColumnToggleDialog();
                    break;
                  case 'ToggleTransport':
                    setState(() {
                      _isTransportHidden = !_isTransportHidden;
                    });
                    break;
                  case 'ToggleFinish2':
                    setState(() => _showSecondFinish = !_showSecondFinish);
                    break;
                  case 'ToggleFinish3':
                    setState(() => _showThirdFinish = !_showThirdFinish);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Settings',
                  child: Text('Settings'),
                ),
                PopupMenuItem<String>(
                  value: 'ToggleTransport',
                  child: Text(_isTransportHidden
                      ? 'Show Transport Section'
                      : 'Hide Transport Section'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'ToggleFinish2',
                  child: Text('Toggle Finish Type 2 Columns'),
                ),
                const PopupMenuItem<String>(
                  value: 'ToggleFinish3',
                  child: Text('Toggle Finish Type 3 Columns'),
                ),
              ],
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🧾 Left: Customer Info
                        Expanded(
                          flex: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer Info',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                  'Name: ${widget.customerName}'),
                              Text(
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                  'Email: ${widget.customerEmail}'),
                              Text(
                                  style: const TextStyle(
                                    fontSize: 18,
                                  ),
                                  'Phone: ${widget.customerPhone}'),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Totals Summary',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildTotalRow("Total Amount 1", _overallTotal,
                                  Colors.orange),
                              _buildTotalRow("Discounted 1",
                                  _discountedOverallTotal, Colors.green),
                              const SizedBox(height: 12),
                              _buildTotalRow("Total Amount 2", _overallTotal2,
                                  Colors.orange),
                              _buildTotalRow("Discounted 2",
                                  _discountedOverallTotal2, Colors.green),
                              const SizedBox(height: 12),
                              _buildTotalRow("Total Amount 3", _overallTotal3,
                                  Colors.orange),
                              _buildTotalRow("Discounted 3",
                                  _discountedOverallTotal3, Colors.green),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('GST Percentage'),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter GST %',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _gstPercentage =
                                          double.tryParse(value) ?? 0.0;
                                      for (int i = 0;
                                          i < _estimateRows.length;
                                          i++) {
                                        _calculateSidePanelAmounts(i);
                                      }
                                      _calculateOverallTotal();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Discount Percentage'),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 200),
                                child: TextField(
                                  controller: TextEditingController(
                                      text: _discountPercentage.toString()),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter discount %',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      double enteredValue =
                                          double.tryParse(value) ?? 0;
                                      if (enteredValue > _hikePercentage) {
                                        enteredValue = _hikePercentage;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Discount cannot exceed hike ($_hikePercentage%)'),
                                          ),
                                        );
                                      }
                                      _discountPercentage = enteredValue;
                                      _calculateOverallTotal();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),
                        Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!_isTransportHidden) ...[
                                  const Text('Transport Cost'),
                                  const SizedBox(height: 4),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 200),
                                    child: TextField(
                                      controller:
                                          _uniqueTransportCostController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter transport cost',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _transportCost =
                                              double.tryParse(value) ?? 0.0;
                                          _calculateOverallTotal();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (!_isTransportHidden) ...[
                                  const Text('Hike Percentage'),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 200),
                                    child: TextField(
                                      controller: TextEditingController(
                                          text: _hikePercentage.toString()),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: '%',
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _hikePercentage =
                                              double.tryParse(value) ?? 0.0;
                                          _calculateOverallTotal();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            )),

                        // 💰 Right: Totals Section
                      ],
                    ),
                  ),
                ),

                // Estimate Table
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Scrollbar(
                          controller: _verticalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          notificationPredicate: (notif) => notif.depth == 1,
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            scrollDirection: Axis.vertical,
                            child: _estimateRowWidget(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Add Row',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: _addRow, // Adds a new row
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE78B48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_estimateRows.isNotEmpty) {
                            final lastIndex = _estimateRows.length - 1;
                            _duplicateRow(lastIndex);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                          backgroundColor: const Color(0xFF388E3C),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text(
                          'Duplicate Row',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: _saveEstimate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 12.0),
                          backgroundColor: const Color(0xFF388E3C),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text(
                          'Save Estimate',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          SidebarController.of(context)?.openPage(
                            const WoodworkEstimateListPage(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE78B48),
                        ),
                        child: const Text(
                          'Woodwork Estimate List',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => ElectricalEstimatePage(
                      //           customerId: _selectedCustomer!['id'],
                      //           customerName: _selectedCustomer!['name'],
                      //           customerEmail: _selectedCustomer!['email'],
                      //           customerPhone: _selectedCustomer!['phone'],
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   child: const Text('Electrical Estimate'),
                      // ),
                      // Button to delete selected rows
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Delete Selected Rows",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: _deleteSelectedRows,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFBE3D2A),
                        ), // Delete the rows that are selected
                      ),
                      // Button to clear all rows
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.clear_all,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Clear All Rows",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed:
                            _clearAllRows, // Clear all rows from the estimate
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFBE3D2A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 18),
        ),
      ],
    );
  }

  Future<bool> _confirmLeaveDialog() async {
    bool leave = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave without saving?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              leave = false;
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              leave = true;
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave;
  }
}
