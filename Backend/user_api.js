const express = require('express');
const bcrypt = require('bcrypt'); // For password hashing
const jwt = require('jsonwebtoken'); // For JWT token generation (optional)
const authenticateToken = require('./middlewares/authenticateToken');
const checkPermissions = require('./middlewares/checkPermissions');

module.exports = (db) => {
  const router = express.Router(); // Fixed incorrect initialization

  // User Creation API
 router.post('/create', authenticateToken, checkPermissions(['create_user'], db), async (req, res) => {
   console.log("📥 Payload:", req.body);

   const {
     firstName,
     lastName,
     email,
     password,
     roleIds,
     permissions,
     department,
     teamId,
     moduleRoles = {}
   } = req.body;

   const userId = req.user.userId.toString()

   if (!firstName || !lastName || !email || !password || !permissions || !department) {
     console.log("❌ Missing required fields!");
     return res.status(400).json({ error: "Missing required fields" });
   }

   try {
     const passwordHash = await bcrypt.hash(password, 10);

     // ✅ Get or create department
     const [departmentResult] = await db.query('SELECT id FROM departments WHERE name = ?', [department]);
     let departmentId = departmentResult.length ? departmentResult[0].id : null;

     if (!departmentId) {
       const [newDept] = await db.query('INSERT INTO departments (name) VALUES (?)', [department]);
       departmentId = newDept.insertId;
     }

     // ✅ Create user
     const [userResult] = await db.query(`
       INSERT INTO users (first_name, last_name, email, password_hash, department)
       VALUES (?, ?, ?, ?, ?)`,
       [firstName, lastName, email, passwordHash, departmentId]
     );

     const userId = userResult.insertId;

     // ✅ Assign roles if any
     if (Array.isArray(roleIds) && roleIds.length > 0) {
       await db.query('INSERT INTO user_roles (user_id, role_id) VALUES ?', [
         roleIds.map(roleId => [userId, roleId])
       ]);
     }

     // ✅ Assign permissions
     if (Array.isArray(permissions) && permissions.length > 0) {
       await db.query('INSERT INTO user_permissions (user_id, permission_id) VALUES ?', [
         permissions.map(id => [userId, id])
       ]);
     }

     // ✅ Estimate module reporting logic
     const estimateRole = moduleRoles['estimate'];
     if (estimateRole === 'Member' && teamId) {
       // First check for Team Lead
       const [tl] = await db.query(`
         SELECT u.id FROM users u
         JOIN user_permissions up ON u.id = up.user_id
         JOIN permissions p ON up.permission_id = p.id
         WHERE u.team_id = ? AND p.permission_name = 'view_team_estimates'
         LIMIT 1
       `, [teamId]);

       if (tl.length) {
         await db.query('UPDATE users SET report_to = ? WHERE id = ?', [tl[0].id, userId]);
       } else {
         // Else check for Manager
         const [manager] = await db.query(`
           SELECT u.id FROM users u
           JOIN user_permissions up ON u.id = up.user_id
           JOIN permissions p ON up.permission_id = p.id
           WHERE u.team_id = ? AND p.permission_name = 'view_member_estimates'
           LIMIT 1
         `, [teamId]);

         if (manager.length) {
           await db.query('UPDATE users SET report_to = ? WHERE id = ?', [manager[0].id, userId]);
         }
       }
     }

     res.status(201).json({ message: "User created successfully!", userId });

     // ✅ Insert moduleRoles into user_module_roles table
     const roleValues = Object.entries(moduleRoles)
       .filter(([, role]) => role && role !== 'None') // skip "None"
       .map(([module, role]) => [userId, module, role]);

     if (roleValues.length > 0) {
       await db.query(`
         INSERT INTO user_module_roles (user_id, module_name, role_name)
         VALUES ?
       `, [roleValues]);
     }


   } catch (error) {
     console.error('❌ Error creating user:', error);
     res.status(500).json({ error: 'Failed to create user', details: error.message });
   }
 });

  // ✅ NEW: Get All Departments API
  router.get('/departments', async (req, res) => {
    try {
      console.log('Fetching departments...');
      const [departments] = await db.query('SELECT * FROM departments');
      console.log('Departments fetched:', departments);

      res.status(200).json(departments);
    } catch (error) {
      console.error('Error fetching departments:', error);
      res.status(500).json({ error: 'Failed to fetch departments' });
    }
  });

  // Fetch all roles
  router.get('/roles', async (req, res) => {
    try {
      const [roles] = await db.query('SELECT * FROM roles');
      res.status(200).json(roles);
    } catch (error) {
      console.error('Error fetching roles:', error);
      res.status(500).json({ error: 'Failed to fetch roles' });
    }
  });

  // Fetch all permissions
  router.get('/permissions', async (req, res) => {
    try {
      const [permissions] = await db.query('SELECT * FROM permissions');
      res.status(200).json(permissions);
    } catch (error) {
      console.error('Error fetching permissions:', error);
      res.status(500).json({ error: 'Failed to fetch permissions' });
    }
  });

  // Fetch permissions for a specific role
  router.get('/roles/:roleId/permissions', async (req, res) => {
    const roleId = req.params.roleId;

    try {
      const [permissions] = await db.query(`
        SELECT p.id, p.permission_name
        FROM permissions p
        JOIN role_permissions rp ON rp.permission_id = p.id
        WHERE rp.role_id = ?`, [roleId]);

      if (permissions.length === 0) {
        return res.status(404).json({ error: 'No permissions found for this role' });
      }

      res.status(200).json(permissions);
    } catch (error) {
      console.error('Error fetching permissions:', error);
      res.status(500).json({ error: 'Failed to fetch permissions for role' });
    }
  });

  // Fetch all users
  router.get('/all-users', async (req, res) => {
      try {
        console.log("Fetching all users...");
        const [results] = await db.query(`
          SELECT users.id, users.first_name, users.last_name, users.email, GROUP_CONCAT(roles.role_name) AS roles
          FROM users
          LEFT JOIN user_roles ON users.id = user_roles.user_id
          LEFT JOIN roles ON user_roles.role_id = roles.id
          GROUP BY users.id;
        `);

        console.log("Users fetched:", results); // Debugging log
        res.status(200).json(results);
      } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: "Database query failed" });
      }
  });

  // Fetch user by ID
  router.get('/users/:id', async (req, res) => {
    const userId = req.params.id;
    try {
      const [results] = await db.query(`
        SELECT users.id, users.first_name, users.last_name, users.email, GROUP_CONCAT(roles.role_name) AS roles
        FROM users
        LEFT JOIN user_roles ON users.id = user_roles.user_id
        LEFT JOIN roles ON user_roles.role_id = roles.id
        WHERE users.id = ?
        GROUP BY users.id;
      `, [userId]);

      if (results.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.status(200).json(results[0]);
    } catch (error) {
      console.error('Error fetching user:', error);
      res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Update user
router.get('/all-users', async (req, res) => {
    try {
      console.log("Fetching all users...");
      const [results] = await db.query(`
        SELECT
          users.id,
          users.first_name,
          users.last_name,
          users.email,
          COALESCE(GROUP_CONCAT(roles.role_name), 'No Role') AS role -- ✅ Changed "roles" to "role"
        FROM users
        LEFT JOIN user_roles ON users.id = user_roles.user_id
        LEFT JOIN roles ON user_roles.role_id = roles.id
        GROUP BY users.id;
      `);
      res.status(200).json(results);
    } catch (error) {
      console.error('Error fetching users:', error);
      res.status(500).json({ error: "Database query failed" });
    }
});

// GET /api/users?department=Designer
router.get('/users', async (req, res) => {
  const departmentName = req.query.department;

  if (!departmentName) {
    return res.status(400).json({ error: 'Department name is required as a query parameter' });
  }

  try {
    const [users] = await db.query(
      `
      SELECT u.id, u.first_name, u.last_name
      FROM users u
      JOIN departments d ON u.department = d.id
      WHERE LOWER(TRIM(d.name)) = LOWER(TRIM(?))
      `,
      [departmentName]
    );

    res.json({ users });
  } catch (error) {
    console.error('Error fetching users by department:', error);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});
// Example: /api/users?departments=Pre-Designer,Designer
router.get('/users-department', async (req, res) => {
  const departmentsParam = req.query.departments;
  console.log("📥 Incoming query:", req.query);
  if (!departmentsParam) {
    return res.status(400).json({ error: 'Departments query parameter is required' });
  }


  const departments = departmentsParam.split(',').map(dep => dep.trim());
  console.log("🔍 Parsed departments array:", departments);

  try {
    const placeholders = departments.map(() => '?').join(', ');
    console.log("🧩 SQL Placeholders:", placeholders);

    const sql = `
      SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) AS name
      FROM users u
      JOIN departments d ON u.department = d.id
      WHERE d.name IN (${placeholders})
    `;

    console.log("📄 Executing SQL:\n", sql);
    console.log("📦 With values:", departments);

    const [users] = await db.query(sql, departments);

    console.log("✅ Users fetched:", users);

    res.json({ users });
  } catch (error) {
    console.error('🔥 Error fetching users by departments:', error);
    res.status(500).json({ error: 'Failed to fetch users', detail: error.message });
  }
});

router.get('/permissions/grouped', async (req, res) => {
    try {
      const [rows] = await db.query(`
        SELECT
          m.name AS module_name,
          p.id AS permission_id,
          p.permission_name
        FROM permissions p
        JOIN modules m ON p.module_id = m.id
        ORDER BY m.name, p.permission_name
      `);

      const grouped = {};

      for (const row of rows) {
        if (!grouped[row.module_name]) {
          grouped[row.module_name] = [];
        }
        grouped[row.module_name].push({
          id: row.permission_id,
          permission_name: row.permission_name
        });
      }

      const result = Object.entries(grouped).map(([module_name, permissions]) => ({
        module_name,
        permissions
      }));

      res.json(result);
    } catch (error) {
      console.error('❌ Failed to fetch grouped permissions:', error);
      res.status(500).json({ error: 'Failed to fetch grouped permissions' });
    }
  });
router.get('/roles/default-permissions/:role', async (req, res) => {
  const role = req.params.role.toLowerCase();

  try {
    const [rows] = await db.query(`
      SELECT id, permission_name FROM permissions
    `);

    const allowed = [];

    for (const row of rows) {
      const [action] = row.permission_name.split('_'); // view, edit, etc.

      if (
        (role === 'super-admin') ||
        (role === 'admin' && action !== 'delete') ||
        (role === 'employee' && (action === 'view' || action === 'create'))
      ) {
        allowed.push(row.id);
      }
    }

    res.json(allowed);
  } catch (err) {
    console.error('🔥 Failed to get role default permissions:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

  router.post('/teams/create', async (req, res) => {
    const { name, team_lead_id, member_ids } = req.body;

    if (!name) return res.status(400).json({ error: 'Team name is required' });

    try {
      const [existing] = await db.query('SELECT * FROM teams WHERE name = ?', [name]);
      if (existing.length > 0) {
        return res.status(409).json({ error: 'Team already exists' });
      }

      const [result] = await db.query(
        'INSERT INTO teams (name, team_lead_id) VALUES (?, ?)',
        [name, team_lead_id || null]
      );

      const teamId = result.insertId;

      // ✅ Add team lead to team_members table
      if (team_lead_id) {
        await db.query(
          'INSERT INTO team_members (team_id, user_id) VALUES (?, ?)',
          [teamId, team_lead_id]
        );
      }

      // ✅ Add members to team_members table
      if (Array.isArray(member_ids)) {
        for (const userId of member_ids) {
          // Avoid duplicate insert if user is also the team lead
          if (userId !== team_lead_id) {
            await db.query(
              'INSERT INTO team_members (team_id, user_id) VALUES (?, ?)',
              [teamId, userId]
            );
          }
        }
      }

      res.status(201).json({ message: 'Team created', teamId });
    } catch (err) {
      console.error('Team creation failed:', err);
      res.status(500).json({ error: 'Failed to create team' });
    }
  });

  router.get('/teams', async (req, res) => {
    try {
      const [teams] = await db.query(`
        SELECT
          t.id,
          t.name,
          t.team_lead_id,
          CONCAT(u.first_name, ' ', u.last_name) AS team_lead_name
        FROM teams t
        LEFT JOIN users u ON t.team_lead_id = u.id
        ORDER BY t.id DESC
      `);

      res.status(200).json(teams);
    } catch (error) {
      console.error("Error fetching teams:", error);
      res.status(500).json({ error: "Failed to load teams" });
    }
  });


router.delete('/teams/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const [users] = await db.query('SELECT id FROM users WHERE team_id = ?', [id]);
    if (users.length > 0) {
      return res.status(400).json({ error: 'Team has assigned users. Reassign before deleting.' });
    }

    await db.query('DELETE FROM teams WHERE id = ?', [id]);
    res.json({ message: 'Team deleted' });
  } catch (err) {
    console.error('Team deletion error:', err);
    res.status(500).json({ error: 'Failed to delete team' });
  }
});

router.put('/user/:userId/team', async (req, res) => {
  const { userId } = req.params;
  const { teamId } = req.body;

  if (!teamId) return res.status(400).json({ error: 'teamId is required' });

  try {
    await db.query('UPDATE users SET team_id = ? WHERE id = ?', [teamId, userId]);
    res.json({ message: 'User team updated' });
  } catch (err) {
    console.error('Failed to update user team:', err);
    res.status(500).json({ error: 'Failed to update user team' });
  }
});
router.get('/team/:teamId/structure', async (req, res) => {
  const teamId = req.params.teamId;

  try {
    const [users] = await db.query(`
      SELECT u.id, u.first_name, u.last_name, u.report_to,
             GROUP_CONCAT(p.permission_name) AS permissions
      FROM users u
      LEFT JOIN user_permissions up ON u.id = up.user_id
      LEFT JOIN permissions p ON up.permission_id = p.id
      WHERE u.team_id = ?
      GROUP BY u.id
    `, [teamId]);

    let teamLead = null, manager = null, members = [];

    users.forEach(user => {
      const fullName = `${user.first_name} ${user.last_name}`;
      const perms = user.permissions?.split(',') ?? [];

      if (perms.includes('view_team_estimates')) {
        teamLead = { id: user.id, name: fullName, role: 'Team Lead' };
      } else if (perms.includes('view_member_estimates')) {
        manager = { id: user.id, name: fullName, role: 'Manager' };
      } else {
        members.push({
          id: user.id,
          name: fullName,
          role: 'Member',
          reportsTo: users.find(u => u.id === user.report_to)?.first_name ?? null
        });
      }
    });

    res.json({
      teamId: parseInt(teamId),
      teamLead,
      manager,
      members
    });

  } catch (error) {
    console.error('❌ Error fetching team structure:', error);
    res.status(500).json({ error: 'Failed to fetch team structure' });
  }
});
router.get('/teams/:id/members', async (req, res) => {
  const teamId = req.params.id;

  try {
    const [members] = await db.query(`
      SELECT u.id, u.first_name, u.last_name, u.email
      FROM team_members tm
      JOIN users u ON tm.user_id = u.id
      WHERE tm.team_id = ?
    `, [teamId]);

    res.json(members);
  } catch (err) {
    console.error("Error fetching team members:", err);
    res.status(500).json({ error: "Failed to fetch members" });
  }
});

router.post('/teams/:id/add-user', async (req, res) => {
  const teamId = req.params.id;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'Missing userId' });
  }

  try {
    await db.query(
      `INSERT IGNORE INTO team_members (team_id, user_id) VALUES (?, ?)`,
      [teamId, userId]
    );
    res.json({ message: 'User added to team' });
  } catch (err) {
    console.error("Error assigning user to team:", err);
    res.status(500).json({ error: "Failed to assign user to team" });
  }
});

// POST /api/teams/:id/set-lead
router.post('/teams/:id/set-lead', async (req, res) => {
  const teamId = req.params.id;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  try {
    await db.query(
      'UPDATE teams SET team_lead_id = ? WHERE id = ?',
      [userId, teamId]
    );
    res.json({ message: 'Team lead assigned' });
  } catch (err) {
    console.error("Error assigning team lead:", err);
    res.status(500).json({ error: 'Failed to set team lead' });
  }
});
router.get('/teams/:id', async (req, res) => {
  const teamId = req.params.id;
  const [results] = await db.query(`
    SELECT t.*,
           CONCAT(u.first_name, ' ', u.last_name) AS team_lead_name
    FROM teams t
    LEFT JOIN users u ON t.team_lead_id = u.id
    WHERE t.id = ?
  `, [teamId]);

  res.json(results[0]);
});
router.delete('/teams/:teamId/remove-user/:userId', async (req, res) => {
  const { teamId, userId } = req.params;

  try {
    const [result] = await db.query(
      'DELETE FROM team_members WHERE team_id = ? AND user_id = ?',
      [teamId, userId]
    );

    if (result.affectedRows > 0) {
      res.json({ message: 'User removed from team' });
    } else {
      res.status(404).json({ error: 'User not found in this team' });
    }
  } catch (err) {
    console.error('Error removing user from team:', err);
    res.status(500).json({ error: 'Failed to remove user from team' });
  }
});


  return router;
};
