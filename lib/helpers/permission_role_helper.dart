class PermissionRoleHelper {
  /// Module-to-available-roles mapping
  static const Map<String, List<String>> moduleRoleOptions = {
    'sales': ['None', 'Sales Manager', 'Sales Executive'],
    'purchase': ['None', 'Purchase Manager', 'Purchase Staff'],
    'estimate': ['None', 'Admin', 'Manager', 'Team Lead', 'Member'],
    'user': ['None', 'Super Admin', 'Admin', 'User Viewer'],
    'customer': ['None', 'Customer Manager', 'Customer Viewer'],
    'material': ['None', 'Material Manager', 'Material Staff'],
    'reports': ['None', 'Report Admin', 'Report Viewer'],
  };

  /// Role-to-permission names per module
  static const Map<String, Map<String, List<String>>> moduleRolePermissionMap =
      {
    'sales': {
      'Sales Manager': [
        'view_sales',
        'create_sales',
        'edit_sales',
        'view_all_sales'
      ],
      'Sales Executive': ['view_sales', 'create_sales'],
    },
    'purchase': {
      'Purchase Manager': [
        'view_purchase',
        'create_purchase',
        'edit_purchase',
        'view_all_purchases'
      ],
      'Purchase Staff': ['view_purchase', 'create_purchase'],
    },
    'estimate': {
      'Admin': [
        'view_estimate',
        'create_estimate',
        'edit_estimate',
        'delete_estimate',
        'view_all_estimates'
      ],
      'Manager': [
        'view_estimate',
        'create_estimate',
        'edit_estimate',
        'view_member_estimates'
      ],
      'Team Lead': [
        'view_estimate',
        'create_estimate',
        'edit_estimate',
        'view_team_estimates'
      ],
      'Member': ['view_estimate', 'create_estimate'],
    },
    'user': {
      'Super Admin': ['view_user', 'create_user', 'edit_user', 'delete_user'],
      'Admin': ['view_user', 'create_user', 'edit_user'],
      'User Viewer': ['view_user'],
    },
    'customer': {
      'Customer Manager': ['view_customer', 'edit_customer'],
      'Customer Viewer': ['view_customer'],
    },
    'material': {
      'Material Manager': [
        'view_material',
        'create_material',
        'edit_material',
        'delete_material'
      ],
      'Material Staff': ['view_material', 'create_material'],
    },
    'reports': {
      'Report Admin': ['view_reports', 'generate_reports', 'export_reports'],
      'Report Viewer': ['view_reports'],
    },
  };

  /// Get all unique permission names used across all modules
  static List<String> getAllPermissionNames() {
    return moduleRolePermissionMap.values
        .expand((roleMap) => roleMap.values)
        .expand((permList) => permList)
        .toSet()
        .toList();
  }

  /// Given selected module-roles, return all corresponding permission names
  static List<String> getPermissionsFromSelectedRoles(
      Map<String, String> selectedRolesPerModule) {
    final Set<String> allPermissions = {};

    for (final module in selectedRolesPerModule.keys) {
      final role = selectedRolesPerModule[module];
      final moduleMap = moduleRolePermissionMap[module];
      if (role != null &&
          role != 'None' &&
          moduleMap != null &&
          moduleMap.containsKey(role)) {
        allPermissions.addAll(moduleMap[role]!);
      }
    }

    return allPermissions.toList();
  }

  /// Convert permission names to IDs using a map fetched from the backend
  static List<int> mapPermissionNamesToIds(
    List<String> permissionNames,
    Map<String, int> allPermissionsByName,
  ) {
    return permissionNames
        .map((name) => allPermissionsByName[name])
        .whereType<int>()
        .toList();
  }
}
