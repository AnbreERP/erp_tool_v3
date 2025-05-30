import 'package:flutter/material.dart';
import '../../../database/e_database_helper.dart';
import '../../../modules/material/pages/electricalType.dart';
import '../../../widgets/sidebar_menu.dart';

class DescriptionPage extends StatefulWidget {
  const DescriptionPage({super.key});

  @override
  _DescriptionPageState createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  late Future<List<Map<String, dynamic>>> _descriptionsFuture;
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  int? _selectedDescriptionId;
  bool _isSaving = false; // Track save operation
  bool _isDeleting = false; // Track delete operation

  @override
  void initState() {
    super.initState();
    _descriptionsFuture = _loadDescriptions();
  }

  Future<List<Map<String, dynamic>>> _loadDescriptions() async {
    try {
      return await EDatabaseHelper.getDescriptions();
    } catch (e) {
      _showSnackbar('Error fetching descriptions');
      return [];
    }
  }

  Future<void> _saveDescription() async {
    if (_descriptionController.text.isEmpty) {
      _showSnackbar('Please enter a description');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final descriptionData = {'description': _descriptionController.text};
      bool success = _selectedDescriptionId == null
          ? await EDatabaseHelper.addDescription(descriptionData)
          : await EDatabaseHelper.updateDescription(
              _selectedDescriptionId!, descriptionData);

      if (success) {
        _descriptionController.clear();
        _selectedDescriptionId = null;
        setState(() {
          _descriptionsFuture = _loadDescriptions();
        });
        _showSnackbar('Description saved successfully');
      } else {
        _showSnackbar('Failed to save description');
      }
    } catch (e) {
      _showSnackbar('Error saving description');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _editDescription(int id, String description) {
    setState(() {
      _descriptionController.text = description;
      _selectedDescriptionId = id;
    });
  }

  Future<void> _deleteDescription(int id) async {
    setState(() => _isDeleting = true);

    try {
      bool success = await EDatabaseHelper.deleteDescription(id);
      if (success) {
        setState(() {
          _descriptionsFuture = _loadDescriptions();
        });
        _showSnackbar('Description deleted');
      } else {
        _showSnackbar('Failed to delete description');
      }
    } catch (e) {
      _showSnackbar('Error deleting description');
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  void _showSnackbar(String message) {
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Descriptions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Enter Description',
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
              onPressed: _isSaving ? null : _saveDescription,
              child: Text(_selectedDescriptionId == null
                  ? 'Save Description'
                  : 'Update Description'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _descriptionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading descriptions'));
                  } else if (snapshot.data!.isEmpty) {
                    return const Center(child: Text('No descriptions found'));
                  }

                  final descriptions = snapshot.data!;
                  return ListView.builder(
                    itemCount: descriptions.length,
                    itemBuilder: (context, index) {
                      var description = descriptions[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('ID: ${description['descriptionId']}'),
                          subtitle: Text(description['description']),
                          onTap: () {
                            SidebarController.of(context)?.openPage(
                              TypePage(description['descriptionId']),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editDescription(
                                    description['descriptionId'],
                                    description['description']),
                              ),
                              IconButton(
                                icon: _isDeleting
                                    ? const CircularProgressIndicator(strokeWidth: 2)
                                    : const Icon(Icons.delete,
                                        color: Colors.red),
                                onPressed: _isDeleting
                                    ? null
                                    : () => _deleteDescription(
                                        description['descriptionId']),
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
