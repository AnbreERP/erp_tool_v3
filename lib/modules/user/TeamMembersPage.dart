import 'package:flutter/material.dart';
import 'package:erp_tool/modules/user/services/user_service.dart';

import 'AddUserToTeamPage.dart';

class TeamMembersPage extends StatefulWidget {
  final int teamId;
  final String teamName;

  const TeamMembersPage(
      {super.key, required this.teamId, required this.teamName});

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  final UserService _userService = UserService();
  late Future<List<Map<String, dynamic>>> _members;

  @override
  void initState() {
    super.initState();
    _members = _userService.fetchTeamMembers(widget.teamId);
  }

  void _refresh() {
    setState(() {
      _members = _userService.fetchTeamMembers(widget.teamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team: ${widget.teamName}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _members,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final members = snapshot.data!;
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(
                  '${members[i]['first_name']} ${members[i]['last_name']}'),
              subtitle: Text(members[i]['email'] ?? ''),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add User',
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddUserToTeamPage(teamId: widget.teamId),
            ),
          );
          if (added == true) _refresh();
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
