
import 'package:flutter/material.dart';
import 'ManageTeamMembersPage.dart';
import 'services/user_service.dart'; // Import the UserService
import 'model/user.dart'; // Import the User model

class TeamCreatePage extends StatefulWidget {
  final VoidCallback onTeamCreated;
  const TeamCreatePage({super.key, required this.onTeamCreated});

  @override
  State<TeamCreatePage> createState() => _TeamCreatePageState();
}

class _TeamCreatePageState extends State<TeamCreatePage> {
  final _formKey = GlobalKey<FormState>();
  String teamName = '';
  bool isSubmitting = false;
  List<Map<String, dynamic>> users = [];
  List<int> selectedMemberIds = [];
  int? selectedLeadId;

  final UserService _userService = UserService();
  late Future<List<User>> _userList;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final userList = await _userService.fetchUsersAsMap();
      setState(() {
        users = userList;
      });
    } catch (e) {
      print("Error loading users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users')),
      );
    }
  }

  Future<void> saveTeam() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isSubmitting = true);

      _formKey.currentState?.save();
      final createdTeamId = await _userService.createTeam(
        teamName,
        selectedLeadId,
        selectedMemberIds,
      );

      setState(() => isSubmitting = false);

      if (createdTeamId != null) {
        Navigator.pop(context); // close the dialog
        widget.onTeamCreated(); // notify parent to refresh list

        //  navigate after dialog closes
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManageTeamMembersPage(
                teamId: createdTeamId,
                teamName: teamName,
              ),
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create team')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Team'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400, // ✅ Set a fixed width
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Team Name'),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  onSaved: (val) => teamName = val?.trim() ?? '',
                  validator: (val) =>
                      val!.isEmpty ? 'Please enter a team name' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedLeadId,
                  items: users.map((user) {
                    final fullName =
                        '${user['first_name']} ${user['last_name']}';
                    return DropdownMenuItem<int>(
                      value: user['id'],
                      child: Text(fullName),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedLeadId = val),
                  decoration:
                      const InputDecoration(labelText: 'Select Team Lead'),
                  validator: (val) =>
                      val == null ? 'Please select a team lead' : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Team Members',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                SizedBox(
                  height: 150,
                  child: Scrollbar(
                    child: ListView(
                      children: users.map((user) {
                        final userId = user['id'];
                        final fullName =
                            '${user['first_name']} ${user['last_name']}';
                        final isSelected = selectedMemberIds.contains(userId);
                        return CheckboxListTile(
                          title: Text(fullName),
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedMemberIds.add(userId);
                              } else {
                                selectedMemberIds.remove(userId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : saveTeam,
          child: isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
