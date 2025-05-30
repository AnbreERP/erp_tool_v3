import 'package:flutter/material.dart';
import '../../../database/e_database_helper.dart';
import '../../../modules/material/pages/electricalLightType.dart';
import '../../../widgets/sidebar_menu.dart';

class TypePage extends StatefulWidget {
  final int descriptionId;

  const TypePage(this.descriptionId, {super.key});

  @override
  _TypePageState createState() => _TypePageState();
}

class _TypePageState extends State<TypePage> {
  late Future<List<Map<String, dynamic>>> _typesFuture;
  final TextEditingController _typeController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  int? _selectedTypeId;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _typesFuture = _loadTypes();
  }

  Future<List<Map<String, dynamic>>> _loadTypes() async {
    try {
      final response = await EDatabaseHelper.getTypes(widget.descriptionId);
      return response;
    } catch (e) {
      _showSnackbar('Error fetching types');
      return [];
    }
  }

  Future<void> _saveType() async {
    if (_typeController.text.isEmpty) {
      _showSnackbar('Please enter a type');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final typeData = {
        'descriptionId': widget.descriptionId,
        'type': _typeController.text
      };
      bool success = _selectedTypeId == null
          ? await EDatabaseHelper.addType(typeData)
          : await EDatabaseHelper.updateType(_selectedTypeId!, typeData);

      if (success) {
        _typeController.clear();
        _selectedTypeId = null;
        setState(() {
          _typesFuture = _loadTypes();
        });
        _showSnackbar('Type saved successfully');
      } else {
        _showSnackbar('Failed to save type');
      }
    } catch (e) {
      _showSnackbar('Error saving type');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteType(int id) async {
    setState(() => _isDeleting = true);

    try {
      bool success = await EDatabaseHelper.deleteType(id);
      if (success) {
        setState(() {
          _typesFuture = _loadTypes();
        });
        _showSnackbar('Type deleted');
      } else {
        _showSnackbar('Failed to delete type');
      }
    } catch (e) {
      _showSnackbar('Error deleting type');
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  void _editType(int id, String type) {
    setState(() {
      _typeController.text = type;
      _selectedTypeId = id;
    });
  }

  void _showSnackbar(String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Types')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: 'Enter Type',
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
              child:
                  Text(_selectedTypeId == null ? 'Save Type' : 'Update Type'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _typesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading types'));
                  } else if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('No types found'));
                  }

                  final types = snapshot.data!;
                  return ListView.builder(
                    itemCount: types.length,
                    itemBuilder: (context, index) {
                      var type = types[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('ID: ${type['typeId']}'),
                          subtitle: Text(type['type']),
                          onTap: () {
                            SidebarController.of(context)?.openPage(
                              LightTypePage(type['typeId']),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _editType(type['typeId'], type['type']),
                              ),
                              IconButton(
                                icon: _isDeleting
                                    ? const CircularProgressIndicator(strokeWidth: 2)
                                    : const Icon(Icons.delete,
                                        color: Colors.red),
                                onPressed: _isDeleting
                                    ? null
                                    : () => _deleteType(type['typeId']),
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
