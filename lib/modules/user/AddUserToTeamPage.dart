import 'package:flutter/material.dart';
import 'package:erp_tool/modules/user/services/user_service.dart';

class AddUserToTeamPage extends StatefulWidget {
  final int teamId;
  const AddUserToTeamPage({super.key, required this.teamId});

  @override
  State<AddUserToTeamPage> createState() => _AddUserToTeamPageState();
}

class _AddUserToTeamPageState extends State<AddUserToTeamPage> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = [];
  int? selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users =
        await _userService.fetchUsersAsMap(); // implement this as a map
    setState(() => _users = users);
  }

  Future<void> _assignUser() async {
    if (selectedUserId != null) {
      final success =
          await _userService.assignUserToTeam(selectedUserId!, widget.teamId);
      if (success) {
        Navigator.pop(context, true); // return success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add user to team")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add User to Team')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DropdownButtonFormField<int>(
          value: selectedUserId,
          hint: const Text("Select User"),
          items: _users.map((u) {
            final name = '${u['first_name']} ${u['last_name']}';
            return DropdownMenuItem<int>(
              value: u['id'],
              child: Text(name),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedUserId = val),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _assignUser,
        icon: const Icon(Icons.check),
        label: const Text("Assign"),
      ),
    );
  }
}
