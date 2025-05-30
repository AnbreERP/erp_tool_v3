const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');


module.exports = (db) => {
  const router = express.Router();

//    Get the latest version for a customer's Woodwork estimate

router.get("/woodwork-estimates/:customerId/latest-version", async (req, res) => {
  const { customerId } = req.params;
  const { estimateType } = req.query;

  try {
    const [result] = await db.query(
      `SELECT MAX(CAST(version AS DECIMAL(5,1))) as version
       FROM woodwork_estimate
       WHERE customerId = ? AND estimateType = ?`,
      [customerId, estimateType]
    );

    const version = result[0].version ? result[0].version.toString() : "0.0";

    res.json({ version });
  } catch (error) {
    console.error("❌ Error fetching latest version:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

  /**
   * Save a new Woodwork estimate with rows
   */
 router.post("/woodwork-estimates", authenticateToken, async (req, res) => {
   try {
     const { customerId, customerName, customerEmail, customerPhone,
       totalAmount, totalAmount2, totalAmount3, discount, transportCost,
       gstPercentage, estimateType, version, status, stage, rows } = req.body;

     // Get userId from the decoded token
     const userId = req.user.userId; // Assuming token is authenticated and userId is attached to req.user

     // Validate required fields
     let missingFields = [];
     if (!customerId) missingFields.push("customerId");
     if (!customerName) missingFields.push("customerName");
     if (!totalAmount) missingFields.push("totalAmount");
     if (!estimateType) missingFields.push("estimateType");
     if (!version) missingFields.push("version");
     if (!rows || !Array.isArray(rows) || rows.length === 0) missingFields.push("rows");
     if (!userId) missingFields.push("userId");
     if (!status) missingFields.push("status");
     if (!stage) missingFields.push("stage");

     if (missingFields.length > 0) {
       console.error("🚨 Missing required fields:", missingFields);
       return res.status(400).json({ error: "Missing required fields", missingFields });
     }

     console.log("✅ All fields are present. Proceeding with database insert...");

     // Start transaction
     const connection = await db.getConnection();
     await connection.beginTransaction();

     try {
       // Step 1: Insert into main `woodwork_estimate` table
       const [estimateResult] = await connection.query(
         `INSERT INTO woodwork_estimate
         (customerId, customerName, customerEmail, customerPhone, totalAmount, totalAmount2, totalAmount3, discount, transportCost, gstPercentage, estimateType, version, user_id, status, stage)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
         [customerId, customerName, customerEmail, customerPhone, totalAmount, totalAmount2, totalAmount3, discount, transportCost, gstPercentage, estimateType, version, userId, status, stage]
       );

       const estimateId = estimateResult.insertId;
       console.log("✅ Inserted Estimate ID:", estimateId);

       // Step 2: Insert rows into `woodwork_estimate_row`
       const rowInserts = rows.map(row => [
         estimateId,
         row.sNo,
         row.room || '',
         row.selectedUnit,
         row.description,
         row.widthInput,
         row.widthMM,
         row.heightInput,
         row.heightMM,
         row.widthFeet,
         row.heightFeet,
         row.squareFeet,
         row.quantity,
         row.finishType1,
         row.selectedFinishRate,
         row.amount1,
         row.totalAmount,
         row.finishType2,
         row.selectedFinishRate2,
         row.amount2,
         row.totalAmount2,
         row.finishType3,
         row.selectedFinishRate3,
         row.amount3,
         row.totalAmount3,
         row.sidePanel1,
         row.sideRate1,
         row.sideQuantity1,
         row.sideAmount1,
         row.sidePanel2,
         row.sideRate2,
         row.sideQuantity2,
         row.sideAmount2,
         row.sidePanel3,
         row.sideRate3,
         row.sideQuantity3,
         row.sideAmount3
       ]);

       await connection.query(
         `INSERT INTO woodwork_estimate_row
         (estimateId, sNo, room, selectedUnit, description, widthInput, widthMM, heightInput, heightMM, widthFeet, heightFeet, squareFeet, quantity,
         finishType1, selectedFinishRate, amount1, totalAmount,
         finishType2, selectedFinishRate2, amount2, totalAmount2,
         finishType3, selectedFinishRate3, amount3, totalAmount3,
         sidePanel1, sideRate1, sideQuantity1, sideAmount1,
         sidePanel2, sideRate2, sideQuantity2, sideAmount2,
         sidePanel3, sideRate3, sideQuantity3, sideAmount3)
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
       console.error("❌ Error during database operation:", err);
       throw err;
     }

   } catch (error) {
     console.error("❌ Internal Server Error:", error);
     res.status(500).json({ error: "Internal Server Error", details: error.message });
   }
 });

 router.get("/woodwork-estimates", authenticateToken, async (req, res) => {
   const { userId, permissions } = req.user;

   //  Normalize permission keys
   const normalizedPermissions = {};
   for (const [module, perms] of Object.entries(permissions || {})) {
     normalizedPermissions[module.toLowerCase()] = perms;
   }

   const estimatePerms = normalizedPermissions['estimate'] || [];

   let query = '';
   let params = [];

   try {
     //  Permission-based filtering
     if (estimatePerms.includes('view_all_estimates')) {
       query = 'SELECT * FROM woodwork_estimate ORDER BY id DESC';
     } else if (estimatePerms.includes('view_member_estimates')) {
       query = `
         SELECT e.* FROM woodwork_estimate e
         JOIN team_members tm ON e.user_id = tm.user_id
         WHERE tm.team_id IN (
           SELECT team_id FROM team_members WHERE user_id = ?
         )
         ORDER BY e.id DESC
       `;
       params = [userId];
     } else if (estimatePerms.includes('view_team_estimates')) {
       query = `
         SELECT * FROM woodwork_estimate
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
       query = 'SELECT * FROM woodwork_estimate WHERE user_id = ? ORDER BY id DESC';
       params = [userId];
     } else {
       return res.status(403).json({ error: 'Access denied: No estimate permissions' });
     }

     // Fetch estimates
     const [estimates] = await db.query(query, params);

     // Fetch and attach estimate rows for each estimate
     for (let estimate of estimates) {
       const [rows] = await db.query(
         `SELECT * FROM woodwork_estimate_row WHERE estimateId = ?`,
         [estimate.id]
       );
       estimate.rows = rows;
     }

     res.status(200).json({ success: true, data: estimates });
   } catch (error) {
     console.error(" Error fetching woodwork estimates:", error);
     res.status(500).json({ error: "Internal Server Error" });
   }
 });


  /**
   *  Get a single Woodwork estimate by ID (including its rows)
   */
 router.get("/woodwork-estimates/:id", async (req, res) => {
   const { id } = req.params;

   try {
     // Fetch the main estimate
     const [estimateResult] = await db.query(
       `SELECT * FROM woodwork_estimate WHERE id = ?`,
       [id]
     );

     if (!estimateResult.length) {
       return res.status(404).json({ error: "Estimate not found" });
     }

     const estimate = estimateResult[0];

     // Parse numeric fields to numbers
     estimate.totalAmount = parseFloat(estimate.totalAmount);
     estimate.totalAmount2 = parseFloat(estimate.totalAmount2);
     estimate.totalAmount3 = parseFloat(estimate.totalAmount3);
     estimate.discount = parseFloat(estimate.discount);
     estimate.transportCost = parseFloat(estimate.transportCost);
     estimate.gstPercentage = parseFloat(estimate.gstPercentage);

     // Fetch the related rows
     const [rowsResult] = await db.query(
       `SELECT * FROM woodwork_estimate_row WHERE estimateId = ?`,
       [id]
     );


     // Return the estimate with its rows
     res.status(200).json({
       estimate,
       rows:rowsResult,
     });
   } catch (error) {
     console.error(" Error fetching estimate by ID:", error);
     res.status(500).json({ error: "Internal Server Error" });
   }
 });

router.get("/woodwork-estimates-edit/:id", authenticateToken, async (req, res) => {
   const { id } = req.params;

   try {
     // Fetch the main estimate
     const [estimateResult] = await db.query(
       `SELECT * FROM woodwork_estimate WHERE id = ?`,
       [id]
     );

     if (!estimateResult.length) {
       return res.status(404).json({ error: "Estimate not found" });
     }

     const estimate = estimateResult[0];

     // Parse numeric fields to numbers
     estimate.totalAmount = parseFloat(estimate.totalAmount);
     estimate.totalAmount2 = parseFloat(estimate.totalAmount2);
     estimate.totalAmount3 = parseFloat(estimate.totalAmount3);
     estimate.discount = parseFloat(estimate.discount);
     estimate.transportCost = parseFloat(estimate.transportCost);
     estimate.gstPercentage = parseFloat(estimate.gstPercentage);

     // Fetch the related rows
     const [rowsResult] = await db.query(
       `SELECT * FROM woodwork_estimate_row WHERE estimateId = ?`,
       [id]
     );


     // Return the estimate with its rows
     res.status(200).json({
       estimate,
       rows:rowsResult,
     });
   } catch (error) {
     console.error(" Error fetching estimate by ID:", error);
     res.status(500).json({ error: "Internal Server Error" });
   }
 });
/**
 *  Delete a woodwork estimate by ID (including its rows)
 */
router.delete("/woodwork/delete-estimate/:estimateId", async (req, res) => {
  const { estimateId } = req.params;

  try {
    // Delete rows from woodwork_estimate_rows table
    await db.query(
      `DELETE FROM woodwork_estimate_row WHERE estimateId = ?`,
      [estimateId]
    );

    // Delete the estimate from woodwork_estimates table
    await db.query(
      `DELETE FROM woodwork_estimate WHERE id = ?`,
      [estimateId]
    );

    res.status(200).json({ success: true, message: "Estimate deleted successfully." });
  } catch (error) {
    console.error("❌ Error deleting estimate:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

  return router;
};
