const express = require('express');
const bcrypt = require('bcrypt'); // Ensure bcrypt is imported
const jwt = require('jsonwebtoken');
require('dotenv').config();
const PermissionRoleHelper = require('./middlewares/PermissionRoleHelper');
module.exports = (db) => {
  const router = express.Router();

router.post('/user-login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const [userRows] = await db.query(
      'SELECT * FROM users WHERE email = ?', [email]
    );

    if (userRows.length === 0) {
      return res.status(401).json({ error: 'Invalid email' });
    }

    const user = userRows[0];
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid password' });
    }

    // 🔄 Load assigned roles from DB
  const [permResults] = await db.query(`
    SELECT p.permission_name, m.name AS module_name
    FROM user_permissions up
    JOIN permissions p ON up.permission_id = p.id
    JOIN modules m ON p.module_id = m.id
    WHERE up.user_id = ?
  `, [user.id]);

    const permissions = {};
    for (const row of permResults) {
      if (!permissions[row.module_name]) permissions[row.module_name] = [];
      permissions[row.module_name].push(row.permission_name);
    }

    // 🔄 Load moduleRoles from UI selection
    const [roleMappings] = await db.query(`
      SELECT module_name, role_name FROM user_module_roles
      WHERE user_id = ?
    `, [user.id]);

    const moduleRoles = {};
    for (const row of roleMappings) {
      moduleRoles[row.module_name] = row.role_name;
    }

    const token = jwt.sign(
      {
        userId: user.id,
        email: user.email,
        roles: moduleRoles,
        permissions: permissions
      },
      process.env.JWT_SECRET || 'yourSecretKey',
      { expiresIn: '1h' }
    );

    return res.status(200).json({
      message: "Login successful",
      token,
      userId: user.id,
      name: `${user.first_name} ${user.last_name}`,
      permissions,
      moduleRoles
    });

  } catch (err) {
    console.error("Login error:", err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

  return router;
};
