const express = require("express");
const jwt = require("jsonwebtoken");
const authenticateToken = require('./middlewares/authenticateToken');
const checkPermissions = require('./middlewares/checkPermissions');

 module.exports = (db) => {
        const router = express.Router();

  // ✅ Get all wallpaper estimates for the logged-in user
  router.get("/wallpaper-estimates", authenticateToken, async (req, res) => {
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
        query = 'SELECT * FROM wallpaper_estimate ORDER BY id DESC';
      } else if (estimatePerms.includes('view_member_estimates')) {
        query = `
          SELECT e.* FROM wallpaper_estimate e
          JOIN team_members tm ON e.user_id = tm.user_id
          WHERE tm.team_id IN (
            SELECT team_id FROM team_members WHERE user_id = ?
          )
          ORDER BY e.id DESC
        `;
        params = [userId];
      } else if (estimatePerms.includes('view_team_estimates')) {
        query = `
          SELECT * FROM wallpaper_estimate
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
        query = 'SELECT * FROM wallpaper_estimate WHERE user_id = ? ORDER BY id DESC';
        params = [userId];
      } else {
        return res.status(403).json({ error: 'Access denied: No estimate permissions' });
      }

      const [results] = await db.query(query, params);
      res.json(results);
    } catch (error) {
      console.error("Failed to fetch wallpaper estimates:", error);
      res.status(500).json({ error: "Database query failed" });
    }
  });

 // ✅ Get estimate details by estimate ID
  router.get('/wallpaper-estimates/:estimateId', authenticateToken, async (req, res) => {
       const estimateId = req.params.estimateId;
       const userId = parseInt(req.user.userId, 10);  // Get the logged-in user's ID

       try {
         // Fetch the estimate and check if it belongs to the logged-in user
         const [estimateRows] = await db.query(
           'SELECT * FROM wallpaper_estimate WHERE id = ? AND user_id = ?',
           [estimateId, userId]
         );

         if (estimateRows.length === 0) {
           return res.status(403).json({ message: 'You are not authorized to access this estimate.' });
         }

         // Fetch the estimate details (rows)
         const [detailRows] = await db.query(
           'SELECT * FROM wallpaper_estimates_row WHERE estimateId = ?',
           [estimateId]
         );

         res.status(200).json({
           estimate: estimateRows[0],
           rows: detailRows
         });
       } catch (error) {
         console.error('Error fetching wallpaper estimate:', error.message);
         res.status(500).json({ error: 'Internal Server Error' });
       }
     });

  router.post("/estimates", authenticateToken, checkPermissions(['create_estimate'], db), async (req, res) => {
       try {
         const { customerId, discount, labour, transportCost, gstPercentage, totalAmount, version, status, stage, estimateType, timestamp } = req.body;

         // Ensure userId is treated as an integer
         const userId = req.user.userId.toString(); // Explicitly parse the userId to an integer

         if (!customerId || !totalAmount || !version || isNaN(userId)) {
           return res.status(400).json({ error: "Missing required fields or invalid userId" });
         }

         // Insert the new estimate into the database with the userId
         const [result] = await db.query(
           "INSERT INTO wallpaper_estimate (customerId, user_id, discount, labour, transportCost, gstPercentage, totalAmount, version, status, stage, estimateType, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
           [customerId, userId, discount, labour, transportCost, gstPercentage, totalAmount, version, status, stage, estimateType, timestamp]
         );
         const estimateId = result.insertId;

         // 🔔 Create notification for estimate creation
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
         res.status(201).json({ id: result.insertId, message: "Wallpaper estimate added successfully!" });

       } catch (error) {
         console.error("🔥 ERROR: Failed to create estimate:", error);
         res.status(500).json({ error: "Failed to create estimate", details: error.message });
       }
     });

 // ✅ Insert wallpaper estimate with row details
 router.post("/estimate-rows", authenticateToken, async (req, res) => {
            try {
                const { details } = req.body;

                if (!details || !Array.isArray(details) || details.length === 0) {
                    return res.status(400).json({ error: "Invalid or empty details data" });
                }

                const query = "INSERT INTO wallpaper_estimates_row (estimateId, room, description, length, height, rate, quantity, amount, primerIncluded) VALUES ?";
                const values = details.map(d => [
                    d.estimateId, d.room, d.description, d.length, d.height, d.rate, d.quantity, d.amount, d.primerIncluded
                ]);

                await db.query(query, [values]);

                res.status(201).json({ message: "Estimate details saved successfully!" });

            } catch (error) {
                console.error("🔥 ERROR: Failed to save estimate details:", error);
                res.status(500).json({ error: "Failed to save estimate details", details: error.message });
            }
        });

// ✅ Fetch latest estimate version for a customer
router.get("/latest/:customerId", async (req, res) => {
            const { customerId } = req.params;

            try {
                if (!customerId) {
                    return res.status(400).json({ error: "Missing customerId" });
                }

                const [rows] = await db.query(
                    "SELECT version FROM wallpaper_estimate WHERE customerId = ? ORDER BY id DESC LIMIT 1",
                    [customerId]
                );

                if (rows.length === 0) {
                    return res.json({ version: "0.0" }); // No estimate found for the customer
                }

                // Return the version of the most recent estimate
                res.json({ version: rows[0].version });
            } catch (error) {
                console.error("🔥 ERROR: Failed to fetch latest version:", error);
                res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
            }
        });

 // ✅ Delete a wallpaper estimate
 router.delete("/wallpaper-estimates/:id", authenticateToken, async (req, res) => {
            const { id } = req.params;

            try {
                // Ensure only the owner (user) of the estimate can delete it
                const [estimateResult] = await db.query(
                    "SELECT * FROM wallpaper_estimate WHERE id = ? AND user_id = ?",
                    [id, req.user.userId] // Ensure the estimate belongs to the logged-in user
                );

                if (estimateResult.length === 0) {
                    return res.status(403).json({ error: "Unauthorized access or estimate not found" });
                }

                // Proceed with deletion
                await db.query("DELETE FROM wallpaper_estimate WHERE id = ?", [id]);
                res.json({ message: "Wallpaper estimate deleted successfully!" });
            } catch (error) {
                console.error("❌ Error deleting estimate:", error.message);
                res.status(500).json({ error: "Failed to delete estimate" });
            }
        });

 return router;

 };
