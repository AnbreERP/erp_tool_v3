import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LightDetailsPage extends StatefulWidget {
  final int lightTypeId;

  const LightDetailsPage(this.lightTypeId, {super.key});

  @override
  _LightDetailsPageState createState() => _LightDetailsPageState();
}

class _LightDetailsPageState extends State<LightDetailsPage> {
  List<Map<String, dynamic>> _lightDetails = [];
  final TextEditingController _lightNameController = TextEditingController();
  final TextEditingController _materialRateController = TextEditingController();
  final TextEditingController _labourRateController = TextEditingController();
  final TextEditingController _boqMaterialRateController =
      TextEditingController();
  final TextEditingController _boqLabourRateController =
      TextEditingController();
  int?
      _selectedLightDetailId; // To store the selected lightDetailId for updating

  @override
  void initState() {
    super.initState();
    _loadLightDetails();
  }

  Future<void> _loadLightDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/e-estimate/light-details/${widget.lightTypeId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> lightDetails = json.decode(response.body);
        setState(() {
          _lightDetails = List<Map<String, dynamic>>.from(lightDetails);
        });
      } else {
        print('Failed to load light details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching light details: $e');
    }
  }

  Future<void> _saveLightDetail() async {
    if (_lightNameController.text.isEmpty) return;

    try {
      final Map<String, dynamic> lightData = {
        'lightTypeId': widget.lightTypeId,
        'lightName': _lightNameController.text,
        'materialRate': _materialRateController.text,
        'labourRate': _labourRateController.text,
        'boqMaterialRate': _boqMaterialRateController.text,
        'boqLabourRate': _boqLabourRateController.text,
      };

      http.Response response;
      if (_selectedLightDetailId != null) {
        // Update existing light detail
        response = await http.put(
          Uri.parse(
              'http://127.0.0.1:4000/api/e-estimate/light-details/$_selectedLightDetailId'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(lightData),
        );
      } else {
        // Insert new light detail
        response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/e-estimate/light-details'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(lightData),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lightNameController.clear();
        _materialRateController.clear();
        _labourRateController.clear();
        _boqMaterialRateController.clear();
        _boqLabourRateController.clear();
        _selectedLightDetailId = null;
        _loadLightDetails();
      } else {
        throw Exception('Failed to save light detail');
      }
    } catch (e) {
      print('Error saving light detail: $e');
    }
  }

  Future<void> _deleteLightDetail(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:4000/api/light-details/$id'),
      );

      if (response.statusCode == 200) {
        _loadLightDetails();
      } else {
        print('Failed to delete light detail');
      }
    } catch (e) {
      print('Error deleting light detail: $e');
    }
  }

  _editLightDetail(int id, String lightName, String materialRate,
      String labourRate, String boqMaterialRate, String boqLabourRate) {
    _lightNameController.text = lightName;
    _materialRateController.text = materialRate;
    _labourRateController.text = labourRate;
    _boqMaterialRateController.text = boqMaterialRate;
    _boqLabourRateController.text = boqLabourRate;
    _selectedLightDetailId = id; // Set the selected lightDetailId for update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _lightNameController,
              decoration: const InputDecoration(labelText: 'Enter Light Name'),
            ),
            TextField(
              controller: _materialRateController,
              decoration:
                  const InputDecoration(labelText: 'Enter Material Rate'),
            ),
            TextField(
              controller: _labourRateController,
              decoration: const InputDecoration(labelText: 'Enter Labour Rate'),
            ),
            TextField(
              controller: _boqMaterialRateController,
              decoration:
                  const InputDecoration(labelText: 'Enter BOQ Material Rate'),
            ),
            TextField(
              controller: _boqLabourRateController,
              decoration:
                  const InputDecoration(labelText: 'Enter BOQ Labour Rate'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveLightDetail,
              child: Text(
                _selectedLightDetailId == null
                    ? 'Save Light Detail'
                    : 'Update Light Detail',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _lightDetails.length,
                itemBuilder: (context, index) {
                  var lightDetail = _lightDetails[index];
                  return Card(
                    child: ListTile(
                      title: Text(lightDetail['lightName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Material Rate: ${lightDetail['materialRate']}'),
                          Text('Labour Rate: ${lightDetail['labourRate']}'),
                          Text(
                              'BOQ Material Rate: ${lightDetail['boqMaterialRate']}'),
                          Text(
                              'BOQ Labour Rate: ${lightDetail['boqLabourRate']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _editLightDetail(
                                lightDetail['lightDetailsId'],
                                lightDetail['lightName'],
                                lightDetail['materialRate'].toString(),
                                lightDetail['labourRate'].toString(),
                                lightDetail['boqMaterialRate'].toString(),
                                lightDetail['boqLabourRate'].toString(),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteLightDetail(lightDetail['lightDetailsId']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
