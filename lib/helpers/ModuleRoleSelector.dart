import 'package:flutter/material.dart';
import 'package:erp_tool/helpers/permission_role_helper.dart';

class ModuleRoleSelector extends StatelessWidget {
  final Map<String, String> selectedRolesPerModule;
  final void Function(String module, String role) onRoleChanged;

  const ModuleRoleSelector({
    super.key,
    required this.selectedRolesPerModule,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: PermissionRoleHelper.moduleRoleOptions.entries.map((entry) {
        final module = entry.key;
        final roles = entry.value;
        final selectedRole = selectedRolesPerModule[module] ?? 'None';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: InputDecoration(
              labelText: '${capitalize(module)} Role',
              border: const OutlineInputBorder(),
            ),
            items: roles.map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onRoleChanged(module, value);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  String capitalize(String text) {
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }
}
