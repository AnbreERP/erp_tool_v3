const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');

module.exports = (db) => {
  const router = express.Router();

  // ✅ Fetch all False Ceiling estimates
router.get("/false-ceiling-estimates", authenticateToken, async (req, res) => {
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
    console.log("🔍 Fetching false ceiling estimates with permissions...");

    if (estimatePerms.includes('view_all_estimates')) {
      query = 'SELECT * FROM fc_estimates ORDER BY id DESC';
    } else if (estimatePerms.includes('view_member_estimates')) {
      query = `
        SELECT e.* FROM fc_estimates e
        JOIN team_members tm ON e.user_id = tm.user_id
        WHERE tm.team_id IN (
          SELECT team_id FROM team_members WHERE user_id = ?
        )
        ORDER BY e.id DESC
      `;
      params = [userId];
    } else if (estimatePerms.includes('view_team_estimates')) {
      query = `
        SELECT * FROM fc_estimates
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
      query = 'SELECT * FROM fc_estimates WHERE user_id = ? ORDER BY id DESC';
      params = [userId];
    } else {
      return res.status(403).json({ error: 'Access denied: No estimate permissions' });
    }

    const [results] = await db.query(query, params);

    console.log("✅ Query Result:", results);
    res.json(results);
  } catch (err) {
    console.error("❌ Database Query Error:", err);
    res.status(500).json({ error: err.message });
  }
});


router.get("/latest/:customerId", async (req, res) => {
       try {
           const { customerId } = req.params;

           // Query ordered by timestamp for the latest estimate
           const [rows] = await db.query(
               "SELECT version FROM fc_estimates WHERE customerId = ? ORDER BY timestamp DESC LIMIT 1",
               [customerId]
           );

           res.json({ version: rows.length > 0 ? rows[0].version : "0.0" });

       } catch (error) {
           console.error("🔥 ERROR: Failed to fetch latest version:", error);
           res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
       }
   });

  //  Fetch a single False Ceiling estimate by ID
router.get("/false-ceiling-estimates/:id", async (req, res) => {
  try {
    const estimateId = parseInt(req.params.id, 10);

    if (isNaN(estimateId)) {
      console.error("❌ Invalid Estimate ID:", req.params.id);
      return res.status(400).json({ error: "Invalid estimate ID. Must be a number." });
    }

    console.log("🔍 Fetching estimate for ID:", estimateId);

    const [results] = await db.query("SELECT * FROM fc_estimates WHERE id = ?", [estimateId]);

    console.log("🔎 Query Result:", results);

    if (results.length === 0) {
      console.warn("⚠️ No estimate found for ID:", estimateId);
      return res.status(404).json({ error: `Estimate with ID ${estimateId} not found in the database.` });
    }

    console.log(" Estimate Fetched Successfully:", results[0]);
    res.json(results[0]);
  } catch (err) {
    console.error("❌ Database Query Error:", err);
    res.status(500).json({ error: err.message });
  }
});


  // Fetch estimate details including rows
router.get("/estimates/:id/details", async (req, res) => {
  try {
    const estimateId = parseInt(req.params.id, 10);

    if (isNaN(estimateId)) {
      console.error(" Invalid Estimate ID:", req.params.id);
      return res.status(400).json({ error: "Invalid estimate ID. Must be a number." });
    }

    console.log(" Fetching estimate details for ID:", estimateId);

    const [estimateResults] = await db.query("SELECT * FROM fc_estimates WHERE id = ?", [estimateId]);

    if (estimateResults.length === 0) {
      console.warn(" No estimate found for ID:", estimateId);
      return res.status(404).json({ error: `Estimate with ID ${estimateId} not found.` });
    }

    const [rowsResults] = await db.query("SELECT * FROM fc_estimate_row WHERE estimateId = ?", [estimateId]);

    console.log(" Estimate Details Fetched Successfully");
    res.json({
      estimate: estimateResults[0],
      rows: rowsResults,
    });

  } catch (err) {
    console.error(" Database Query Error:", err);
    res.status(500).json({ error: err.message });
  }
});

  // ✅ Insert a new False Ceiling estimate and rows in a single API call
router.post("/save-full-estimate", authenticateToken, async (req, res) => {
  console.log(" Received API Request Body:", JSON.stringify(req.body, null, 2));

  const { customerId, customerName, estimateType, gst, totalAmount, version, timestamp, userId, status, stage, details } = req.body;

  if (!customerId || !customerName || !estimateType || gst == null || !totalAmount || !version || !timestamp || !userId || !details) {
    console.error(" Missing required fields.");
    return res.status(400).json({ error: "Missing required fields." });
  }

  if (!Array.isArray(details) || details.length === 0) {
    console.error(" Invalid details format (not an array):", details);
    return res.status(400).json({ error: "Invalid data format for estimate rows. Expected a non-empty array." });
  }

  console.log(" Estimate details received:", JSON.stringify(details, null, 2));

  try {
    const connection = await db.getConnection();
    await connection.beginTransaction(); //  Start Transaction

    // 🔹 Step 1: Insert into `fc_estimates`
    const [estimateResult] = await connection.query(
      "INSERT INTO fc_estimates (customerId, customerName, estimateType, gst, totalAmount, version, timestamp, user_id, status, stage) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [customerId, customerName, estimateType, gst, totalAmount, version, timestamp, userId, status, stage] // Ensure userId is passed here
    );

    const estimateId = estimateResult.insertId;
    console.log(" Estimate saved with ID:", estimateId);

    // 🔹 Step 2: Insert into `fc_estimate_row`
    const values = details.map((row) => [
      estimateId, row.type, row.description, row.length, row.width,
      row.area, row.quantity, row.rate, row.amount
    ]);

    console.log(" SQL Insert Rows:", JSON.stringify(values, null, 2));

    await connection.query(
      "INSERT INTO fc_estimate_row (estimateId, type, description, length, width, area, quantity, rate, amount) VALUES ?",
      [values]
    );

    console.log(" Estimate rows inserted successfully");

    await connection.commit(); // Commit transaction if everything succeeds
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
    res.status(201).json({ message: "Estimate and rows added successfully", estimateId });
  } catch (err) {
    console.error("❌ Transaction Error:", err);
    if (connection) {
      await connection.rollback(); // ❌ Rollback if error occurs
      connection.release();
    }
    res.status(500).json({ error: err.message });
  }
});

  //  Update an existing False Ceiling estimate
  router.put("/false-ceiling-estimates/:id", (req, res) => {
    const { id } = req.params;
    const { customerName, gst, totalAmount, version } = req.body;

    db.query(
      "UPDATE fc_estimates SET customerName = ?, gst = ?, totalAmount = ?, version = ? WHERE id = ?",
      [customerName, gst, totalAmount, version, id],
      (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "Estimate updated successfully" });
      }
    );
  });

  //  Delete a False Ceiling estimate
  router.delete("/false-ceiling-estimates/:id", authenticateToken, (req, res) => {
    const { id } = req.params
    db.query("DELETE FROM fc_estimates WHERE id = ?", [id], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Estimate deleted successfully" });
    });
  });
router.get("/false-ceiling-estimates/:id/details", authenticateToken, async (req, res) => {
  try {
    const estimateId = parseInt(req.params.id, 10);

    if (isNaN(estimateId)) {
      console.error(" Invalid Estimate ID:", req.params.id);
      return res.status(400).json({ error: "Invalid estimate ID. Must be a number." });
    }

    console.log(" Fetching False Ceiling estimate details for ID:", estimateId);

    // Fetch the main estimate
    const [estimateResults] = await db.query(
      "SELECT * FROM fc_estimates WHERE id = ?",
      [estimateId]
    );

    if (estimateResults.length === 0) {
      console.warn("️ No estimate found for ID:", estimateId);
      return res.status(404).json({ error: `Estimate with ID ${estimateId} not found.` });
    }

    // Fetch related rows
    const [rowsResults] = await db.query(
      "SELECT * FROM fc_estimate_row WHERE estimateId = ?",
      [estimateId]
    );

    console.log(" False Ceiling Estimate and Rows Fetched Successfully");
    res.json({
      estimate: estimateResults[0],
      rows: rowsResults,
    });

  } catch (err) {
    console.error(" Database Query Error:", err);
    res.status(500).json({ error: err.message });
  }
});


  return router;
};
