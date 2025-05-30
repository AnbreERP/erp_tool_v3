const express = require("express");
const createEstimateService = require("../lib/services/EstimateService");

module.exports = (db) => {
  const router = express.Router();
   const EstimateService = createEstimateService(db);

  /** ✅ **Fetch all estimates from multiple tables** **/
router.get("/all-estimates/:customerId", async (req, res) => {
  try {
    const { customerId } = req.params;

    const tables = [
      "granite_estimates",
      "woodwork_estimate",
      "charcoal_estimate",
      "quartz_slab_estimates",
      "wallpaper_estimate",
      "weinscoating_estimate",
      "fc_estimates",
      "grass_estimates",
      "flooring_estimates",
      "mosquitonet_estimates"
    ];

    let allEstimates = [];

    for (const table of tables) {
      const [estimates] = await db.query(
        `SELECT id AS estimateId, customerId, '${table}' AS estimateType, totalAmount, version, timestamp
         FROM ${table}
         WHERE customerId = ?`,
        [customerId]
      );
      allEstimates.push(...estimates);
    }

    if (allEstimates.length === 0) {
      console.log(`Debug: No estimates found for customer ${customerId}`);
    }

    console.log(`Debug: All Estimates Retrieved - ${JSON.stringify(allEstimates)}`);
    res.status(200).json(allEstimates);
  } catch (error) {
    console.error("❌ Error fetching customer estimates:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

router.get('/selected-estimate/:customerId', async (req, res) => {
        try {
          const { customerId } = req.params;
          const { version } = req.query;  // Get version from query params

          if (!version) {
            return res.status(400).json({ error: 'Version is required' });  // Error if version is missing
          }

          // Define the tables for different estimate types
          const tables = [
            'granite_estimates',
            'woodwork_estimate',
            'charcoal_estimate',
            'quartz_slab_estimates',
            'wallpaper_estimate',
            'weinscoating_estimate',
            'fc_estimates',
            'grass_estimates',
            'flooring_estimates',
            'mosquitonet_estimates'
          ];

          let allEstimates = [];

          for (const table of tables) {
            // Query the database to get estimates for the given customerId and version
            const query = `SELECT DISTINCT id AS estimateId, customerId, '${table}' AS estimateType, totalAmount, version, timestamp
                           FROM ${table}
                           WHERE customerId = ? AND version = ?`;

            const params = [customerId, version];

            // Fetch estimates for each table (type)
            const [estimates] = await db.query(query, params);
            allEstimates.push(...estimates);
          }

          // Ensure unique estimateId in the final response
          allEstimates = Array.from(new Set(allEstimates.map(a => a.estimateId)))
            .map(id => allEstimates.find(a => a.estimateId === id));

          if (allEstimates.length === 0) {
            console.log(`Debug: No estimates found for customer ${customerId} and version ${version}`);
            return res.status(404).json({ message: 'No estimates found' });
          }

          console.log(`Debug: Estimates Retrieved for customer ${customerId} and version ${version}: ${JSON.stringify(allEstimates)}`);

          // Return the fetched estimates as a response
          res.status(200).json(allEstimates);
        } catch (error) {
          console.error("Error fetching customer estimates:", error);
          res.status(500).json({ error: 'Internal Server Error' });
        }
      });

router.get("/estimate-details", async (req, res) => {
  try {
    const { estimateId, estimateType } = req.query;

    if (!estimateId || !estimateType) {
      return res.status(400).json({
        success: false,
        message: "Both estimateId and estimateType are required",
      });
    }

    // Map estimateType to their correct detail table names
    const detailTableMap = {
      granite_estimates: "granite_estimates_details",
      woodwork_estimate: "woodwork_estimate_row",
      charcoal_estimate: "charcoal_estimate_row",
      quartz_slab_estimates: "quartz_estimate_details",
      wallpaper_estimate: "wallpaper_estimates_row",
      weinscoating_estimate: "weinscoating_estimate_row",
      fc_estimates: "fc_estimate_row",
      grass_estimates: "grass_estimate_rows",
      flooring_estimates: "flooring_vinyl_estimate_row", // default; can be dynamic
      mosquitonet_estimates: "mosquitonet_estimate_row",
      electrical_estimates: "electrical_estimate_rows",
    };

    const detailTable = detailTableMap[estimateType];

    if (!detailTable) {
      return res.status(400).json({
        success: false,
        message: `Unknown estimateType: ${estimateType}`,
      });
    }

    // Fetch only rows from the correct table
    const [details] = await db.query(
      `SELECT * FROM ${detailTable} WHERE estimateId = ?`,
      [estimateId]
    );

    return res.status(200).json({
      success: true,
      estimateId,
      estimateType,
      details,
    });

  } catch (error) {
    console.error("❌ Error in /estimate-details:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
});




  /** ✅ **Fetch a specific estimate with details** **/
router.get("/estimates/:estimateId/details", async (req, res) => {
  try {
    const { estimateId } = req.params;

    const estimateTables = {
      granite: 'granite_estimates',
      woodwork: 'woodwork_estimates',
      charcoal: 'charcoal_estimates',
      quartz: 'quartz_slab_estimates',
      wallpaper: 'wallpaper_estimates',
      weinscoating: 'weinscoating_estimates',
      falseceiling: 'false_ceiling_estimates',
      grass: 'grass_estimates',
      flooring: 'flooring_estimates',
      mosquitonet: 'mosquitonet_estimates',
      electrical: 'electrical_estimates'
    };

    const detailTables = {
      granite: 'granite_estimate_details',
      woodwork: 'woodwork_estimate_details',
      charcoal: 'charcoal_estimate_details',
      quartz: 'quartz_slab_estimate_details',
      wallpaper: 'wallpaper_estimate_details',
      weinscoating: 'weinscoating_estimate_details',
      falseceiling: 'false_ceiling_estimate_details',
      grass: 'grass_estimate_details',
      flooring: 'flooring_estimate_details',
      mosquitonet: 'mosquitonet_estimate_details',
      electrical: 'electrical_estimate_details'
    };

    let estimate = null;
    let estimateType = null;

    // 🔍 Find the estimate from the correct table
    for (const [type, table] of Object.entries(estimateTables)) {
      const [rows] = await db.query(`SELECT * FROM ${table} WHERE id = ?`, [estimateId]);
      if (rows.length) {
        estimate = rows[0];
        estimateType = type;
        break;
      }
    }

    if (!estimate || !estimateType) {
      return res.status(404).json({ success: false, message: "Estimate not found" });
    }

    const detailTable = detailTables[estimateType];

    // ✅ Now get only that estimate's details
    const [details] = await db.query(`SELECT * FROM ${detailTable} WHERE estimateId = ?`, [estimateId]);

    res.json({
      success: true,
      estimate: { ...estimate, estimateType },
      details
    });
  } catch (error) {
    console.error("❌ Error:", error);
    res.status(500).json({ success: false, message: "Internal Server Error" });
  }
});




  /** ✅ **Fetch customer name by ID** **/
router.get("/customers/:customerId", async (req, res) => {
    try {
      const { customerId } = req.params;
      const [result] = await db.query(
        "SELECT name FROM customers WHERE id = ?",
        [customerId]
      );

      if (result.length === 0) {
        return res.status(404).json({ error: "Customer not found" });
      }

      res.json({ customerName: result[0].name });
    } catch (error) {
      console.error("❌ Error fetching customer name:", error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  });


  /**  Fetch unique estimate types for a customer **/
router.get("/estimates/customer/:customerId/types", async (req, res) => {
      try {
        const { customerId } = req.params;

        // Mapping table names with the desired estimateType labels
        const tables = [
          { table: "granite_estimates", type: "Granite" },
          { table: "woodwork_estimates", type: "Woodwork" },
          { table: "charcoal_estimates", type: "Charcoal" },
          { table: "quartz_slab_estimates", type: "Quartz" },
          { table: "wallpaper_estimates", type: "Wallpaper" },
          { table: "weinscoating_estimates", type: "Weinscoating" },
          { table: "false_ceiling_estimates", type: "False Ceiling" },
          { table: "grass_estimates", type: "Grass" },        // Added grass_estimates
          { table: "flooring_estimates", type: "Flooring" },   // Added flooring_estimates
          { table: "mosquitonet_estimates", type: "MosquitoNet" }, // Added mosquitonet_estimates
          { table: 'electrical_estimates', type: "electrical" }
        ];

        let estimateTypes = [];

        for (const { table, type } of tables) {
          const sql = `SELECT id FROM ${table} WHERE customerId = ? LIMIT 1`;
          const params = [customerId];

          // ✅ Print the query and its parameters
          console.log(`Executing query: ${sql} with params: ${params}`);

          const [results] = await db.query(sql, params);

          if (results.length > 0) {
            estimateTypes.push({ estimateType: type });
          }
        }

        res.status(200).json({
          success: true,
          data: estimateTypes,
        });
      } catch (error) {
        console.error("❌ Error fetching estimate types:", error);
        res.status(500).json({
          success: false,
          message: "Internal Server Error",
        });
      }
    });


      /** ✅ 1. Get all estimates with details by customerId and estimateType **/
router.get("/estimates/customer/:customerId/:estimateType", async (req, res) => {
        try {
          const { customerId, estimateType } = req.params;
          const estimates = await EstimateService.getEstimatesByCustomerId(
            customerId,
            estimateType.toLowerCase()
          );

          res.status(200).json({
            success: true,
            data: estimates,
          });
        } catch (error) {
          console.error("❌ Error fetching estimates:", error);
          res.status(500).json({
            success: false,
            message: "Internal Server Error",
          });
        }
      });

      /** ✅ 2. Get estimate details by estimateId and estimateType **/
router.get("/estimates/:estimateType/:estimateId/details", async (req, res) => {
        try {
          const { estimateType, estimateId } = req.params;
          const details = await EstimateService.getEstimatesByEstimateId(
            estimateId,
            estimateType.toLowerCase()
          );

          res.status(200).json({
            success: true,
            data: details,
          });
        } catch (error) {
          console.error("❌ Error fetching estimate details:", error);
          res.status(500).json({
            success: false,
            message: "Internal Server Error",
          });
        }
      });

      /** ✅ 3. Fetch estimates by type and customerId **/
router.get("/estimates/type/:estimateType/customer/:customerId", async (req, res) => {
        try {
          const { estimateType, customerId } = req.params;
          const estimates = await EstimateService.fetchEstimatesByType(
            customerId,
            estimateType.toLowerCase()
          );

          res.status(200).json({
            success: true,
            data: estimates,
          });
        } catch (error) {
          console.error("❌ Error fetching estimates by type:", error);
          res.status(500).json({
            success: false,
            message: "Internal Server Error",
          });
        }
      });

        /** ✅ Get granite estimate details by estimateId **/
router.get("/estimates/granite/:estimateId", async (req, res) => {
          try {
            const { estimateId } = req.params;
            const estimate = await EstimateService.getEstimateDetailsById(estimateId);

            if (!estimate) {
              return res.status(404).json({
                success: false,
                message: "Granite estimate not found",
              });
            }

            res.status(200).json({
              success: true,
              data: estimate,
            });
          } catch (error) {
            console.error("❌ Error fetching granite estimate:", error.message);
            res.status(500).json({
              success: false,
              message: "Internal Server Error",
            });
          }
        });

/** ✅ **Fetch estimate details for a specific estimate by estimateId** **/
router.get("/estimates/:estimateType/:estimateId/details", async (req, res) => {
        try {
          const { estimateType, estimateId } = req.params;
          const details = await EstimateService.getEstimatesByEstimateId(
            estimateId,
            estimateType.toLowerCase()
          );

          res.status(200).json({
            success: true,
            data: details,
          });
        } catch (error) {
          console.error("❌ Error fetching estimate details:", error);
          res.status(500).json({
            success: false,
            message: "Internal Server Error",
          });
        }
      });

      /** ✅ 3. Fetch estimates by type and customerId **/
router.get("/estimates/type/:estimateType/customer/:customerId", async (req, res) => {
        try {
          const { estimateType, customerId } = req.params;
          const estimates = await EstimateService.fetchEstimatesByType(
            customerId,
            estimateType.toLowerCase()
          );

          res.status(200).json({
            success: true,
            data: estimates,
          });
        } catch (error) {
          console.error("❌ Error fetching estimates by type:", error);
          res.status(500).json({
            success: false,
            message: "Internal Server Error",
          });
        }
      });

        /** ✅ Get granite estimate details by estimateId **/
router.get("/estimates/granite/:estimateId", async (req, res) => {
          try {
            const { estimateId } = req.params;
            const estimate = await EstimateService.getEstimateDetailsById(estimateId);

            if (!estimate) {
              return res.status(404).json({
                success: false,
                message: "Granite estimate not found",
              });
            }

            res.status(200).json({
              success: true,
              data: estimate,
            });
          } catch (error) {
            console.error("❌ Error fetching granite estimate:", error.message);
            res.status(500).json({
              success: false,
              message: "Internal Server Error",
            });
          }
        });


// customer.routes.js or similar



  return router;
};
