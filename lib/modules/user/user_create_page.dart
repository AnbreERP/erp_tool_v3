import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:erp_tool/modules/user/services/user_service.dart';
import 'package:erp_tool/helpers/permission_role_helper.dart';

import '../../helpers/ModuleRoleSelector.dart';

class UserCreatePage extends StatefulWidget {
  const UserCreatePage({super.key});

  @override
  _UserCreatePageState createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  final _formKey = GlobalKey<FormState>();

  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String department = '';

  Set<int> selectedPermissionIds = {}; // Final permission IDs
  Map<String, int> allPermissionsByName = {}; // permission_name -> id
  Map<String, String> selectedRolesPerModule = {
    'estimate': 'Member',
    'sales': 'None',
    'purchase': 'None',
    'user': 'None',
    'customer': 'None',
    'material': 'None',
    'reports': 'None',
  };

  List<String> availableDepartments = [];
  List<Map<String, dynamic>> availableTeams = [];
  bool _obscurePassword = true;
  int? selectedTeamId;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    fetchDepartments();
    fetchPermissions();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    try {
      final teams = await _userService
          .fetchTeams(); // must return List<Map<String, dynamic>>
      setState(() {
        availableTeams = teams;
        if (availableTeams.isNotEmpty) {
          selectedTeamId = availableTeams.first['id'];
        }
      });
    } catch (e) {
      print('Error fetching teams: $e');
    }
  }

  Future<void> fetchDepartments() async {
    try {
      List<Map<String, dynamic>> departments =
          await _userService.fetchDepartments();
      setState(() {
        availableDepartments =
            departments.map((dept) => dept['name'] as String).toList();
        if (availableDepartments.isNotEmpty) {
          department = availableDepartments[0];
        }
      });
    } catch (e) {
      print('Error fetching departments: $e');
    }
  }

  Future<void> fetchPermissions() async {
    try {
      final List<Map<String, dynamic>> permissions =
          await _userService.fetchPermissionsWithIds();
      setState(() {
        allPermissionsByName = {
          for (var p in permissions) p['permission_name']: p['id']
        };
      });
    } catch (e) {
      print('Error fetching permissions: $e');
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  void updatePermissionsFromSelectedRoles() {
    final selectedNames = PermissionRoleHelper.getPermissionsFromSelectedRoles(
        selectedRolesPerModule);
    selectedPermissionIds = PermissionRoleHelper.mapPermissionNamesToIds(
            selectedNames, allPermissionsByName)
        .toSet();
  }

  Future<void> saveUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      updatePermissionsFromSelectedRoles();

      if (firstName.isEmpty ||
          lastName.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          department.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields.')),
        );
        return;
      }

      try {
        final success = await _userService.createUser(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          roleIds: [],
          permissions: selectedPermissionIds.toList(),
          department: department,
          // teamId: selectedTeamId,
          moduleRoles: selectedRolesPerModule,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User $firstName created successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create user')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onSaved: (value) => firstName = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter first name' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onSaved: (value) => lastName = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter last name' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onSaved: (value) => email = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter email' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  onSaved: (value) => password = value ?? '',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a password' : null,
                ),
                DropdownButtonFormField<String>(
                  value: department.isEmpty ? null : department,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: availableDepartments.map((dept) {
                    return DropdownMenuItem(value: dept, child: Text(dept));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      department = value ?? 'HR';
                    });
                  },
                ),
                // DropdownButtonFormField<int>(
                //   value: selectedTeamId,
                //   decoration: const InputDecoration(labelText: 'Team'),
                //   items: [
                //     const DropdownMenuItem(value: null, child: Text('None')),
                //     ...availableTeams.map<DropdownMenuItem<int>>((team) {
                //       return DropdownMenuItem(
                //         value: team['id'],
                //         child: Text(team['name']),
                //       );
                //     }).toList(),
                //   ],
                //   onChanged: (val) {
                //     setState(() {
                //       selectedTeamId = val;
                //     });
                //   },
                // ),
                const SizedBox(height: 20),
                const Text('Module Roles:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ModuleRoleSelector(
                  selectedRolesPerModule: selectedRolesPerModule,
                  onRoleChanged: (module, role) {
                    setState(() {
                      selectedRolesPerModule[module] = role;
                      updatePermissionsFromSelectedRoles();
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveUser,
                  child: const Text('Create User'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
