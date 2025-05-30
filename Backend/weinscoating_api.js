const express = require("express");
const jwt = require('jsonwebtoken');
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');

module.exports = (db) => {
  const router = express.Router();

  /** 📌 **Wainscoting Estimates API** **/
router.get("/estimates", authenticateToken, async (req, res) => {
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
      query = 'SELECT * FROM weinscoating_estimate ORDER BY id DESC';
    } else if (estimatePerms.includes('view_member_estimates')) {
      query = `
        SELECT e.* FROM weinscoating_estimate e
        JOIN team_members tm ON e.user_id = tm.user_id
        WHERE tm.team_id IN (
          SELECT team_id FROM team_members WHERE user_id = ?
        )
        ORDER BY e.id DESC
      `;
      params = [userId];
    } else if (estimatePerms.includes('view_team_estimates')) {
      query = `
        SELECT * FROM weinscoating_estimate
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
      query = 'SELECT * FROM weinscoating_estimate WHERE user_id = ? ORDER BY id DESC';
      params = [userId];
    } else {
      return res.status(403).json({ error: 'Access denied: No estimate permissions' });
    }

    const [results] = await db.query(query, params);
    res.json(results.length ? results : []);
  } catch (error) {
    console.error("🔥 ERROR: Failed to fetch weinscoating estimates:", error);
    res.status(500).json({ error: "Failed to fetch estimates", details: error.message });
  }
});


// GET: Fetch Weinscoating estimate and its rows by ID
router.get("/weinscoating-estimates/:id", async (req, res) => {
  try {
    const estimateId = parseInt(req.params.id, 10);

    if (isNaN(estimateId)) {
      return res.status(400).json({ error: "Invalid estimate ID." });
    }

    // Fetch the main estimate
    const [estimateResults] = await db.query(
      "SELECT * FROM weinscoating_estimate WHERE id = ?",
      [estimateId]
    );

    if (estimateResults.length === 0) {
      return res.status(404).json({ error: "Estimate not found." });
    }

    // Fetch the related estimate rows
    const [rowsResults] = await db.query(
      "SELECT * FROM weinscoating_estimate_row WHERE estimateId = ?",
      [estimateId]
    );

    res.status(200).json({
      estimate: estimateResults[0],
      rows: rowsResults,
    });

  } catch (error) {
    console.error("❌ Error fetching Weinscoating estimate:", error);
    res.status(500).json({ error: "Internal server error." });
  }
});

  router.get("/estimates/:id", async (req, res) => {
    try {
      const { id } = req.params;
      const [results] = await db.query("SELECT * FROM weinscoating_estimate WHERE id = ?", [id]);
      res.json(results.length ? results[0] : {});
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch estimate" });
    }
  });

  router.post("/save-estimate", authenticateToken, async (req, res) => {
    const connection = await db.getConnection(); // ✅ Start transaction
    try {
      await connection.beginTransaction(); // ✅ Start transaction

      // Extract data from request body
      const {
        customerId,
        customerName,
        transportCharges,
        gst,
        totalAmount,
        version,
        estimateType,
        status,
        stage,
        estimateRows
      } = req.body;

      const userId = req.user.userId; // Get the logged-in user's ID from JWT

      // Validate the input fields
      if (!customerId || !totalAmount || !estimateType || !estimateRows || estimateRows.length === 0) {
        return res.status(400).json({ error: "Missing required fields" });
      }

      // ✅ Step 1: Insert the main estimate into `weinscoating_estimate` table
      const [estimateResult] = await connection.query(
        "INSERT INTO weinscoating_estimate (customerId, customerName, transportCharges, gst, totalAmount, version, estimateType, user_id, status, stage) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [customerId, customerName, transportCharges, gst, totalAmount, version, estimateType, userId, status, stage]
      );

      const estimateId = estimateResult.insertId; // ✅ Get the inserted estimate ID

      // ✅ Step 2: Insert estimate rows in bulk into `weinscoating_estimate_row` table
      const rowValues = estimateRows.map(row => [
        estimateId,
        row.description,
        row.length,
        row.width,
        row.area,
        row.rate,
        row.laying,
        row.labour,
        row.amount,
        row.panel
      ]);

      const rowQuery = "INSERT INTO weinscoating_estimate_row (estimateId, description, length, width, area, rate, laying, labour, amount, panel) VALUES ?";
      await connection.query(rowQuery, [rowValues]);

      await connection.commit(); // ✅ Commit the transaction if everything succeeds
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
      res.status(201).json({ message: "Estimate and rows saved successfully", id: estimateId });

    } catch (error) {
      await connection.rollback(); // ❌ Rollback the transaction in case of failure
      console.error("🔥 ERROR: Failed to save estimate:", error);
      res.status(500).json({ error: "Failed to save estimate", details: error.message });
    } finally {
      connection.release(); // ✅ Release the database connection
    }
  });



  router.put("/estimates/:id", async (req, res) => {
    try {
      const { id } = req.params;
      const { customerName, transportCharges, gst, totalAmount, version, estimateType } = req.body;

      await db.promise().query(
        "UPDATE weinscoating_estimate SET customerName = ?, transportCharges = ?, gst = ?, totalAmount = ?, version = ?, estimateType = ? WHERE id = ?",
        [customerName, transportCharges, gst, totalAmount, version, estimateType, id]
      );

      res.status(200).json({ message: "Wainscoting estimate updated successfully!" });
    } catch (error) {
      res.status(500).json({ error: "Failed to update estimate" });
    }
  });

  router.delete("/delete-estimates/:id", async (req, res) => {
      try {
          const { id } = req.params;

          if (!id) {
              return res.status(400).json({ error: "Missing estimate ID" });
          }

          // ✅ Delete from main estimate table
          const [result] = await db.query("DELETE FROM weinscoating_estimate WHERE id = ?", [id]);

          if (result.affectedRows === 0) {
              return res.status(404).json({ error: "Estimate not found" });
          }

          // ✅ Delete related rows from estimate details table
          await db.query("DELETE FROM weinscoating_estimate_row WHERE estimateId = ?", [id]);

          res.json({ message: "Estimate deleted successfully" });

      } catch (error) {
          console.error("🔥 ERROR: Failed to delete estimate:", error);
          res.status(500).json({ error: "Failed to delete estimate", details: error.message });
      }
  });



  router.get("/estimate-rows/:estimateId", async (req, res) => {
    try {
      const { estimateId } = req.params;
      const [rows] = await db.query("SELECT * FROM weinscoating_estimate_row WHERE estimateId = ?", [estimateId]);
      res.json(rows);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch estimate rows" });
    }
  });
   router.get("/latest/:customerId", async (req, res) => {
         try {
             const { customerId } = req.params;

             // Query ordered by timestamp for the latest estimate
             const [rows] = await db.query(
                 "SELECT version FROM weinscoating_estimate WHERE customerId = ? ORDER BY timestamp DESC LIMIT 1",
                 [customerId]
             );

             res.json({ version: rows.length > 0 ? rows[0].version : "0.0" });

         } catch (error) {
             console.error("🔥 ERROR: Failed to fetch latest version:", error);
             res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
         }
     });

  return router;
};
