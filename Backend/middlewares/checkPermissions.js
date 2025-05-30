const checkPermissions = (requiredPermissions, db) => {
  return async (req, res, next) => {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized. Missing user ID.' });
    }

    try {
      // ✅ Fetch all permission names assigned to the user
      const [rows] = await db.query(
        `SELECT p.permission_name
         FROM user_permissions up
         JOIN permissions p ON p.id = up.permission_id
         WHERE up.user_id = ?`,
        [userId]
      );

      const userPermissionNames = rows.map(p => p.permission_name);

      // ✅ Log user permissions for debug
      console.log("🔐 User Permissions:", userPermissionNames);
      console.log("📋 Required Permissions:", requiredPermissions);

      // ✅ Check if all required permissions are present
      const hasAll = requiredPermissions.every(p => userPermissionNames.includes(p));

      if (!hasAll) {
        return res.status(403).json({
          error: 'Access denied. Missing required permission(s).',
          missing: requiredPermissions.filter(p => !userPermissionNames.includes(p))
        });
      }

      next(); // ✅ All good — continue to route handler
    } catch (error) {
      console.error('❌ Permission check failed:', error);
      return res.status(500).json({ error: 'Internal server error during permission check' });
    }
  };
};

module.exports = checkPermissions;
