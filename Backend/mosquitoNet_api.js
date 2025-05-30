const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');

module.exports = (db) => {
    const router = express.Router();

    //  Get all mosquitoNet estimates
router.get("/mosquitoNet-estimates", authenticateToken, async (req, res) => {
  const { userId, permissions } = req.user;

  // 🔧 Normalize permission keys
  const normalizedPermissions = {};
  for (const [module, perms] of Object.entries(permissions || {})) {
    normalizedPermissions[module.toLowerCase()] = perms;
  }

  const estimatePerms = normalizedPermissions['estimate'] || [];

  let query = '';
  let params = [];

  try {
    if (estimatePerms.includes('view_all_estimates')) {
      query = 'SELECT * FROM mosquitonet_estimates ORDER BY id DESC';
    } else if (estimatePerms.includes('view_member_estimates')) {
      query = `
        SELECT e.* FROM mosquitonet_estimates e
        JOIN team_members tm ON e.user_id = tm.user_id
        WHERE tm.team_id IN (
          SELECT team_id FROM team_members WHERE user_id = ?
        )
        ORDER BY e.id DESC
      `;
      params = [userId];
    } else if (estimatePerms.includes('view_team_estimates')) {
      query = `
        SELECT * FROM mosquitonet_estimates
        WHERE user_id = ?
        OR user_id IN (
          SELECT tm.user_id FROM team_members tm
          JOIN teams t ON t.id = tm.team_id
          WHERE t.team_lead_id = ?
        )
        ORDER BY id DESC
      `;
      params = [userId, userId];
    } else if (estimatePerms.includes('view_estimate')) {
      query = 'SELECT * FROM mosquitonet_estimates WHERE user_id = ? ORDER BY id DESC';
      params = [userId];
    } else {
      return res.status(403).json({ error: 'Access denied: No estimate permissions' });
    }

    const [results] = await db.query(query, params);
    res.json(results.length > 0 ? results : []);
  } catch (error) {
    console.error("🔥 ERROR: Failed to fetch estimates:", error);
    res.status(500).json({ error: "Database query failed", details: error.message });
  }
});


    // ✅ Fetch a single estimate by ID
router.get("/mosquitoNet-estimates/:id", async (req, res) => {
        try {
            const { id } = req.params;
            const [results] = await db.query("SELECT * FROM mosquitonet_estimates WHERE id = ?", [id]);
            res.json(results.length ? results[0] : {});
        } catch (error) {
            res.status(500).json({ error: "Failed to fetch estimate" });
        }
});

      // Endpoint to create a mosquitoNet estimate (with userId)
router.post("/mosquitoNet-estimates", authenticateToken, async (req, res) => {
            try {
                const { customerId, hike, transport, gst, totalAmount, version, status, stage, estimateType, timestamp } = req.body;
                const userId = req.user.userId; // Get the logged-in user's ID

                if (!customerId || !totalAmount || !version) {
                    return res.status(400).json({ error: "Missing required fields" });
                }

                // Insert the estimate into the database
                const [result] = await db.query(
                    "INSERT INTO mosquitonet_estimates (customerId, hike, gst, totalAmount, version, timestamp, user_id, status, stage, estimateType) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    [customerId, hike, gst, totalAmount, version, timestamp, userId, status, stage, estimateType] // Including userId
                );
                await db.query(
                           `INSERT INTO notifications (user_id, title, message, type)
                            VALUES (?, ?, ?, ?)`,
                           [
                             userId,
                             'Estimate Created',
                             `Estimate ${version} created for customer ID ${customerId}`,
                             'estimate'
                           ]
                         );
                res.status(201).json({
                    id: result.insertId,
                    message: "MosquitoNet estimate added successfully!"
                });

            } catch (error) {
                console.error("🔥 ERROR: Failed to create estimate:", error);
                res.status(500).json({ error: "Failed to create estimate", details: error.message });
            }
});

        // Endpoint to insert mosquitoNet estimate rows (with userId)
router.post("/mosquitoNet-estimate-rows", authenticateToken, async (req, res) => {
            try {
                const { details } = req.body;

                if (!details || !Array.isArray(details) || details.length === 0) {
                    return res.status(400).json({ error: "Invalid or empty details data" });
                }

                // Prepare values for batch insertion
                const query = "INSERT INTO mosquitonet_estimate_row (estimateId, room, window, additional_Info, model, length, height, area, rate, amount) VALUES ?";
                const values = details.map(d => [
                    d.estimateId, d.room, d.window, d.additional_Info, d.model, d.length, d.height, d.area, d.rate, d.amount
                ]);

                // Insert the rows into the database
                await db.query(query, [values]);

                res.status(201).json({ message: "Estimate details saved successfully!" });

            } catch (error) {
                console.error("🔥 ERROR: Failed to save estimate details:", error);
                res.status(500).json({ error: "Failed to save estimate details", details: error.message });
            }
 });


    // ✅ Fetch latest version for frontend use (optional)
  router.get("/latest/:customerId", async (req, res) => {
      try {
          const { customerId } = req.params;

          // Use the correct table name here
          const [rows] = await db.query(
              "SELECT version FROM mosquitoNet_estimates WHERE customerId = ? ORDER BY id DESC LIMIT 1",
              [customerId]
          );

          res.json({ version: rows.length > 0 ? rows[0].version : "0.0" });
      } catch (error) {
          console.error("🔥 ERROR: Failed to fetch latest version:", error);
          res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
      }
  });

    // ✅ Fetch estimate rows
    router.get("/mosquitoNet-estimates-details/:estimateId", async (req, res) => {
        try {
            const { estimateId } = req.params;
            const [rows] = await db.query(
                "SELECT * FROM mosquitonet_estimate_row WHERE estimateId = ?",
                [estimateId]
            );

            res.status(200).json(rows.length > 0 ? rows : { message: "No estimate details found." });
        } catch (error) {
            res.status(500).json({ error: "Failed to fetch estimate details" });
        }
    });

    // ✅ Update mosquitoNet estimate (frontend provides new version)
    router.put("/mosquitoNet-estimates/:id", async (req, res) => {
        try {
            const { id } = req.params;
            const { customerId, hike, transport, gst, totalAmount, version, timestamp } = req.body;

            if (!customerId || !totalAmount || !version) {
                return res.status(400).json({ error: "Missing required fields" });
            }

            const [updateResult] = await db.query(
                "UPDATE mosquitonet_estimates SET customerId = ?, hike = ?, transport = ?, gst = ?, totalAmount = ?, version = ?, timestamp = ? WHERE id = ?",
                [customerId, hike, transport, gst, totalAmount, version, timestamp, id]
            );

            if (updateResult.affectedRows === 0) {
                return res.status(404).json({ error: "Failed to update estimate" });
            }

            res.json({ message: "mosquitoNet estimate updated successfully!" });

        } catch (error) {
            console.error("🔥 ERROR: Failed to update estimate:", error);
            res.status(500).json({ error: "Failed to update estimate", details: error.message });
        }
    });

    // ✅ Delete mosquitoNet estimate
    router.delete("/mosquitoNet-estimates/:id", authenticateToken, async (req, res) => {
        try {
            const { id } = req.params;
            await db.query("DELETE FROM mosquitonet_estimate_row WHERE estimateId = ?", [id]);
            await db.query("DELETE FROM mosquitonet_estimates WHERE id = ?", [id]);
            res.json({ message: "mosquitoNet estimate deleted successfully!" });
        } catch (error) {
            res.status(500).json({ error: "Failed to delete estimate" });
        }
    });

    return router;
};
