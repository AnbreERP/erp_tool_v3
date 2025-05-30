import 'package:flutter/material.dart';
import 'ManageTeamMembersPage.dart';
import 'TeamCreatePage.dart';
import 'services/user_service.dart';

class TeamListPage extends StatefulWidget {
  const TeamListPage({super.key});

  @override
  State<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  final UserService _userService = UserService();
  late Future<List<Map<String, dynamic>>> _teamList;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  void _loadTeams() {
    _teamList = _userService.fetchTeams();
  }

  void _refreshTeams() {
    setState(() {
      _loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTeams,
            tooltip: 'Refresh Teams',
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _teamList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No teams found'));
          } else {
            final teams = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return Card(
                  child: ListTile(
                    title: Text(team['name'] ?? 'Unnamed Team'),
                    subtitle: Text('Lead: ${team['team_lead_name'] ?? 'None'}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManageTeamMembersPage(
                            teamId: team['id'],
                            teamName: team['name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamCreatePage(
                onTeamCreated: _refreshTeams,
              ),
            ),
          );
        },
        tooltip: 'Create Team',
        child: const Icon(Icons.add),
      ),
    );
  }
}
