const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');

module.exports = (db) => {
  const router = express.Router();


  /** 📌 **Quartz Estimates API** **/
 router.get("/quartz-slab-estimates", authenticateToken, async (req, res) => {
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
       query = 'SELECT * FROM quartz_slab_estimates ORDER BY id DESC';
     } else if (estimatePerms.includes('view_member_estimates')) {
       query = `
         SELECT e.* FROM quartz_slab_estimates e
         JOIN team_members tm ON e.user_id = tm.user_id
         WHERE tm.team_id IN (
           SELECT team_id FROM team_members WHERE user_id = ?
         )
         ORDER BY e.id DESC
       `;
       params = [userId];
     } else if (estimatePerms.includes('view_team_estimates')) {
       query = `
         SELECT * FROM quartz_slab_estimates
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
       query = 'SELECT * FROM quartz_slab_estimates WHERE user_id = ? ORDER BY id DESC';
       params = [userId];
     } else {
       return res.status(403).json({ error: 'Access denied: No estimate permissions' });
     }

     const [results] = await db.query(query, params);
     res.json(results);
   } catch (error) {
     console.error("Failed to fetch quartz slab estimates:", error);
     res.status(500).json({ error: "Database query failed" });
   }
 });


  router.post("/save-estimates", authenticateToken, async (req, res) => {
    try {
      const { customerId, hike, loading, transport, totalAmount, version, estimateType, status, stage, details } = req.body;
      const userId = req.user.userId;

      console.log("Received estimate data:", req.body);
      console.log("User from token:", req.user); // Check if this is populated correctly
      if (!userId) {
        return res.status(400).json({ error: "User ID is missing" });
      }
      if (!customerId || !totalAmount || !version || !details || !userId || !Array.isArray(details)) {
        return res.status(400).json({ error: "Missing required fields or invalid data format." });
      }
      const connection = await db.getConnection();
      await connection.beginTransaction();

      try {
        // Step 1: Insert into quartz_estimates
        const [estimateResult] = await connection.query(
          "INSERT INTO quartz_slab_estimates (customerId, hike, loading, transport, totalAmount, version, estimateType, user_id, status, stage) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          [customerId, hike, loading, transport, totalAmount, version, estimateType, userId, status, stage]  // Ensure userId is passed correctly
        );

        const estimateId = estimateResult.insertId;
        console.log("Estimate saved with ID:", estimateId);

        // Step 2: Insert into quartz_estimate_details
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
            "INSERT INTO quartz_estimate_details (estimateId, description, length, width, area, rate, labour, amount) VALUES ?",
            [detailValues]
          );
          console.log("Estimate details inserted successfully.");
        }

        // Commit the transaction
        await connection.commit();
        connection.release();
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
        await connection.rollback();
        connection.release();
        console.error(" Error during database operation:", error); // Log exact error
        res.status(500).json({ error: "Database operation failed", details: error.message });
      }
    } catch (error) {
      console.error(" Error saving estimate and details:", error);
      res.status(500).json({ error: "Internal server error", details: error.message });
    }
  });

  router.put("/estimates/:id", authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const { customerId, hike, loading, transport, totalAmount, version } = req.body;

      await db.query(
        "UPDATE quartz_slab_estimates SET customerId=?, hike=?, loading=?, transport=?, totalAmount=?, version=? WHERE id=?",
        [customerId, hike, loading, transport, totalAmount, version, id]
      );

      res.status(200).json({ message: "Quartz estimate updated successfully!" });
    } catch (error) {
      res.status(500).json({ error: "Failed to update estimate" });
    }
  });

  router.get("/estimates/:id", authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      const [results] = await db.query("SELECT * FROM quartz_slab_estimates WHERE id = ?", [id]);
      res.json(results.length ? results[0] : {});
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch estimate" });
    }
  });

  router.delete("/estimates/:id", authenticateToken, async (req, res) => {
    try {
      const { id } = req.params;
      await db.query("DELETE FROM quartz_slab_estimates WHERE id = ?", [id]);
      res.json({ message: "Quartz estimate deleted" });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete estimate" });
    }
  });

  /**  **Add Multiple Quartz Estimate Details** **/
  router.post("/estimate-details", authenticateToken, async (req, res) => {
    try {
      const { details } = req.body;

      if (!details || !Array.isArray(details)) {
        return res.status(400).json({ error: "Invalid details data" });
      }

      const query = "INSERT INTO quartz_estimate_details (estimateId, description, length, width, area, rate, labour, amount) VALUES ?";
      const values = details.map((d) => [d.estimateId, d.description, d.length, d.width, d.area, d.rate, d.labour, d.amount]);

      await db.promise().query(query, [values]);

      res.status(201).json({ message: "Estimate details saved successfully!" });
    } catch (error) {
      res.status(500).json({ error: "Failed to save estimate details" });
    }
  });

  /**  Fetch Quartz Estimate Details (Main + Rows) **/
  router.get("/quartz-slab-estimates/:id", authenticateToken, async (req, res) => {
    const { id } = req.params;
    try {
      //  Fetch the main estimate
      const [estimate] = await db.query(
        "SELECT * FROM quartz_slab_estimates WHERE id = ?",
        [id]
      );

      if (!estimate.length) {
        return res.status(404).json({ message: "Estimate not found" });
      }

      //  Fetch the estimate rows/details
      const [estimateRows] = await db.query(
        "SELECT * FROM quartz_estimate_details WHERE estimateId = ?",
        [id]
      );

      res.json({
        estimate: estimate[0], //  Main estimate object
        rows: estimateRows,    // Related estimate rows
      });
    } catch (error) {
      console.error("❌ Failed to fetch estimate:", error);
      res.status(500).json({ error: "Failed to fetch estimate", details: error.message });
    }
  });

  router.get("/quartz-estimates/:estimateId/details", authenticateToken, async (req, res) => {
    try {
      const { estimateId } = req.params;
      console.log(` Fetching details for estimateId: ${estimateId}`);

      //  Validate estimateId
      if (!estimateId || isNaN(estimateId)) {
        return res.status(400).json({ error: "Invalid estimate ID" });
      }

      // Fetch Main Estimate from the correct table
      const [estimate] = await db.query("SELECT * FROM quartz_slab_estimates WHERE id = ?", [estimateId]);

      if (!estimate.length) {
        console.error(`❌ Estimate not found for ID: ${estimateId}`);
        return res.status(404).json({ error: "Estimate not found" });
      }

      //  Fetch Estimate Details (Rows)
      const [rows] = await db.query("SELECT * FROM quartz_estimate_details WHERE estimateId = ?", [estimateId]);

      console.log(" Estimate details fetched successfully!");
      res.json({
        estimate: estimate[0], //  Send main estimate as a single object
        rows: rows, //  Send estimate rows as a list
      });
    } catch (error) {
      console.error(" Internal Server Error:", error);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
  });
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
             console.error(" ERROR: Failed to fetch latest version:", error);
             res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
         }
     });

  return router;
};
