import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TeamStructurePage extends StatefulWidget {
  final int teamId;

  const TeamStructurePage({super.key, required this.teamId});

  @override
  _TeamStructurePageState createState() => _TeamStructurePageState();
}

class _TeamStructurePageState extends State<TeamStructurePage> {
  Map<String, dynamic>? teamData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTeamStructure();
  }

  Future<void> fetchTeamStructure() async {
    try {
      final res = await http.get(Uri.parse(
          'http://127.0.0.1:4000/api/team/${widget.teamId}/structure'));
      if (res.statusCode == 200) {
        setState(() {
          teamData = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load team');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildUserCard(
      String label, Map<String, dynamic>? user, IconData icon) {
    if (user == null) return const SizedBox.shrink();
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(icon),
        title: Text("$label: ${user['name']}"),
        subtitle: Text("Role: ${user['role']}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final members = teamData?['members'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Team Structure (ID: ${widget.teamId})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildUserCard(
                '👑 Team Lead', teamData?['teamLead'], Icons.emoji_events),
            buildUserCard(
                '🧑‍💼 Manager', teamData?['manager'], Icons.manage_accounts),
            const SizedBox(height: 20),
            const Text("👥 Members:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...members.map<Widget>((member) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member['name']),
                  subtitle: Text("Reports to: ${member['reportsTo'] ?? '—'}"),
                ),
              );
            }).toList()
          ],
        ),
      ),
    );
  }
}
