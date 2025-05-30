const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');

module.exports = (db) => {
    const router = express.Router();


    // ✅ Insert a new flooring estimate (summary + rows)
  router.post("/flooring-estimates", authenticateToken, async (req, res) => {
      const { customerId, user_id, customer_name, installation_cost, foam, transport_charges, gst, totalAmount, version, timestamp, flooringType, estimateType, status, stage, rows } = req.body;

      if (!customerId || !customer_name || !totalAmount || !version || !flooringType || !estimateType || !Array.isArray(rows) || rows.length === 0) {
          return res.status(400).json({ error: "Missing required fields or rows" });
      }

      try {
          // Insert estimate summary with user_id and estimateType
          const [summaryResult] = await db.query(
              `INSERT INTO flooring_estimates (customerId, user_id, customer_name, installation_cost, foam, transport_charges, gst, totalAmount, version, timestamp, flooringType, estimateType, status, stage)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
              [customerId, user_id, customer_name, installation_cost, foam, transport_charges, gst, totalAmount, version, timestamp, flooringType, estimateType, status, stage]
          );

          const estimateId = summaryResult.insertId;

          // Determine the correct rows table based on flooring type
          const tableName = `flooring_${flooringType.toLowerCase()}_estimate_row`;

          // Insert estimate rows
          const rowValues = rows.map((row) => [
              estimateId,
              row.description,
              row.length,
              row.width,
              row.area,
              row.perBox,
              row.totalRequired,
              row.boxes,
              row.areaRequired,
              row.ratePerSqft,
              row.totalAmount,
          ]);

          await db.query(
              `INSERT INTO ${tableName} (estimateId, description, length, width, area, perBox, totalRequired, boxes, areaRequired, ratePerSqft, totalAmount) VALUES ?`,
              [rowValues]
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
          res.status(201).json({ id: estimateId, message: "Flooring estimate saved successfully!" });
      } catch (error) {
          console.error("🔥 ERROR: Failed to create flooring estimate:", error);
          res.status(500).json({ error: "Failed to create flooring estimate", details: error.message });
      }
  });

 router.get("/flooring-estimates", authenticateToken, async (req, res) => {
   const { userId, permissions } = req.user;
   const { type } = req.query;

   // 🔧 Normalize permission keys
   const normalizedPermissions = {};
   for (const [module, perms] of Object.entries(permissions || {})) {
     normalizedPermissions[module.toLowerCase()] = perms;
   }

   const estimatePerms = normalizedPermissions['estimate'] || [];

   let query = "SELECT * FROM flooring_estimates";
   const params = [];

   try {
     if (estimatePerms.includes('view_all_estimates')) {
       // no WHERE clause needed
     } else if (estimatePerms.includes('view_member_estimates')) {
       query += `
         WHERE user_id IN (
           SELECT tm.user_id FROM team_members tm
           WHERE tm.team_id IN (
             SELECT team_id FROM team_members WHERE user_id = ?
           )
         )
       `;
       params.push(userId);
     } else if (estimatePerms.includes('view_team_estimates')) {
       query += `
         WHERE user_id = ?
         OR user_id IN (
           SELECT tm.user_id FROM team_members tm
           JOIN teams t ON t.id = tm.team_id
           WHERE t.team_lead_id = ?
         )
       `;
       params.push(userId, userId);
     } else if (estimatePerms.includes('view_estimate')) {
       query += " WHERE user_id = ?";
       params.push(userId);
     } else {
       return res.status(403).json({ error: "Access denied: No estimate permissions" });
     }

     // Append type filter
     if (type) {
       query += params.length > 0 ? " AND flooringType = ?" : " WHERE flooringType = ?";
       params.push(type);
     }

     query += " ORDER BY timestamp DESC";

     console.log("Executing query:", query);
     console.log("With parameters:", params);

     const [estimates] = await db.query(query, params);

     const modifiedEstimates = estimates.map((estimate) => {
       estimate.id = estimate.estimateId;
       delete estimate.estimateId;
       return estimate;
     });

     res.json(modifiedEstimates);
   } catch (error) {
     console.error("🔥 ERROR fetching flooring estimates:", error);
     res.status(500).json({ error: "Failed to fetch estimates" });
   }
 });


 router.get("/latest/:customerId", async (req, res) => {
       try {
           const { customerId } = req.params;

           // Query ordered by timestamp for the latest estimate
           const [rows] = await db.query(
               "SELECT version FROM flooring_estimates WHERE customerId = ? ORDER BY timestamp DESC LIMIT 1",
               [customerId]
           );

           res.json({ version: rows.length > 0 ? rows[0].version : "0.0" });

       } catch (error) {
           console.error("🔥 ERROR: Failed to fetch latest version:", error);
           res.status(500).json({ error: "Failed to fetch latest version", details: error.message });
       }
   });

    // ✅ Fetch estimates for a specific customer
   router.get("/flooring-estimates/customer/:customerId", async (req, res) => {
     const { customerId } = req.params;
     try {
       const [results] = await db.query(`
         SELECT
           id AS estimateId,
           customerId,
           customer_name,
           totalAmount,
           version,
           flooringType,
           timestamp
         FROM flooring_estimates
         WHERE customerId = ?
       `, [customerId]);

       res.json(results);
     } catch (error) {
       console.error("❌ Failed to get flooring estimates:", error);
       res.status(500).json({ error: "Server error while fetching estimates." });
     }
   });


    // ✅ Fetch estimate summary and rows by flooringType and estimateId (For Edit)
    router.get("/flooring-estimates/:flooringType/:estimateId", async (req, res) => {
        try {
            const { flooringType, estimateId } = req.params;

            const [summaryResult] = await db.query(
              `SELECT * FROM flooring_estimates WHERE id = ? AND flooringType = ?`,
              [estimateId, flooringType]
            );


            if (summaryResult.length === 0) {
                return res.status(404).json({ message: "Estimate not found" });
            }

            const tableName = `flooring_${flooringType.toLowerCase()}_estimate_row`;
            const [rows] = await db.query(`SELECT * FROM ${tableName} WHERE estimateId = ?`, [estimateId]);

            // ✅ Calculate total area from rows
            const totalArea = rows.reduce((sum, row) => sum + (row.area || 0), 0);

            // ✅ Recalculate installation cost if total area > 0
            if (totalArea > 0) {
                summaryResult[0].installation_cost = summaryResult[0].installation_cost / totalArea;
            }

            // ✅ Version handling
            if (parseFloat(summaryResult[0].version) === 0.0) {
                summaryResult[0].version = "1.1";
            }

            res.status(200).json({ summary: summaryResult[0], rows });
        } catch (error) {
            console.error("🔥 ERROR fetching estimate details:", error);
            res.status(500).json({ error: "Failed to fetch estimate details" });
        }
    });

    // ✅ Save updated estimate as a new version (Edit Functionality)
    router.put("/flooring-estimates/:estimateId", async (req, res) => {
            const connection = await db.getConnection();
            try {
                await connection.beginTransaction();

                const { estimateId } = req.params;
                const { customer_id, customer_name, installation_cost, foam, transport_charges, gst, totalAmount, timestamp, flooringType, rows } = req.body;

                if (!customerId || !customer_name || !totalAmount || !flooringType) {
                    return res.status(400).json({ error: "Missing required fields" });
                }

                // ✅ Fetch the latest version for this customer
                const [latestVersionResult] = await connection.query(
                    `SELECT MAX(version) as latestVersion FROM flooring_estimates WHERE customerId = ?`,
                    [customer_id]
                );

                const latestVersion = parseFloat(latestVersionResult[0].latestVersion || "0.0");
                const major = Math.floor(latestVersion);
                const minor = ((latestVersion - major) * 10).toFixed(0);
                const newVersion = latestVersion === 0.0
                    ? "1.1"
                    : minor >= 9
                        ? `${major + 1}.1`
                        : `${major}.${parseInt(minor) + 1}`;

                // ✅ Insert new estimate
                const [summaryResult] = await connection.query(
                    `INSERT INTO flooring_estimates (customer_id, customer_name, installation_cost, foam, transport_charges, gst, totalAmount, version, timestamp, flooringType)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [customer_id, customer_name, installation_cost, foam, transport_charges, gst, totalAmount, newVersion, timestamp, flooringType]
                );

                const newEstimateId = summaryResult.insertId;
                const tableName = `flooring_${flooringType.toLowerCase()}_estimate_row`;

                const rowValues = rows.map((row) => [
                    newEstimateId,
                    row.description,
                    row.length,
                    row.width,
                    row.area,
                    row.perBox,
                    row.totalRequired,
                    row.boxes,
                    row.areaRequired,
                    row.ratePerSqft,
                    row.totalAmount,
                ]);

                await connection.query(
                    `INSERT INTO ${tableName} (estimateId, description, length, width, area, perBox, totalRequired, boxes, areaRequired, ratePerSqft, totalAmount) VALUES ?`,
                    [rowValues]
                );

                await connection.commit();
                res.status(201).json({ id: newEstimateId, message: "Updated estimate saved as a new version!" });
            } catch (error) {
                await connection.rollback();
                console.error("🔥 ERROR updating estimate:", error);
                res.status(500).json({ error: "Failed to update estimate", details: error.message });
            } finally {
                connection.release();
            }
        });

    // ✅ Delete flooring estimate and rows
    router.delete("/flooring-estimates/:estimateId", async (req, res) => {
        const connection = await db.getConnection();
        try {
            await connection.beginTransaction();

            const { estimateId } = req.params;
            const [estimate] = await connection.query(`SELECT flooringType FROM flooring_estimates WHERE estimateId = ?`, [estimateId]);

            if (estimate.length === 0) {
                return res.status(404).json({ message: "Estimate not found" });
            }

            const tableName = `flooring_${estimate[0].flooringType.toLowerCase()}_estimate_row`;
            await connection.query(`DELETE FROM ${tableName} WHERE estimateId = ?`, [estimateId]);
            await connection.query(`DELETE FROM flooring_estimates WHERE estimateId = ?`, [estimateId]);

            await connection.commit();
            res.status(200).json({ message: "Estimate deleted successfully!" });
        } catch (error) {
            await connection.rollback();
            res.status(500).json({ error: "Failed to delete estimate" });
        } finally {
            connection.release();
        }
    });

    return router;
};
