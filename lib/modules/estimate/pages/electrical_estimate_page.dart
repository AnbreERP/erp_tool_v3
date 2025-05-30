import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../../../database/e_database_helper.dart';
import '../../../services/customer_database_service.dart';
import '../../../modules/estimate/pages/electrical_estimate_list.dart';
import '../../../widgets/sidebar_menu.dart';
import '../../material/pages/electricalProductList.dart';
import 'package:http/http.dart' as http;

import '../../providers/notification_provider.dart';

class ElectricalEstimatePage extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? estimateData;
  final int customerId;
  final int? estimateId;
  final Map<String, dynamic>? customerInfo;
  final String customerName; // Ensure these are passed correctly
  final String customerEmail;
  final String customerPhone;
  String? status;
  String? stage;

  ElectricalEstimatePage(
      {super.key,
      this.isEditMode = false,
      this.estimateData,
      required this.customerId,
      this.estimateId,
      this.customerInfo,
      required this.customerName,
      required this.customerEmail,
      required this.customerPhone,
      this.status,
      this.stage});
  @override
  _ElectricalEstimatePageState createState() => _ElectricalEstimatePageState();
}

class _ElectricalEstimatePageState extends State<ElectricalEstimatePage> {
// Instantiate correctly
  bool _showBOQColumns = false; // To toggle BOQ columns visibility
  bool _showHikeField = false;
  final TextEditingController transportController = TextEditingController();
  final TextEditingController hikeController = TextEditingController();
  TextEditingController additionalInfoController = TextEditingController();
  TextEditingController quantityController = TextEditingController(text: '0');

  double _grandTotal = 0.0;
  double _transport = 0.0;

  final List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _rows = []; // List of rows
  List<Map<String, dynamic>> _floors = [];
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _descriptions = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _lightTypes = [];
  List<Map<String, dynamic>> _lightDetails = [];

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode && widget.estimateData != null) {
      var estimateSummary = widget.estimateData!['summary'] ?? {};

      hikeController.text = (estimateSummary['hike'] ?? 0).toString();
      transportController.text = (estimateSummary['transport'] ?? 0).toString();
      _grandTotal = estimateSummary['grandTotal'] ?? 0.0;

      // Populate _rows with existing estimate rows
      if (widget.estimateData!.containsKey('rows')) {
        _rows = List<Map<String, dynamic>>.from(widget.estimateData!['rows']);
      }
    } else {
      _addNewRow(); // If new estimate, start with one empty row
      _checkAndPromptDraft();
    }

    _loadFloorsAndRooms();
    _fetchCustomers();
    _fetchDropdownData();
  }

  //auto save
  Future<void> _saveDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> draftData = {
      'hike': hikeController.text,
      'transport': transportController.text,
      'grandTotal': _grandTotal,
      'rows': _rows,
    };

    await prefs.setString('electrical_estimate_draft', jsonEncode(draftData));
    debugPrint("📝 Draft saved locally.");
  }

  Future<void> _restoreDraftIfAvailable() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? draftJson = prefs.getString('electrical_estimate_draft');

    if (draftJson != null) {
      Map<String, dynamic> draft = jsonDecode(draftJson);
      setState(() {
        hikeController.text = draft['hike'] ?? '';
        transportController.text = draft['transport'] ?? '';
        _grandTotal = double.tryParse(draft['grandTotal'].toString()) ?? 0.0;
        _rows = List<Map<String, dynamic>>.from(draft['rows'] ?? []);
      });

      debugPrint("📥 Draft restored successfully.");
      _calculateGrandTotal(); // Recalculate totals after loading
    }
  }

  Future<void> _showRestoreDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore Draft?'),
          content: const Text('A draft was found. Do you want to restore it?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('electrical_estimate_draft');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _restoreDraftIfAvailable(); // Call your restore function here
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndPromptDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('electrical_estimate_draft')) {
      await _showRestoreDialog();
    }
  }

  Future<void> clearDraftLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('quartz_draft');
    debugPrint("🗑️ Quartz draft cleared.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quartz draft cleared.')),
    );
  }

  //end

  // ✅ Fetch all dropdown data dynamically
  void _fetchDropdownData() async {
    try {
      // Fetch descriptions
      _descriptions = await EDatabaseHelper.getDescriptions();

      if (_descriptions.isNotEmpty) {
        int firstDescriptionId = _descriptions.first['descriptionId'];

        // Fetch types based on first available descriptionId
        _types = await EDatabaseHelper.getTypes(firstDescriptionId);

        if (_types.isNotEmpty) {
          int firstTypeId = _types.first['typeId'];

          // Fetch light types based on first available typeId
          _lightTypes = await EDatabaseHelper.getLightTypes(firstTypeId);

          if (_lightTypes.isNotEmpty) {
            int firstLightTypeId = _lightTypes.first['lightTypeId'];

            // Fetch light details based on first available lightTypeId
            _lightDetails =
                await EDatabaseHelper.getLightDetails(firstLightTypeId);
          } else {
            _lightDetails = [];
          }
        } else {
          _lightTypes = [];
          _lightDetails = [];
        }
      } else {
        _types = [];
        _lightTypes = [];
        _lightDetails = [];
      }

      setState(() {}); // ✅ Update UI after fetching all data
    } catch (e) {
      print("Error fetching dropdown data: $e");
    }
  }

  // Fetch customer data from database
  Future<void> _fetchCustomers() async {
    try {
      final dbService = CustomerDatabaseService();
      final response = await dbService.fetchCustomers();
      setState(() {
        _customers.clear();
        _customers.addAll(response['customers']);
      });
    } catch (e) {
      _showErrorSnackBar('Error fetching customers.');
    }
  }

  // Method to load floors and rooms from database for dropdowns
  _loadFloorsAndRooms() async {
    // Load floors and rooms data here (you can update to fetch actual data)
    setState(() {
      _floors = [
        {'id': 1, 'name': 'Ground Floor'},
        {'id': 2, 'name': 'First Floor'},
        {'id': 3, 'name': 'Second Floor'},
        {'id': 4, 'name': 'Third Floor'},
        {'id': 5, 'name': 'Terrace'},
      ];
      _rooms = [
        {'id': 1, 'name': 'Hall'},
        {'id': 2, 'name': 'Bedroom-1'},
        {'id': 3, 'name': 'Bedroom-2'},
        {'id': 4, 'name': 'Bedroom-3'},
        {'id': 5, 'name': 'Balcony'},
        {'id': 6, 'name': 'Stair Case'},
        {'id': 7, 'name': 'Kitchen'},
        {'id': 8, 'name': 'Pooja room'},
        {'id': 9, 'name': 'Dining Room'},
        {'id': 10, 'name': 'Bathroom'},
        {'id': 11, 'name': 'Store Room'},
      ];
    });
  }

  // Method to add a new row to the table
  _addNewRow() {
    setState(() {
      _rows.add({
        'floor': null,
        'room': null,
        'additionalInfo': '',
        'description': null,
        'type': null,
        'lightType': null,
        'lightDetails': null,
        'quantity': 0,
        'materialRate': 0.0,
        'labourRate': 0.0,
        'totalAmount': 0.0,
        'netAmount': 0.0,
        'boqMaterialRate': 0.0,
        'boqLabourRate': 0.0,
        'boqTotalAmount': 0.0,
      });
    });
  }

  // Clear all rows in the table
  void _clearAllRows() {
    setState(() {
      _rows.clear();
    });
  }

  // Calculation function
  _calculateRow(int index) {
    setState(() {
      double qty = _rows[index]['quantity'];
      double materialRate = _rows[index]['materialRate'];
      double labourRate = _rows[index]['labourRate'];
      double boqMaterialRate = _rows[index]['boqMaterialRate'];
      double boqLabourRate = _rows[index]['boqLabourRate'];
      double hikePercentage = double.tryParse(hikeController.text) ?? 0;

      if (hikePercentage <= 20) {
        hikePercentage = 20;
      }

      _rows[index]['totalAmount'] = qty * (materialRate + labourRate);
      _rows[index]['netAmount'] =
          _rows[index]['totalAmount'] / (1 - hikePercentage / 100);
      _rows[index]['boqTotalAmount'] = qty * (boqMaterialRate + boqLabourRate);

      _calculateGrandTotal();
    });
  }

  void _calculateGrandTotal() {
    try {
      double transport = double.tryParse(transportController.text) ?? 0;
      double hikePercentage = double.tryParse(hikeController.text) ?? 20;
      if (hikePercentage < 20) {
        hikePercentage = 20;
      }
      double totalAmount = 0;
      for (var row in _rows) {
        totalAmount += row['netAmount'] ?? 0;
      }
      setState(() {
        _transport = transport / (1 - hikePercentage / 100);
        _grandTotal = (totalAmount + _transport).ceilToDouble();
      });
    } catch (e) {
      _showErrorSnackBar('Error calculating grand total: $e');
    }
  }

  void _saveEstimateToDatabase() async {
    try {
      const String baseUrl = "http://127.0.0.1:4000/api/e-estimate";
      double latestVersion = 0.0;
      String newVersion = '';

      // Retrieve token and userId from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      int? userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        print('❌ Error: Token or UserId is missing');
        throw Exception("User is not authenticated. Cannot save estimate.");
      }

      // Step 1: Fetch latest version for the customer
      final latestVersionResponse = await http
          .get(Uri.parse("$baseUrl/latest/${widget.customerId}"), headers: {
        'Authorization': 'Bearer $token',
      });

      if (latestVersionResponse.statusCode == 200) {
        var data = jsonDecode(latestVersionResponse.body);
        latestVersion = double.tryParse(data['version'].toString()) ?? 0.0;
      } else {
        throw Exception(
            "Failed to fetch the latest version. Server responded with ${latestVersionResponse.statusCode}");
      }

      // Debugging output
      print(
          "Fetched latest version for customer ${widget.customerId}: $latestVersion");

      // Step 2: Calculate new version number
      if (latestVersion == 0.0) {
        newVersion = "1.1"; // First version if no estimate exists
      } else {
        // Extract major and minor version parts from latestVersion
        List<String> versionParts = latestVersion.toString().split('.');
        int major = int.parse(versionParts[0]); // Extract major version
        int minor = versionParts.length > 1
            ? int.parse(versionParts[1])
            : 0; // Extract minor version

        // Debugging output
        print("Current major: $major, minor: $minor");

        // Increment the minor version by 1 if it's less than 9, else reset minor and increment major
        if (minor >= 9) {
          major += 1; // Increment the major version if minor is 9
          minor = 0; // Reset minor version to 0
        } else {
          minor += 1; // Increment minor version
        }

        // Correct the new version without adding an additional `+1`
        newVersion = "$major.$minor"; // Correct minor version increment

        // Debugging output for new version
        print("New version calculated: $newVersion");
      }

      String getStageFromVersion(String version) {
        int major = int.tryParse(version.split('.').first) ?? 1;
        if (major == 1) return 'Sales';
        if (major == 2) return 'Pre-Designer';
        if (major == 3) return 'Designer';
        return 'Sales';
      }

      String computedStage = getStageFromVersion(newVersion);

      // Prepare estimate rows
      List<Map<String, dynamic>> formattedRows = _rows.map((row) {
        return {
          "floor": row["floor"],
          "room": row["room"],
          "additionalInfo": row["additionalInfo"] ?? "",
          "description": row["descriptionName"] ?? "",
          "type": row["typeName"] ?? "",
          "lightType": row["lightTypeName"] ?? "",
          "lightDetails": row["lightName"] ?? "",
          "quantity": row["quantity"] ?? 0,
          "materialRate": row["materialRate"] ?? 0.0,
          "labourRate": row["labourRate"] ?? 0.0,
          "totalAmount": row["totalAmount"] ?? 0.0,
          "netAmount": row["netAmount"] ?? 0.0,
          "boqMaterialRate": row["boqMaterialRate"] ?? 0.0,
          "boqLabourRate": row["boqLabourRate"] ?? 0.0,
          "boqTotalAmount": row["boqTotalAmount"] ?? 0.0,
        };
      }).toList();

      // Ensure at least one row exists
      if (formattedRows.isEmpty) {
        _showErrorSnackBar("Please add at least one row before saving.");
        return;
      }

      // Prepare estimate data payload
      Map<String, dynamic> estimateData = {
        "customerId": widget.customerId,
        'user_id': userId,
        "customerName": widget.customerInfo!['name'],
        "hike": double.tryParse(hikeController.text) ?? 0.0,
        "transport": double.tryParse(transportController.text) ?? 0.0,
        "grandTotal": _grandTotal,
        "version": newVersion,
        "timestamp": DateTime.now().toIso8601String(),
        'estimateType': 'electrical',
        'status': 'InProgress',
        'stage': computedStage,
        "rows": formattedRows,
      };

      // Send data to API
      final response = await http.post(
        Uri.parse("$baseUrl/save-estimates"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(estimateData),
      );
      await Provider.of<NotificationProvider>(context, listen: false)
          .refreshNotifications();
      if (response.statusCode == 201) {
        jsonDecode(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Estimate saved successfully (Version $newVersion)')),
        );

        // Navigate to estimate details page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ElectricalEstimatesListPage(),
          ),
        );
      } else {
        var errorData = jsonDecode(response.body);
        throw Exception(
            "Failed to save estimate. Error: ${errorData['error']}");
      }
    } catch (e) {
      print('🔥 Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error saving estimate: $e')),
      );
    }
  }

  _updateDropdownSelections(int index, String table, int? parentId) async {
    try {
      if (table == 'Type') {
        _rows[index]['type'] = null;
        _rows[index]['lightType'] = null;
        _rows[index]['lightDetails'] = null;

        _types = await EDatabaseHelper.getTypes(parentId!);
      } else if (table == 'LightType') {
        _rows[index]['lightType'] = null;
        _rows[index]['lightDetails'] = null;

        _lightTypes = await EDatabaseHelper.getLightTypes(parentId!);
      } else if (table == 'LightDetails') {
        _rows[index]['lightDetails'] = null;
        _lightDetails = await EDatabaseHelper.getLightDetails(parentId!);
      }

      setState(() {});
    } catch (e) {
      print("Error updating dropdown selections: $e");
    }
  }

  // Fetch dropdown data for description, type, light type, and light details
  Future<List<Map<String, dynamic>>> _getDropdownData(String table,
      {int? parentId}) async {
    try {
      switch (table) {
        case 'Description':
          return await EDatabaseHelper.getDescriptions(); // ✅ Correct API call
        case 'Type':
          if (parentId == null) return [];
          return await EDatabaseHelper.getTypes(
              parentId); // ✅ Requires valid descriptionId
        case 'LightType':
          if (parentId == null) return [];
          return await EDatabaseHelper.getLightTypes(
              parentId); // ✅ Requires valid typeId
        case 'LightDetails':
          if (parentId == null) return [];
          return await EDatabaseHelper.getLightDetails(
              parentId); // ✅ Requires valid lightTypeId
        default:
          return [];
      }
    } catch (e) {
      print("Error fetching dropdown data from $table: $e");
      return [];
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  TableRow _buildRow(int index) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(
                8.0), // Add padding around the cell content
            child: Text('${index + 1}'),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value:
                  _floors.any((floor) => floor['name'] == _rows[index]['floor'])
                      ? _rows[index]['floor']
                      : null, // ✅ Prevents assertion error
              onChanged: (value) {
                setState(() {
                  _rows[index]['floor'] = value;
                  _saveDraftLocally();
                });
              },
              items: _floors.map((floor) {
                return DropdownMenuItem<String>(
                  value: floor['name'],
                  child: Text(floor['name']),
                );
              }).toList(),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _rooms.any((room) => room['name'] == _rows[index]['room'])
                  ? _rows[index]['room']
                  : null, // ✅ Prevents assertion error
              onChanged: (value) {
                setState(() {
                  _rows[index]['room'] = value;
                  _saveDraftLocally();
                });
              },
              items: _rooms.map((room) {
                return DropdownMenuItem<String>(
                  value: room['name'],
                  child: Text(room['name']),
                );
              }).toList(),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              key: ValueKey('additionalInfo-$index'),
              initialValue: _rows[index]['additionalInfo'] ?? '',
              onChanged: (value) {
                _rows[index]['additionalInfo'] = value;
                _saveDraftLocally();
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getDropdownData('Description'),
              builder: (context, snapshot) {
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const CircularProgressIndicator();
                // }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                List<Map<String, dynamic>> descriptions = snapshot.data ?? [];
                int? selectedDescription = _rows[index]['description'];

                descriptions.any(
                    (desc) => desc['descriptionId'] == selectedDescription);

                return DropdownButtonFormField<int>(
                  value: _rows[index]
                      ['description'], // Ensure it exists in the list
                  onChanged: (value) async {
                    setState(() {
                      _rows[index]['description'] = value;
                      _rows[index]['descriptionName'] =
                          _descriptions.firstWhere((desc) =>
                              desc['descriptionId'] == value)['description'];

                      // Clear dependent fields
                      _rows[index]['type'] = null;
                      _rows[index]['lightType'] = null;
                      _rows[index]['lightDetails'] = null;
                      _saveDraftLocally();
                    });

                    await _updateDropdownSelections(index, 'Type', value);
                  },
                  items: _descriptions.map((desc) {
                    return DropdownMenuItem<int>(
                      value: desc['descriptionId'],
                      child: Text(desc['description']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getDropdownData('Type',
                  parentId: _rows[index]['description']),
              builder: (context, snapshot) {
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const CircularProgressIndicator();
                // }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                List<Map<String, dynamic>> types = snapshot.data ?? [];
                int? selectedType = _rows[index]['type'];

                types.any((t) => t['typeId'] == selectedType);

                return DropdownButtonFormField<int>(
                  value: _types.any((t) => t['typeId'] == _rows[index]['type'])
                      ? _rows[index]['type']
                      : null,
                  onChanged: (value) async {
                    setState(() {
                      _rows[index]['type'] = value;
                      _rows[index]['typeName'] = _types
                          .firstWhere((t) => t['typeId'] == value)['type'];

                      // Clear dependent fields
                      _rows[index]['lightType'] = null;
                      _rows[index]['lightDetails'] = null;
                      _saveDraftLocally();
                    });

                    await _updateDropdownSelections(index, 'LightType', value);
                  },
                  items: _types.map((type) {
                    return DropdownMenuItem<int>(
                      value: type['typeId'],
                      child: Text(type['type']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _rows[index]['type'] != null
                  ? _getDropdownData('LightType',
                      parentId: _rows[index]['type'])
                  : Future.value([]),
              builder: (context, snapshot) {
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const CircularProgressIndicator();
                // }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                List<Map<String, dynamic>> lightTypes = snapshot.data ?? [];
                int? selectedLightType = _rows[index]['lightType'];

                lightTypes.any((lt) => lt['lightTypeId'] == selectedLightType);

                return DropdownButtonFormField<int>(
                  value: _lightTypes.any((lt) =>
                          lt['lightTypeId'] == _rows[index]['lightType'])
                      ? _rows[index]['lightType']
                      : null,
                  onChanged: (value) async {
                    setState(() {
                      _rows[index]['lightType'] = value;
                      _rows[index]['lightTypeName'] = _lightTypes.firstWhere(
                          (lt) => lt['lightTypeId'] == value)['lightType'];

                      // Clear dependent field
                      _rows[index]['lightDetails'] = null;
                      _saveDraftLocally();
                    });

                    await _updateDropdownSelections(
                        index, 'LightDetails', value);
                  },
                  items: _lightTypes.map((lightType) {
                    return DropdownMenuItem<int>(
                      value: lightType['lightTypeId'],
                      child: Text(lightType['lightType']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _rows[index]['lightType'] != null
                  ? _getDropdownData('LightDetails',
                      parentId: _rows[index]['lightType'])
                  : Future.value([]),
              builder: (context, snapshot) {
                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const CircularProgressIndicator();
                // }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                List<Map<String, dynamic>> lightDetails = snapshot.data ?? [];
                int? selectedLightDetail = _rows[index]['lightDetails'];

                lightDetails
                    .any((ld) => ld['lightDetailsId'] == selectedLightDetail);

                return DropdownButtonFormField<int>(
                  value: _lightDetails.any((ld) =>
                          ld['lightDetailsId'] == _rows[index]['lightDetails'])
                      ? _rows[index]['lightDetails']
                      : null,
                  onChanged: (value) {
                    final selectedDetail = _lightDetails.firstWhere(
                      (ld) => ld['lightDetailsId'] == value,
                    );

                    setState(() {
                      _rows[index]['lightDetails'] = value;
                      _rows[index]['lightName'] = selectedDetail['lightName'];

                      // Auto-fill material and labour rates
                      _rows[index]['materialRate'] = double.tryParse(
                              selectedDetail['materialRate'].toString()) ??
                          0.0;
                      _rows[index]['labourRate'] = double.tryParse(
                              selectedDetail['labourRate'].toString()) ??
                          0.0;
                      _rows[index]['boqMaterialRate'] = double.tryParse(
                              selectedDetail['boqMaterialRate'].toString()) ??
                          0.0;
                      _rows[index]['boqLabourRate'] = double.tryParse(
                              selectedDetail['boqLabourRate'].toString()) ??
                          0.0;

                      _calculateRow(index);
                      _saveDraftLocally();
                    });
                  },
                  items: _lightDetails.map((lightDetail) {
                    return DropdownMenuItem<int>(
                      value: lightDetail['lightDetailsId'],
                      child: Text(lightDetail['lightName']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              keyboardType: TextInputType.number,
              key: ValueKey('quantity-$index'),
              initialValue: _rows[index]['quantity']?.toString() ?? '0',
// ✅ Load saved value
              onChanged: (value) {
                setState(() {
                  _rows[index]['quantity'] = double.tryParse(value) ?? 0;
                  _calculateRow(index);
                  _saveDraftLocally();
                });
              },
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(_rows[index]['materialRate'].toString()),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(_rows[index]['labourRate'].toString()),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(_rows[index]['totalAmount'].toString()),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(_rows[index]['netAmount'].toString()),
          ),
        ),
        if (_showBOQColumns) ...[
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(_rows[index]['boqMaterialRate'].toString()),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(_rows[index]['boqLabourRate'].toString()),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(_rows[index]['boqTotalAmount'].toString()),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: _showHikeField,
              onChanged: (value) {
                setState(() {
                  _showHikeField = value;
                  _saveDraftLocally();
                });
              },
              title: const Text('Show Hike and Transport Charges'),
            ),
            if (_showHikeField) ...[
              TextField(
                controller: hikeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hike Charges',
                ),
              ),
              TextField(
                controller: transportController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Transport Charges',
                ),
              ),
            ],
            _buildGrandTotalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Text('Grand Total:',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('₹ ${_grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _buildActionsRow(),
      ],
    );
  }

  // Build actions row (Add Row, Clear All, Save Estimate)
  Widget _buildActionsRow() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ElevatedButton(
            onPressed: _addNewRow,
            child: const Text('Add Row'),
          ),
          ElevatedButton(
            onPressed: _clearAllRows,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ]),
        const SizedBox(
          height: 10,
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          ElevatedButton(
            onPressed: _saveEstimateToDatabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
          ElevatedButton(
            onPressed: () {
              // Using Navigator.push to navigate to the EstimateListPage
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ElectricalEstimatesListPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blueAccent,
            ),
            child: const Text('View Estimates'),
          )
        ]),
      ],
    );
  }

  Widget _buildCustomerSelection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Name: ${widget.customerInfo?['name']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Email: ${widget.customerInfo?['email']}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Phone: ${widget.customerInfo?['phone']}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electrical Estimate'),
        backgroundColor: Colors.orange,
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
              }),
          IconButton(
            icon:
                Icon(_showBOQColumns ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showBOQColumns = !_showBOQColumns;
              });
            },
          ),
          const SizedBox(
            width: 10,
          ),
          IconButton(
            icon: const Icon(Icons.view_list, color: Colors.white),
            onPressed: () {
              SidebarController.of(context)
                  ?.openPage(const ElectricalProductListPage());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Start New False Ceiling Estimation',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCustomerSelection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 300,
                    child: _buildSummarySection(),
                  ),
                ],
              ),
              // Remove child: Column here
              Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal, // Enable horizontal scrolling
                    child: Card(
                      // Wrap the table in a Card for better UI
                      elevation: 5,
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            // Use IntrinsicColumnWidth to auto adjust width based on content
                            0: IntrinsicColumnWidth(),
                            1: IntrinsicColumnWidth(),
                            2: IntrinsicColumnWidth(),
                            3: IntrinsicColumnWidth(),
                            4: IntrinsicColumnWidth(),
                            5: IntrinsicColumnWidth(),
                            6: IntrinsicColumnWidth(),
                            7: IntrinsicColumnWidth(),
                            8: IntrinsicColumnWidth(),
                            9: IntrinsicColumnWidth(),
                            10: IntrinsicColumnWidth(),
                            11: IntrinsicColumnWidth(),
                            12: IntrinsicColumnWidth(),
                            13: IntrinsicColumnWidth(),
                            14: IntrinsicColumnWidth(),
                            15: IntrinsicColumnWidth(),
                          },
                          children: [
                            // Table header
                            TableRow(
                              decoration:
                                  BoxDecoration(color: Colors.grey[300]),
                              // Add header background color
                              children: [
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('S.No',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Floor',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Room',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Additional Info',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Type',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Light Type',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Light Details',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Qty',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Material Rate',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Labour Rate',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Total',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                const TableCell(
                                    child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Net Amount',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                )),
                                if (_showBOQColumns) ...[
                                  const TableCell(
                                      child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('BOQ Material Rate',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  )),
                                  const TableCell(
                                      child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('BOQ Labour Rate',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  )),
                                  const TableCell(
                                      child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('BOQ Total Amount',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  )),
                                ]
                              ],
                            ),
                            // Render rows dynamically
                            for (int i = 0; i < _rows.length; i++) _buildRow(i),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
