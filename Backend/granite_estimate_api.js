const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');

module.exports = (db) => {
  const router = express.Router();


router.get("/latest/:customerId", async (req, res) => {
       try {
           const { customerId } = req.params;

           // Query ordered by timestamp for the latest estimate
           const [rows] = await db.query(
               "SELECT version FROM quartz_slab_estimates WHERE customerId = ? ORDER BY timestamp DESC LIMIT 1",
               [customerId]
           );

           res.json({ version: rows.length > 0 ? rows[0].version : "0.0" });

       } catch (error) {
           console.error("🔥 ERROR: Failed to fetch latest version:", error);
           res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
       }
   });
  /**  **Granite Estimates API** **/
  router.get("/granite-estimates", authenticateToken, async (req, res) => {
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
        query = 'SELECT * FROM granite_estimates ORDER BY id DESC';
      } else if (estimatePerms.includes('view_member_estimates')) {
        query = `
          SELECT e.* FROM granite_estimates e
          JOIN team_members tm ON e.user_id = tm.user_id
          WHERE tm.team_id IN (
            SELECT team_id FROM team_members WHERE user_id = ?
          )
          ORDER BY e.id DESC
        `;
        params = [userId];
      } else if (estimatePerms.includes('view_team_estimates')) {
        query = `
          SELECT * FROM granite_estimates
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
        query = 'SELECT * FROM granite_estimates WHERE user_id = ? ORDER BY id DESC';
        params = [userId];
      } else {
        return res.status(403).json({ error: 'Access denied: No estimate permissions' });
      }

      const [results] = await db.query(query, params);
      res.json(results);
    } catch (error) {
      console.error("Failed to fetch granite estimates:", error);
      res.status(500).json({ error: "Database query failed" });
    }
  });


  router.post("/save-full-granite-estimate", authenticateToken, async (req, res) => {
    try {
      const { customerId, hike, loading, transport, totalAmount, version, estimateType, status, stage, details } = req.body;
      const userId = req.user.userId;
      console.log("Received estimate data:", { customerId, hike, loading, transport, totalAmount, version, details });

      // Validate required fields
      if (!customerId || !totalAmount || !version || !details || !userId || !Array.isArray(details)) {
        return res.status(400).json({ error: "Missing required fields or invalid data format." });
      }

      // Start a database transaction
      const connection = await db.getConnection();
      await connection.beginTransaction();

      try {
        // Step 1: Insert into granite_estimates
        const [estimateResult] = await connection.query(
          "INSERT INTO granite_estimates (customerId, hike, loading, transport, totalAmount, version, estimateType, user_id, status, stage) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          [customerId, hike, loading, transport, totalAmount, version, estimateType, userId, status, stage]
        );

        const estimateId = estimateResult.insertId;
        console.log("Estimate saved with ID:", estimateId);

        // Step 2: Insert into granite_estimate_details
        const detailValues = details.map((row) => [
          estimateId,
          row.description,
          row.length,
          row.width,
          row.area,
          row.rate,
          row.labour,
          row.amount,
        ]);

        if (detailValues.length > 0) {
          await connection.query(
            "INSERT INTO granite_estimates_details (estimateId, description, length, width, area, rate, labour, amount) VALUES ?",
            [detailValues]
          );
          console.log("Estimate details inserted successfully.");
        }

        // Commit the transaction
        await connection.commit();
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
          message: "Estimate and details saved successfully.",
          estimateId,
        });
      } catch (error) {
        // Rollback the transaction in case of error
        await connection.rollback();
        console.error("Error during database operation:", error);
        res.status(500).json({ error: "Internal server error", details: error.message });
      } finally {
        connection.release(); // Ensure the connection is always released
      }
    } catch (error) {
      console.error("Error saving estimate and details:", error);
      res.status(500).json({ error: "Internal server error", details: error.message });
    }
  });

  /** 📌 Fetch Granite Estimate Details **/
  router.get("/granite-estimates/:estimateId/details", authenticateToken, async (req, res) => {
    try {
      const { estimateId } = req.params;

      // Fetch main estimate data
      const [estimateResult] = await db.query("SELECT * FROM granite_estimates WHERE id = ?", [estimateId]);

      if (!estimateResult.length) {
        return res.status(404).json({ error: "Estimate not found" });
      }

      const [rowsResult] = await db.query(
        "SELECT * FROM granite_estimates_details WHERE estimateId = ?",
        [estimateId]
      );

      res.json({
        estimate: estimateResult[0],
        rows: rowsResult,
      });
    } catch (error) {
      console.error("Error fetching granite estimate details:", error);
      res.status(500).json({ error: "Failed to fetch estimate details" });
    }
  });

  /** 📌 Fetch Latest Granite Estimate Version for a Customer **/
  router.get("/estimates/latest-version/:customerId", async (req, res) => {
    try {
      const { customerId } = req.params;
      const [results] = await db.query(
        "SELECT MAX(version) AS maxVersion FROM granite_estimates WHERE customerId = ?",
        [customerId]
      );
      const maxVersion = results[0]?.maxVersion || "0.0";
      res.json({ maxVersion });
    } catch (error) {
      res.status(500).json({ error: "Internal server error" });
    }
  });

  /** 📌 Fetch Estimate by ID **/
 router.get("/estimates/:id", async (req, res) => {
   try {
     const { id } = req.params;

     // Fetch main estimate details
     const [estimateResults] = await db.query(
       "SELECT * FROM granite_estimates WHERE id = ?",
       [id]
     );

     // Fetch associated rows
     const [rowResults] = await db.query(
       "SELECT * FROM granite_estimates_details WHERE estimateId = ?",
       [id]
     );

     if (estimateResults.length === 0) {
       return res.status(404).json({ error: "Estimate not found" });
     }

     res.json({
       estimate: estimateResults[0],
       rows: rowResults,
     });
   } catch (error) {
     console.error("❌ Backend error:", error);
     res.status(500).json({ error: "Failed to fetch estimate" });
   }
 });

  /** 📌 Delete Estimate **/
  router.delete("/estimates/:id", authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      await db.query("DELETE FROM granite_estimates WHERE id = ?", [id]);
      res.json({ message: "Granite estimate deleted" });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete estimate" });
    }
  });

  return router;
};
