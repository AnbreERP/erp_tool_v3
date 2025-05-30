import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/user_service.dart';

class ManageTeamMembersPage extends StatefulWidget {
  final int teamId;

  const ManageTeamMembersPage(
      {super.key, required this.teamId, required teamName});

  @override
  State<ManageTeamMembersPage> createState() => _ManageTeamMembersPageState();
}

class _ManageTeamMembersPageState extends State<ManageTeamMembersPage> {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> users = [];
  int? selectedUserId;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    fetchTeamMembers();
    fetchAvailableUsers();
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

  Future<void> fetchTeamMembers() async {
    final response = await http.get(
      Uri.parse(
          'http://127.0.0.1:4000/api/user/teams/${widget.teamId}/members'),
    );

    if (response.statusCode == 200) {
      setState(() {
        members = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Failed to fetch team members');
    }
  }

  Future<void> fetchAvailableUsers() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:4000/api/user/all-users'),
    );

    if (response.statusCode == 200) {
      setState(() {
        users = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Failed to fetch all users');
    }
  }

  Future<void> assignUserToTeam() async {
    if (selectedUserId == null) return;

    final response = await http.post(
      Uri.parse(
          'http://127.0.0.1:4000/api/user/teams/${widget.teamId}/add-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': selectedUserId}),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      fetchTeamMembers(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign user')),
      );
    }
  }

  void _confirmRemove(int userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this user from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeUserFromTeam(userId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeUserFromTeam(int userId) async {
    final response = await http.delete(
      Uri.parse(
          'http://127.0.0.1:4000/api/user/teams/${widget.teamId}/remove-user/$userId'),
    );

    if (response.statusCode == 200) {
      fetchTeamMembers(); // refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove user')),
      );
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Member to Team'),
        content: DropdownButtonFormField<int>(
          value: selectedUserId,
          decoration: const InputDecoration(labelText: 'Select User'),
          items: users.map((user) {
            final name = '${user['first_name']} ${user['last_name']}';
            return DropdownMenuItem<int>(
              value: user['id'],
              child: Text(name),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => selectedUserId = val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: assignUserToTeam,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Members to Team ${widget.teamId}'),
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (_, i) {
          final member = members[i];
          final name = '${member['first_name']} ${member['last_name']}';
          return ListTile(
            title: Text(name),
            subtitle: Text(member['email'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              tooltip: 'Remove from team',
              onPressed: () => _confirmRemove(member['id']),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMemberDialog,
        tooltip: 'Add Member',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
