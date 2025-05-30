import 'package:flutter/material.dart';
import '../../widgets/MainScaffold.dart';
import 'TeamListPage.dart';
import 'services/user_service.dart'; // Import the UserService
import 'model/user.dart'; // Import the User model
import 'user_create_page.dart'; // Import the User Create Page

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserService _userService = UserService();
  late Future<List<User>> _userList;
  late Future<List<Map<String, dynamic>>> _teamList;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _userList = _userService.fetchUsers();
  }

  void _refreshTeams() {
    setState(() {
      _teamList = _userService.fetchTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'User List',
      actions: [
        IconButton(
          icon: const Icon(Icons.groups),
          tooltip: 'View Teams',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TeamListPage()),
            );
          },
        ),
      ],
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'addUser',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserCreatePage()),
              );
            },
            tooltip: 'Create User',
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 12),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User List Section
          Expanded(
            flex: 2,
            child: FutureBuilder<List<User>>(
              future: _userList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found'));
                } else {
                  final users = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        child: ListTile(
                          title: Text('${user.firstName} ${user.lastName}'),
                          subtitle: Text('Role: ${user.role}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Deleted ${user.firstName}')),
                              );
                            },
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
