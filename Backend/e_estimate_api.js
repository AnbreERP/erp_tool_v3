const express = require("express");
const jwt = require("jsonwebtoken");
const checkPermissions = require('./middlewares/checkPermissions');
const authenticateToken = require('./middlewares/authenticateToken');


module.exports = (db) => {
  const router = express.Router();

  /** ✅ Standardized Error Handler */
  const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch((error) => {
      console.error("API Error:", error);
      res.status(error.statusCode || 500).json({ error: error.message || "Internal Server Error" });
    });
  };

  /** ✅ ID Validation Middleware */
  const validateId = (req, res, next) => {
    const { id } = req.params;
    if (!/^[0-9]+$/.test(id)) {
      return res.status(400).json({ error: "Invalid ID format" });
    }
    next();
  };

  /** ✅ Validate Request Body */
  const validateRequestBody = (requiredFields) => (req, res, next) => {
    for (const field of requiredFields) {
      if (!req.body[field]) {
        return res.status(400).json({ error: `${field} is required` });
      }
    }
    next();
  };

  /** 📌 **Descriptions API** ***************************************************************************/
  router.get("/descriptions", asyncHandler(async (req, res) => {
    const [results] = await db.query("SELECT * FROM electrical_description ORDER BY descriptionId DESC");
    res.json(results);
  }));

  router.post("/descriptions", validateRequestBody(["description"]), asyncHandler(async (req, res) => {
    const { description } = req.body;
    const [results] = await db.query("INSERT INTO electrical_description (description) VALUES (?)", [description]);
    res.status(201).json({ message: "Description added", id: results.insertId });
  }));

  router.put("/descriptions/:id", validateId, validateRequestBody(["description"]), asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { description } = req.body;

    const [result] = await db.query("UPDATE electrical_description SET description = ? WHERE descriptionId = ?", [description, id]);
    if (result.affectedRows === 0) return res.status(404).json({ error: "Description not found" });

    res.json({ message: "Description updated successfully" });
  }));

  router.delete("/descriptions/:id", validateId, asyncHandler(async (req, res) => {
    const { id } = req.params;

    const [result] = await db.query("DELETE FROM electrical_description WHERE descriptionId = ?", [id]);
    if (result.affectedRows === 0) return res.status(404).json({ error: "Description not found" });

    res.json({ message: "Description deleted successfully" });
  }));

  /** 📌 **Types API** *****************************************************************************/

    // ✅ Fetch all types
    router.get("/types", asyncHandler(async (req, res) => {
      const [results] = await db.query("SELECT * FROM electrical_types ORDER BY descriptionId DESC");
      res.json(results);
    }));

    // ✅ Fetch types based on a descriptionId
    router.get("/types/:descriptionId", asyncHandler(async (req, res) => {
      const { descriptionId } = req.params;
      console.log(`Fetching types for descriptionId: ${descriptionId}`); // ✅ Debugging Log

      // Ensure descriptionId is a number
      if (!/^[0-9]+$/.test(descriptionId)) {
        return res.status(400).json({ status: "error", message: "Invalid descriptionId format" });
      }

      const [results] = await db.query("SELECT * FROM electrical_types WHERE descriptionId = ?", [descriptionId]);

      if (results.length === 0) {
        return res.status(404).json({ status: "error", message: `No types found for descriptionId: ${descriptionId}` });
      }

      console.log("Fetched types:", results); // ✅ Debug Log
      res.json(results);
    }));

    // ✅ Add a new type (Ensure descriptionId is provided)
    router.post("/types", validateRequestBody(["descriptionId", "type"]), asyncHandler(async (req, res) => {
      const { descriptionId, type } = req.body;
      const [results] = await db.query("INSERT INTO electrical_types (descriptionId, type) VALUES (?, ?)", [descriptionId, type]);
      res.status(201).json({ message: "Type added successfully", id: results.insertId });
    }));

    // ✅ Update an existing type
    router.put("/types/:id", validateId, validateRequestBody(["type"]), asyncHandler(async (req, res) => {
      const { id } = req.params;
      const { type } = req.body;

      const [result] = await db.query("UPDATE electrical_types SET type = ? WHERE typeId = ?", [type, id]);
      if (result.affectedRows === 0) return res.status(404).json({ error: "Type not found" });

      res.json({ message: "Type updated successfully" });
    }));

    // ✅ Delete a type
    router.delete("/types/:id", validateId, asyncHandler(async (req, res) => {
      const { id } = req.params;

      const [result] = await db.query("DELETE FROM electrical_types WHERE typeId = ?", [id]);
      if (result.affectedRows === 0) return res.status(404).json({ error: "Type not found" });

      res.json({ message: "Type deleted successfully" });
    }));

  /** 📌 **Light Types API** *****************************************************************************/
    // ✅ Fetch all Light type
    router.get("/light-types", asyncHandler(async (req, res) => {
      const [results] = await db.query("SELECT * FROM electrical_light_types ORDER BY typeId DESC");
      res.json(results);
      }));

    // ✅ Fetch Light type based on a typeId
    router.get("/light-types/:typeId", asyncHandler(async (req, res) => {
       const { typeId } = req.params;
       console.log(`Fetching types for typeId: ${typeId}`); // ✅ Debugging Log

       // Ensure typeId is a number
       if (!/^[0-9]+$/.test(typeId)) {
         return res.status(400).json({ status: "error", message: "Invalid typeId format" });
       }

       const [results] = await db.query("SELECT * FROM electrical_light_types WHERE typeId = ?", [typeId]);

       if (results.length === 0) {
       return res.status(404).json({ status: "error", message: `No types found for typeId: ${typeId}` });
       }

       console.log("Fetched types:", results); // ✅ Debug Log
       res.json(results);
       }));

       // ✅ Add a new Light type (Ensure typeId is provided)
       router.post("/light-types", validateRequestBody(["typeId", "lightType"]), asyncHandler(async (req, res) => {
       const { typeId, lightType } = req.body;
       const [results] = await db.query("INSERT INTO electrical_light_types (typeId, lightType) VALUES (?, ?)", [typeId, lightType]);
       res.status(201).json({ message: "Light Type added successfully", id: results.insertId });
       }));

       // ✅ Update an existing Light type
       router.put("/light-types/:lightTypeId", validateId, validateRequestBody(["lightType"]), asyncHandler(async (req, res) => {
         const { lightTypeId } = req.params;  // ✅ Correct variable name
         const { lightType } = req.body;

         const [result] = await db.query("UPDATE electrical_light_types SET lightType = ? WHERE lightTypeId = ?", [lightType, lightTypeId]);
         if (result.affectedRows === 0) return res.status(404).json({ error: "Light Type not found" });

         res.json({ message: "✅ Light Type updated successfully" });
       }));

       // ✅ Delete a Light type
       router.delete("/light-types/:lightTypeId", validateId, asyncHandler(async (req, res) => {
         const { lightTypeId } = req.params;  // ✅ Correct variable name

         const [result] = await db.query("DELETE FROM electrical_light_types WHERE lightTypeId = ?", [lightTypeId]);
         if (result.affectedRows === 0) return res.status(404).json({ error: "Light Type not found" });

         res.json({ message: "✅ Light Type deleted successfully" });
       }));

  /** 📌 **Light Details API** *****************************************************************************/
      // ✅ Fetch all types
      router.get("/light-details", asyncHandler(async (req, res) => {
        const [results] = await db.query("SELECT * FROM electrical_light_details ORDER BY lightTypeId DESC");
        res.json(results);
        }));

      // ✅ Fetch types based on a descriptionId
      router.get("/light-details/:lightTypeId", asyncHandler(async (req, res) => {
         const { lightTypeId } = req.params;
         console.log(`Fetching types for typeId: ${lightTypeId}`); // ✅ Debugging Log

         // Ensure descriptionId is a number
         if (!/^[0-9]+$/.test(lightTypeId)) {
           return res.status(400).json({ status: "error", message: "Invalid typeId format" });
         }

         const [results] = await db.query("SELECT * FROM electrical_light_details WHERE lightTypeId = ?", [lightTypeId]);

         if (results.length === 0) {
         return res.status(404).json({ status: "error", message: `No types found for lightTypeId: ${lightTypeId}` });
         }

         console.log("Fetched types:", results); // ✅ Debug Log
         res.json(results);
         }));

         // ✅ Add a new type (Ensure descriptionId is provided)
         router.post("/light-details", validateRequestBody(["lightTypeId", "lightName",	"materialRate",	"labourRate", "boqMaterialRate", "boqLabourRate"]), asyncHandler(async (req, res) => {
         const { lightTypeId, lightName, materialRate, labourRate, boqMaterialRate, boqLabourRate } = req.body;
         const [results] = await db.query("INSERT INTO electrical_light_details (lightTypeId, lightName, materialRate, labourRate, boqMaterialRate, boqLabourRate) VALUES (?, ?, ?, ?, ?, ?)",
                           [lightTypeId, lightName, materialRate, labourRate, boqMaterialRate, boqLabourRate]);
         res.status(201).json({ message: "Light Details added successfully", id: results.insertId });
         }));

         // ✅ Update an existing type
         router.put("/light-details/:lightTypeId", validateId, validateRequestBody(["lightName, materialRate, labourRate, boqMaterialRate, boqLabourRate"]), asyncHandler(async (req, res) => {
         const { lightDetailsId } = req.params;
         const { lightName, materialRate, labourRate, boqMaterialRate, boqLabourRate } = req.body;

         const [result] = await db.query(
         "UPDATE electrical_light_details SET lightName = ?, materialRate = ?, labourRate = ?, boqMaterialRate = ?, boqLabourRate = ? WHERE lightDetailsId = ?",
         [lightName, materialRate, labourRate, boqMaterialRate, boqLabourRate, lightDetailsId]
         );

         if (result.affectedRows === 0) return res.status(404).json({ error: "Light Details not found" });
         res.json({ message: "Light Details updated successfully" });
         }));

         // ✅ Delete a type
         router.delete("/light-details/:lightDetailsId", validateId, asyncHandler(async (req, res) => {
           const { lightDetailsId } = req.params;  // ✅ Correct parameter name

           const [result] = await db.query("DELETE FROM electrical_light_details WHERE lightDetailsId = ?", [lightDetailsId]);
           if (result.affectedRows === 0) return res.status(404).json({ error: "Light Details Type not found" });

           res.json({ message: "✅ Light Details deleted successfully" });
      }));

  /** 📌 **Estimates API with Transactions** **/
  /*__________________________________________________________________________________*/
  /** ✅ Get Estimates with Pagination & Filtering */
    router.get("/estimates", asyncHandler(async (req, res) => {
      try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const offset = (page - 1) * limit;

        const [results] = await db.query(
          "SELECT * FROM electrical_estimates ORDER BY id DESC LIMIT ? OFFSET ?",
          [limit, offset]
        );

        const [[{ totalCount }]] = await db.query("SELECT COUNT(*) AS totalCount FROM electrical_estimates");

        res.json({
          page,
          limit,
          totalPages: Math.ceil(totalCount / limit),
          totalCount,
          estimates: results.length > 0 ? results : [], // ✅ Ensure a valid response format
        });
      } catch (error) {
        res.status(500).json({ error: "Failed to fetch estimates: " + error.message });
      }
    }));

    /** ✅ Get Single Estimate by ID */
    router.get("/estimates/:id", validateId, asyncHandler(async (req, res) => {
      const { id } = req.params;

      // Fetch estimate summary
      const [estimateResult] = await db.query(
        "SELECT * FROM electrical_estimates WHERE id = ?",
        [id]
      );

      if (estimateResult.length === 0) {
        return res.status(404).json({ error: "Estimate not found" });
      }

      // Fetch associated rows
      const [estimateRows] = await db.query(
        "SELECT * FROM electrical_estimate_rows WHERE estimateId = ?",
        [id]
      );

      res.json({
        estimate: estimateResult[0],
        rows: estimateRows.length > 0 ? estimateRows : [],
      });
    }));

    router.get("/latest/:customerId", async (req, res) => {
                const { customerId } = req.params;

                try {
                    if (!customerId) {
                        return res.status(400).json({ error: "Missing customerId" });
                    }

                    const [rows] = await db.query(
                        "SELECT version FROM electrical_estimates WHERE customerId = ? ORDER BY id DESC LIMIT 1",
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

    /** ✅ Create New Estimate with Associated Rows */
    router.post(
      "/save-estimates", authenticateToken,


      validateRequestBody(["customerId", "user_id", "customerName", "hike", "transport", "grandTotal", "version", "timestamp", "estimateType", "status", "stage", "rows"]),

      asyncHandler(async (req, res) => {
        const { customerId, user_id, customerName, hike, transport, grandTotal, version, estimateType, status, stage, timestamp, rows } = req.body;

        if (!Array.isArray(rows) || rows.length === 0) {
          return res.status(400).json({ error: "Rows must be a non-empty array" });
        }

        const connection = await db.getConnection();
        try {
          await connection.beginTransaction();

          // Insert new estimate
          const [estimateResult] = await connection.query(
            `INSERT INTO electrical_estimates (customerId, user_id, customerName, hike, transport, grandTotal, version, estimateType, status, stage, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [customerId, user_id, customerName, hike, transport, grandTotal, version, estimateType, status, stage, timestamp]
          );

          const estimateId = estimateResult.insertId;

          // Insert rows
          const rowValues = rows.map(row => [
            estimateId, row.floor, row.room, row.additionalInfo, row.description, row.type,
            row.lightType, row.lightDetails, row.quantity, row.materialRate, row.labourRate,
            row.totalAmount, row.netAmount, row.boqMaterialRate, row.boqLabourRate, row.boqTotalAmount
          ]);

          await connection.query(
            `INSERT INTO electrical_estimate_rows
            (estimateId, floor, room, additionalInfo, description, type, lightType, lightDetails,
            quantity, materialRate, labourRate, totalAmount, netAmount, boqMaterialRate, boqLabourRate, boqTotalAmount)
            VALUES ?`, [rowValues]
          );

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
          res.status(201).json({ message: "✅ Estimate added successfully", estimateId });
        } catch (error) {
          await connection.rollback();
          res.status(500).json({ error: "❌ Transaction failed: " + error.message });
        } finally {
          connection.release();
        }
      })
    );

    /** ✅ Update Existing Estimate */
    router.put(
      "/estimates/:id",
      validateId,
      validateRequestBody(["customerId", "customerName", "hike", "transport", "grandTotal", "version", "timestamp", "rows"]),
      asyncHandler(async (req, res) => {
        const { id } = req.params;
        const { customerId, customerName, hike, transport, grandTotal, version, timestamp, rows } = req.body;

        if (!Array.isArray(rows) || rows.length === 0) {
          return res.status(400).json({ error: "Rows must be a non-empty array" });
        }

        const connection = await db.getConnection();
        try {
          await connection.beginTransaction();

          // Update estimate details
          await connection.query(
            `UPDATE electrical_estimates
            SET customerId=?, customerName=?, hike=?, transport=?, grandTotal=?, version=?, timestamp=?
            WHERE id=?`, [customerId, customerName, hike, transport, grandTotal, version, timestamp, id]
          );

          // Delete old rows and insert updated rows
          await connection.query("DELETE FROM electrical_estimate_rows WHERE estimateId = ?", [id]);

          const rowValues = rows.map(row => [
            id, row.floor, row.room, row.additionalInfo, row.description, row.type,
            row.lightType, row.lightDetails, row.quantity, row.materialRate, row.labourRate,
            row.totalAmount, row.netAmount, row.boqMaterialRate, row.boqLabourRate, row.boqTotalAmount
          ]);

          await connection.query(
            `INSERT INTO electrical_estimate_rows
            (estimateId, floor, room, additionalInfo, description, type, lightType, lightDetails,
            quantity, materialRate, labourRate, totalAmount, netAmount, boqMaterialRate, boqLabourRate, boqTotalAmount)
            VALUES ?`, [rowValues]
          );

          await connection.commit();
          res.json({ message: "✅ Estimate updated successfully" });
        } catch (error) {
          await connection.rollback();
          res.status(500).json({ error: "❌ Update transaction failed: " + error.message });
        } finally {
          connection.release();
        }
      })
    );

    /** ✅ Delete Estimate & Associated Rows */
    router.delete(
      "/estimates/:id",
      validateId,
      asyncHandler(async (req, res) => {
        const { id } = req.params;
        const connection = await db.getConnection();

        try {
          await connection.beginTransaction();

          // Check if estimate exists
          const [estimateCheck] = await connection.query("SELECT id FROM electrical_estimates WHERE id = ?", [id]);

          if (estimateCheck.length === 0) {
            return res.status(404).json({ error: "Estimate not found" });
          }

          // Delete estimate rows first
          await connection.query("DELETE FROM electrical_estimate_rows WHERE estimateId = ?", [id]);

          // Then delete the estimate
          await connection.query("DELETE FROM electrical_estimates WHERE id = ?", [id]);

          await connection.commit();
          res.json({ message: "✅ Estimate deleted successfully" });
        } catch (error) {
          await connection.rollback();
          res.status(500).json({ error: "❌ Delete transaction failed: " + error.message });
        } finally {
          connection.release();
        }
      })
    );

  /** 📌 **Dropdown APIs for UI** **/
  router.get("/dropdown/descriptions", asyncHandler(async (req, res) => {
    const [results] = await db.query("SELECT descriptionId, description FROM electrical_description ORDER BY descriptionId DESC");
    res.json(results);
  }));

  router.get("/dropdown/types/:descriptionId", validateId, asyncHandler(async (req, res) => {
    const { descriptionId } = req.params;
    const [results] = await db.query("SELECT typeId, type FROM electrical_types WHERE descriptionId = ?", [descriptionId]);
    res.json(results);
  }));

  // ✅ API Route to Fetch All Data
  router.get("/all-data", async (req, res) => {
    try {
      const [results] = await db.query(`
        SELECT
          d.description,
          t.type,
          lt.lightType,
          ld.lightName,
          ld.materialRate,
          ld.labourRate,
          ld.boqMaterialRate,
          ld.boqLabourRate
        FROM electrical_description d
        JOIN electrical_types t ON d.descriptionId = t.descriptionId
        JOIN electrical_light_types lt ON t.typeId = lt.typeId
        JOIN electrical_light_details ld ON lt.lightTypeId = ld.lightTypeId
        ORDER BY d.descriptionId DESC
      `);
      res.json(results);
    } catch (error) {
      res.status(500).json({ error: "Database error: " + error.message });
    }
  });


  return router;
};
