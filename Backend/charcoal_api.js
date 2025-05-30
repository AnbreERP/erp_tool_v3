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
           "SELECT version FROM charcoal_estimate WHERE customerId = ? ORDER BY timestamp DESC LIMIT 1",
           [customerId]
       );

       if (rows.length > 0) {
           res.json({ version: rows[0].version });
       } else {
           res.json({ version: "0.0" }); // Default version if no version exists
       }

   } catch (error) {
       console.error("🔥 ERROR: Failed to fetch latest version:", error);
       res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
   }
});

/** **Charcoal Estimates API** **/
router.get("/charcoal-estimates", authenticateToken, async (req, res) => {
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
      query = 'SELECT * FROM charcoal_estimate ORDER BY id DESC';
    } else if (estimatePerms.includes('view_member_estimates')) {
      query = `
        SELECT e.* FROM charcoal_estimate e
        JOIN team_members tm ON e.user_id = tm.user_id
        WHERE tm.team_id IN (
          SELECT team_id FROM team_members WHERE user_id = ?
        )
        ORDER BY e.id DESC
      `;
      params = [userId];
    } else if (estimatePerms.includes('view_team_estimates')) {
      query = `
        SELECT * FROM charcoal_estimate
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
      query = 'SELECT * FROM charcoal_estimate WHERE user_id = ? ORDER BY id DESC';
      params = [userId];
    } else {
      return res.status(403).json({ error: 'Access denied: No estimate permissions' });
    }

    const [results] = await db.query(query, params);
    res.json(results);
  } catch (error) {
    console.error("Failed to fetch charcoal estimates:", error);
    res.status(500).json({ error: "Database query failed" });
  }
});

router.get("/charcoal-estimates/:id", authenticateToken, async (req, res) => {
   const { id } = req.params;

   try {
     //  Fetch estimate details
     const [estimateResults] = await db.query(
       "SELECT * FROM charcoal_estimate WHERE id = ?",
       [id]
     );

     if (!estimateResults.length) {
       return res.status(404).json({ error: "Estimate not found" });
     }

     //  Fetch related rows
     const [rowResults] = await db.query(
       "SELECT * FROM charcoal_estimate_row WHERE estimateId = ?",
       [id]
     );

     res.json({
       estimate: estimateResults[0],
       rows: rowResults,
     });
   } catch (error) {
     console.error(" Failed to fetch estimate:", error);
     res.status(500).json({ error: "Failed to fetch estimate" });
   }
 });


router.get("/charcoal-estimates/:id/rows", (req, res) => {
    const { id } = req.params;
    db.query("SELECT * FROM charcoal_estimate_row WHERE estimateId = ?", [id], (error, rows) => {
      if (error) return res.status(500).json({ error: "Failed to fetch estimate rows" });
      res.json(rows);
    });
  });

router.post("/charcoal-estimates", authenticateToken, async (req, res) => {
  try {
    console.log(" Received JSON Data:", JSON.stringify(req.body, null, 2));

    const { customerId, hike, totalAmount, gst, discount, version, estimateType, timestamp, rows, userId, status, stage } = req.body;

    let missingFields = [];
    if (!customerId) missingFields.push("customerId");
    if (!hike && hike !== 0) missingFields.push("hike");
    if (!totalAmount) missingFields.push("totalAmount");
    if (!gst && gst !== 0) missingFields.push("gst");
    if (!discount && discount !== 0) missingFields.push("discount");
    if (!version) missingFields.push("version");
    if (!estimateType) missingFields.push("estimateType");
    if (!timestamp) missingFields.push("timestamp");
    if (!userId) missingFields.push("userId"); // Add check for userId
    if (!rows || !Array.isArray(rows) || rows.length === 0) missingFields.push("rows");

    if (missingFields.length > 0) {
      console.error("🚨 Missing required fields:", missingFields);
      return res.status(400).json({ error: "Missing required fields", missingFields });
    }

    console.log(" All fields are present. Proceeding with database insert...");

    // Start transaction
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
      //  Insert into main `charcoal_estimate` table with userId
      const [estimateResult] = await connection.query(
        `INSERT INTO charcoal_estimate
        (customerId, hike, totalAmount, gst, discount, version, estimateType, timestamp, user_id, status, stage)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [customerId, hike, totalAmount, gst, discount, version, estimateType, timestamp, userId, status, stage]
      );

      const estimateId = estimateResult.insertId;
      console.log(" Inserted Estimate ID:", estimateId);

      //  Insert rows into `charcoal_estimate_rows`
      const rowInserts = rows.map(row => [
        estimateId,
        row.description || '',
        row.length || 0.0,
        row.height || 0.0,
        row.rate || 0.0,
        row.laying || 0.0,
        row.area || 0.0,
        row.amount || 0.0,
      ]);

      await connection.query(
        `INSERT INTO charcoal_estimate_row
        (estimateId, description, length, height, rate, laying, area, amount)
        VALUES ?`,
        [rowInserts]
      );

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
      res.status(201).json({ message: "Estimate and rows saved successfully", estimateId });

    } catch (err) {
      await connection.rollback();
      connection.release();
      throw err;
    }

  } catch (error) {
    console.error(" Internal Server Error:", error);
    res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});


router.put("/charcoal-estimates/:id", (req, res) => {
    const { id } = req.params;
    const { hike, totalAmount, gst, discount, estimateType } = req.body;
    db.query(
      "UPDATE charcoal_estimate SET hike = ?, totalAmount = ?, gst = ?, discount = ?, estimateType = ? WHERE id = ?",
      [hike, totalAmount, gst, discount, estimateType, id],
      (error) => {
        if (error) return res.status(500).json({ error: "Failed to update estimate" });
        res.status(200).json({ message: "Charcoal estimate updated successfully!" });
      }
    );
  });

router.delete("/charcoal-estimates/:id", authenticateToken, (req, res) => {
    const { id } = req.params;
    db.query("DELETE FROM charcoal_estimate WHERE id = ?", [id], (error) => {
      if (error) return res.status(500).json({ error: "Failed to delete estimate" });
      res.json({ message: "Charcoal estimate deleted" });
    });
  });

  /**  **Fetch Charcoal Estimate Details (Main + Rows)** **/
router.get("/charcoal-estimates/details/:id", (req, res) => {
    const { id } = req.params;
    db.query("SELECT * FROM charcoal_estimate WHERE id = ?", [id], (error, estimate) => {
      if (error || !estimate.length) return res.status(404).json({ error: "Estimate not found" });
      db.query("SELECT * FROM charcoal_estimate_row WHERE estimateId = ?", [id], (error, rows) => {
        if (error) return res.status(500).json({ error: "Failed to fetch estimate rows" });
        res.json({
          estimate: estimate[0],
          rows: rows,
        });
      });
    });
  });

  /**  **Fetch All Charcoal Estimates with Row Details** **/
router.get("/charcoal-estimates/full", (req, res) => {
    db.query("SELECT * FROM charcoal_estimate", (error, estimates) => {
      if (error) return res.status(500).json({ error: "Failed to fetch charcoal estimates" });
      const estimatePromises = estimates.map((estimate) => {
        return new Promise((resolve, reject) => {
          db.query("SELECT * FROM charcoal_estimate_row WHERE estimateId = ?", [estimate.id], (error, rows) => {
            if (error) return reject(error);
            resolve({ ...estimate, rows });
          });
        });
      });
      Promise.all(estimatePromises)
        .then((fullEstimates) => res.json(fullEstimates))
        .catch((error) => res.status(500).json({ error: "Failed to fetch estimates with details" }));
    });
  });

  return router;
};
