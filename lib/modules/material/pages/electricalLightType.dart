import 'package:flutter/material.dart';
import '../../../database/e_database_helper.dart';
import '../../../modules/material/pages/electricalLightDetail.dart';
import '../../../widgets/sidebar_menu.dart';

class LightTypePage extends StatefulWidget {
  final int typeId;

  const LightTypePage(this.typeId, {super.key});

  @override
  _LightTypePageState createState() => _LightTypePageState();
}

class _LightTypePageState extends State<LightTypePage> {
  late Future<List<Map<String, dynamic>>> _lightTypesFuture;
  final TextEditingController _lightTypeController = TextEditingController();
  final Set<int> _deletingIds = {}; // Track multiple deletes
  int? _selectedTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _lightTypesFuture = _loadLightTypes();
  }

  Future<List<Map<String, dynamic>>> _loadLightTypes() async {
    try {
      final response = await EDatabaseHelper.getLightTypes(widget.typeId);
      print("Light Types Response: $response"); // ✅ Debugging Log
      return response;
    } catch (e) {
      print("Error fetching Light Types: $e"); // ✅ Debugging Log
      _showSnackbar('Error fetching Light Types: $e');
      return [];
    }
  }

  Future<void> _saveType() async {
    if (_lightTypeController.text.isEmpty) {
      _showSnackbar('Please enter a Light Type');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final typeData = {
        'typeId': widget.typeId,
        'lightType': _lightTypeController.text
      };
      bool success = _selectedTypeId == null
          ? await EDatabaseHelper.addLightType(typeData)
          : await EDatabaseHelper.updateLightType(_selectedTypeId!, typeData);

      if (success) {
        _lightTypeController.clear();
        _selectedTypeId = null;
        setState(() {
          _lightTypesFuture = _loadLightTypes();
        });
        _showSnackbar('Light Type saved successfully');
      } else {
        _showSnackbar('Failed to save Light Type');
      }
    } catch (e) {
      _showSnackbar('Error saving Light Type');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteType(int id) async {
    setState(() => _deletingIds.add(id));

    try {
      bool success = await EDatabaseHelper.deleteLightType(id);
      if (success) {
        setState(() {
          _lightTypesFuture = _loadLightTypes();
        });
        _showSnackbar('Light Type deleted');
      } else {
        _showSnackbar('Failed to delete Light Type');
      }
    } catch (e) {
      _showSnackbar('Error deleting Light Type');
    } finally {
      setState(() => _deletingIds.remove(id));
    }
  }

  void _editType(int id, String type) {
    setState(() {
      _lightTypeController.text = type;
      _selectedTypeId = id;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Light Types')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _lightTypeController,
              decoration: InputDecoration(
                labelText: 'Enter Light Type',
                border: const OutlineInputBorder(),
                suffixIcon: _isSaving
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveType,
              child: Text(_selectedTypeId == null
                  ? 'Save Light Type'
                  : 'Update Light Type'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _lightTypesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                        child: Text('Error loading Light Types'));
                  } else if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('No Light Types found'));
                  }

                  final lightTypes = snapshot.data!;
                  return ListView.builder(
                    itemCount: lightTypes.length,
                    itemBuilder: (context, index) {
                      var type = lightTypes[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('ID: ${type['lightTypeId']}'),
                          subtitle: Text(type['lightType']),
                          onTap: () {
                            SidebarController.of(context)?.openPage(
                              LightDetailsPage(type['lightTypeId']),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editType(
                                    type['lightTypeId'], type['lightType']),
                              ),
                              _deletingIds.contains(type['lightTypeId'])
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteType(type['lightTypeId']),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
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
