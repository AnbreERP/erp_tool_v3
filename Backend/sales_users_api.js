const express = require("express");
const jwt = require("jsonwebtoken");

module.exports = (db) => {
    const router = express.Router();

    // Middleware to authenticate token
    const authenticateToken = (req, res, next) => {
      const token = req.headers["authorization"]?.split(" ")[1]; // Bearer <token>

      if (!token) {
        return res.status(403).json({ error: "Token is missing" });
      }

      jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
          return res.status(403).json({ error: "Invalid or expired token" });
        }
        console.log('Token verified:', user); // Log the user info to check
        req.user = user; // Attach user data to request object
        next();
      });
    };

    // Endpoint to get summary for all estimates (all tables)
 router.get('/estimates-summary', authenticateToken, async (req, res) => {
     const userId = req.user.userId; // Get the logged-in user's ID

     try {
         // Query to sum total amounts and count total estimates from multiple tables
         const query = `
             SELECT
                 SUM(totalAmount) AS overallTotalAmount,   -- Sum of totalAmount
                 COUNT(*) AS estimateCount                  -- Count of total estimates
             FROM (
                 SELECT totalAmount FROM wallpaper_estimate WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM woodwork_estimate WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM fc_estimates WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM granite_estimates WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM quartz_slab_estimates WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM weinscoating_estimate WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM mosquitonet_estimates WHERE user_id = ?
                 UNION ALL
                 SELECT totalAmount FROM flooring_estimates WHERE user_id = ?  -- Add flooring_estimates
                 UNION ALL
                 SELECT totalAmount FROM grass_estimates WHERE user_id = ?     -- Add grass_estimates
             ) AS all_estimates;
         `;

         // Pass userId for each table in the query parameters
         const [result] = await db.query(query, [
             userId, userId, userId, userId, userId, userId, userId, userId, userId
         ]);

         // Send the response with the total amount and the count of estimates
         res.status(200).json({
             overallTotalAmount: result[0].overallTotalAmount, // Total sum of all estimate amounts
             estimateCount: result[0].estimateCount          // Total count of all estimates
         });

     } catch (error) {
         console.error("Error fetching estimate summary:", error);
         res.status(500).json({ error: "Failed to fetch estimate summary" });
     }
 });

  // Endpoint to get all estimates from different tables
router.get("/all-estimates", authenticateToken, async (req, res) => {
  const userId = req.user.userId;

  try {
    const query = `
      SELECT
        e.estimateType,
        e.totalAmount,
        e.customerId,
        e.version,
        e.timestamp,
        e.user_id,
        e.stage,
        e.status,
        e.assigned_to,
        CONCAT(u.first_name, ' ', u.last_name) AS assignedUserName
      FROM (
        SELECT 'wallpaper_estimate' AS estimateType, totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM wallpaper_estimate WHERE user_id = ?
        UNION ALL
        SELECT 'woodwork_estimate', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM woodwork_estimate WHERE user_id = ?
        UNION ALL
        SELECT 'fc_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM fc_estimates WHERE user_id = ?
        UNION ALL
        SELECT 'granite_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM granite_estimates WHERE user_id = ?
        UNION ALL
        SELECT 'quartz_slab_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM quartz_slab_estimates WHERE user_id = ?
        UNION ALL
        SELECT 'weinscoating_estimate', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM weinscoating_estimate WHERE user_id = ?
        UNION ALL
        SELECT 'mosquitonet_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM mosquitonet_estimates WHERE user_id = ?
        UNION ALL
        SELECT 'flooring_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM flooring_estimates WHERE user_id = ?
        UNION ALL
        SELECT 'grass_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM grass_estimates WHERE user_id = ?
      ) AS e
      LEFT JOIN users u ON e.assigned_to = u.id
      ORDER BY e.timestamp DESC;
    `;

    const [results] = await db.query(query, Array(9).fill(userId));
    res.status(200).json(results.length > 0 ? results : []);
  } catch (error) {
    console.error("🔥 ERROR: Failed to fetch all estimates:", error);
    res.status(500).json({ error: "Database query failed", details: error.message });
  }
});



    // Endpoint to fetch specific estimate by ID from all tables (generic)
    router.get("/estimates/:estimateId", authenticateToken, async (req, res) => {
        const { estimateId } = req.params;
        const userId = req.user.userId;

        try {
          const query = `
            SELECT estimateType,
                   COUNT(estimateId) AS estimateCount,
                   SUM(totalAmount) AS totalAmount
            FROM (
                SELECT estimateType, totalAmount, estimateId FROM wallpaper_estimate WHERE user_id = ?
                UNION ALL
                SELECT estimateType, totalAmount, estimateId FROM woodwork_estimate WHERE user_id = ?
                UNION ALL
                SELECT estimateType, totalAmount, estimateId FROM fc_estimates WHERE user_id = ?
                UNION ALL
                SELECT estimateType, totalAmount, estimateId FROM granite_estimates WHERE user_id = ?
                UNION ALL
                SELECT estimateType, totalAmount, estimateId FROM quartz_slab_estimates WHERE user_id = ?
                UNION ALL
                SELECT estimateType, totalAmount, estimateId FROM weinscoating_estimate WHERE user_id = ?
                UNION ALL
                SELECT estimateType, totalAmount, estimateId FROM mosquitonet_estimates WHERE user_id = ?
            ) AS all_estimates
            GROUP BY estimateType;
          `;

            const [results] = await db.query(query, Array(7).fill(estimateId).concat(Array(7).fill(userId)));
            res.status(200).json(results.length > 0 ? results[0] : {});
        } catch (error) {
            console.error("❌ Failed to fetch estimate:", error);
            res.status(500).json({ error: "Failed to fetch estimate" });
        }
    });

 router.put('/promote-stage', authenticateToken, async (req, res) => {
   console.log("✅ /promote-stage hit");

   const userId = req.user.userId;
   const { estimateType, version, currentStage, assignedTo } = req.body;

   // ✅ Validate all inputs properly
   if (!estimateType || !version || !currentStage || !assignedTo) {
     return res.status(400).json({ error: "Missing required fields" });
   }

   let nextStage;
   switch (currentStage) {
     case 'Sales':
       nextStage = 'Pre-Designer';
       break;
     case 'Pre-Designer':
       nextStage = 'Designer';
       break;
     default:
       return res.status(400).json({ error: "No next stage from current stage" });
   }

   try {
     const [result] = await db.query(
       `UPDATE \`${estimateType}\`
        SET stage = ?, assigned_to = ?
        WHERE user_id = ? AND version = ? AND stage = ?`,
       [nextStage, assignedTo, userId, version, currentStage]
     );

     if (result.affectedRows > 0) {
       console.log("📦 Promote Request:", { userId, estimateType, version, currentStage, assignedTo });

       // 🔍 Get next-stage user (optional fallback)
       const [nextUser] = await db.query(
         `SELECT u.id
          FROM users u
          JOIN user_roles ur ON u.id = ur.user_id
          JOIN roles r ON ur.role_id = r.id
          WHERE r.role_name = ?
          LIMIT 1`,
         [nextStage]
       );

       const notifyUserId = nextUser[0]?.id || assignedTo;

       // 🔔 Send notification
       await db.query(
         `INSERT INTO notifications (user_id, title, message, type)
          VALUES (?, ?, ?, ?)`,
         [
           notifyUserId,
           'Estimate Promoted',
           `Estimate ${estimateType} (v${version}) promoted to ${nextStage}`,
           'estimate'
         ]
       );

       return res.status(200).json({ message: `Estimate promoted to ${nextStage}` });
     } else {
       return res.status(404).json({ error: 'No matching estimates found to promote' });
     }
     console.log("📄 SQL Params:", [nextStage, assignedTo, userId, version, currentStage]);

   } catch (error) {
     console.error("❌ Failed to promote stage:", error);
     return res.status(500).json({ error: "Internal server error" });
   }
 });
router.get('/assigned-estimates', authenticateToken, async (req, res) => {
  const userId = req.user.userId;

  try {
    const query = `
      SELECT
        e.estimateType,
        e.totalAmount,
        e.customerId,
        e.version,
        e.timestamp,
        e.user_id,
        e.stage,
        e.status,
        e.assigned_to,
        CONCAT(u.first_name, ' ', u.last_name) AS assignedByName
      FROM (
        SELECT 'wallpaper_estimate' AS estimateType, totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM wallpaper_estimate
        UNION ALL
        SELECT 'woodwork_estimate', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM woodwork_estimate
        UNION ALL
        SELECT 'fc_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM fc_estimates
        UNION ALL
        SELECT 'granite_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM granite_estimates
        UNION ALL
        SELECT 'quartz_slab_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM quartz_slab_estimates
        UNION ALL
        SELECT 'weinscoating_estimate', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM weinscoating_estimate
        UNION ALL
        SELECT 'mosquitonet_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM mosquitonet_estimates
        UNION ALL
        SELECT 'flooring_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM flooring_estimates
        UNION ALL
        SELECT 'grass_estimates', totalAmount, customerId, version, timestamp, user_id, stage, status, assigned_to FROM grass_estimates
      ) AS e
      LEFT JOIN users u ON e.user_id = u.id
      WHERE e.assigned_to = ?
      ORDER BY e.timestamp DESC;
    `;

    const [results] = await db.query(query, [userId]);
    res.json({ estimates: results });
  } catch (error) {
    console.error("🔥 Error fetching assigned estimates:", error);
    res.status(500).json({ error: "Failed to fetch assigned estimates" });
  }
});

    return router;
};
