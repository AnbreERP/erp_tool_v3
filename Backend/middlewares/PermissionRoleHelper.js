const moduleRolePermissionMap = {
  estimate: {
    Admin: ['view_estimate', 'create_estimate', 'edit_estimate', 'delete_estimate', 'view_all_estimates'],
    Manager: ['view_estimate', 'create_estimate', 'edit_estimate', 'view_member_estimates'],
    'Team Lead': ['view_estimate', 'create_estimate', 'edit_estimate', 'view_team_estimates'],
    Member: ['view_estimate', 'create_estimate'],
  },
  sales: {
    'Sales Manager': ['view_sales', 'create_sales', 'edit_sales', 'view_all_sales'],
    'Sales Executive': ['view_sales', 'create_sales'],
  },
  purchase: {
    'Purchase Manager': ['view_purchase', 'create_purchase', 'edit_purchase', 'view_all_purchases'],
    'Purchase Staff': ['view_purchase', 'create_purchase'],
  },
  user: {
    'Super Admin': ['view_user', 'create_user', 'edit_user', 'delete_user'],
    'Admin': ['view_user', 'create_user', 'edit_user'],
    'User Viewer': ['view_user'],
  },
  customer: {
    'Customer Manager': ['view_customer', 'edit_customer'],
    'Customer Viewer': ['view_customer'],
  },
  material: {
    'Material Manager': ['view_material', 'create_material', 'edit_material', 'delete_material'],
    'Material Staff': ['view_material', 'create_material'],
  },
  reports: {
    'Report Admin': ['view_reports', 'generate_reports', 'export_reports'],
    'Report Viewer': ['view_reports'],
  },
};

function getModuleRolesFromPermissions(userPermissions = []) {
  const moduleRoles = {};

  for (const [module, roles] of Object.entries(moduleRolePermissionMap)) {
    for (const [role, perms] of Object.entries(roles)) {
      const hasPermission = perms.some(p => userPermissions.includes(p));
      if (hasPermission) {
        moduleRoles[module] = role;
        break;
      }
    }

    if (!moduleRoles[module]) {
      moduleRoles[module] = 'None';
    }
  }

  return moduleRoles;
}

module.exports = {
  moduleRolePermissionMap,
  getModuleRolesFromPermissions,
};
