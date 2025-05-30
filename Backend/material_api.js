const express = require("express");

module.exports = (db) => {
  const router = express.Router();

  // ✅ Fetch all materials
  router.get("/all-material", async (req, res) => {
    try {
      const [results] = await db.query("SELECT * FROM woodwork_finish");
      res.json(results);
    } catch (error) {
      console.error("❌ Error fetching materials:", error);
      res.status(500).json({ error: "Failed to fetch materials" });
    }
  });

  // ✅ Add a new material
  router.post("/save-finish", async (req, res) => {
    try {
      console.log("📩 Received Material Data:", JSON.stringify(req.body, null, 2));

      const { type, unitType, finish, rate, dateAdded } = req.body;

      // Validate required fields
      if (!type || !unitType || !finish || !rate || !dateAdded) {
        console.error("🚨 Missing required fields:", { type, unitType, finish, rate, dateAdded });
        return res.status(400).json({ error: "Missing required fields" });
      }

      // Insert material into database
      const [result] = await db.query(
        "INSERT INTO woodwork_finish (type, unitType, finish, rate, dateAdded) VALUES (?, ?, ?, ?, ?)",
        [type, unitType, finish, rate, dateAdded]
      );

      console.log("✅ Material added with ID:", result.insertId);
      res.status(201).json({ message: "Material added successfully", id: result.insertId });

    } catch (error) {
      console.error("❌ Error adding material:", error);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
  });


  router.put("/all-material/:id", async (req, res) => {
    try {
      const { id } = req.params;
      const { type, unitType, finish, rate } = req.body;

      // Log the request body for debugging
      console.log("Received Request Body:", req.body);

      // Check if the material exists in the database
      const [rows] = await db.query(
        "SELECT * FROM woodwork_finish WHERE id = ?",
        [id]
      );
      if (rows.length === 0) {
        return res.status(404).json({ error: "Material not found" });
      }

      // Log the UPDATE query for debugging
      console.log("Executing UPDATE Query:",
        "UPDATE woodwork_finish SET type = ?, unitType = ?, finish = ?, rate = ? WHERE id = ?");
      console.log("With Values:", [type, unitType, finish, rate, id]);

      // Proceed with the update
      const [updateResult] = await db.query(
        "UPDATE woodwork_finish SET type = ?, unitType = ?, finish = ?, rate = ? WHERE id = ?",
        [type, unitType, finish, rate, id]
      );

      if (updateResult.affectedRows === 0) {
        return res.status(400).json({ error: "No changes made to material" });
      }

      res.json({ message: "Material updated successfully" });
    } catch (error) {
      console.error("Error updating material:", error); // Log the full error
      res.status(500).json({ error: error.message || "Failed to update material" });
    }
  });

  // ✅ Delete a material by ID
  router.delete("/:id", async (req, res) => {
    try {
      const { id } = req.params;
      await db.promise().query("DELETE FROM woodwork_finish WHERE id = ?", [id]);
      res.json({ message: "Material deleted" });
    } catch (error) {
      res.status(500).json({ error: "Failed to delete material" });
    }
  });

  // ✅ Fetch woodwork finish types and rates from a stored procedure
  router.get("/finishes", async (req, res) => {
    try {
      const [rows] = await db.query("CALL GetWoodworkFinishTypes();");

      // Process data into a structured format
      let unitMeasurements = {};
      rows[0].forEach((row) => {
        if (!unitMeasurements[row.unitType]) {
          unitMeasurements[row.unitType] = {};
        }
        unitMeasurements[row.unitType][row.finish] = parseFloat(row.rate);
      });

      res.json({ success: true, unitMeasurements });
    } catch (error) {
      console.error("Error fetching finishes:", error);
      res.status(500).json({ success: false, message: "Failed to fetch finishes" });
    }
  });

  router.post("/wooden-item", async (req, res) => {
    try {
      console.log("📩 Received Item Data:", JSON.stringify(req.body, null, 2));

      const { name, description } = req.body;

      // ✅ Validate required fields
      if (!name || !description) {
        console.error("🚨 Missing required fields:", { name, description });
        return res.status(400).json({ error: "Missing required fields" });
      }

      // ✅ Insert into database
      const [result] = await db.query(
        "INSERT INTO wooden_item (name, description) VALUES (?, ?)",
        [name, description]
      );

      console.log("✅ Item added with ID:", result.insertId);
      res.status(201).json({ message: "Item added successfully", id: result.insertId });

    } catch (error) {
      console.error("❌ Error adding item:", error);
      res.status(500).json({ error: "Internal Server Error", details: error.message });
    }
  });

router.get("/wooden-items", async (req, res) => {
  try {
    console.log("📩 Fetching wooden items...");
    const [results] = await db.query("SELECT * FROM wooden_item");

    if (results.length === 0) {
      console.warn("⚠️ No items found in the database");
    } else {
      console.log("✅ Wooden items fetched successfully:", results);
    }

    res.json(results); // ✅ Return JSON response
  } catch (error) {
    console.error("❌ Error fetching wooden items:", error);
    res.status(500).json({ error: "Failed to fetch wooden items", details: error.message });
  }
});
//  Fetch all available table types
router.get("/table-types", async (req, res) => {
  try {
    console.log("📡 Fetching table types...");

    // Fetch unique table types from your database
    const [rows] = await db.query("SELECT DISTINCT table_type FROM table_types");

    if (rows.length === 0) {
      console.warn("⚠️ No table types found in database.");
      return res.status(404).json({ error: "No table types available." });
    }

    const tableTypes = rows.map(row => row.table_type); // Extract values

    console.log("✅ Table Types Fetched:", tableTypes);
    res.json(tableTypes); // Send as an array
  } catch (error) {
    console.error("❌ Error fetching table types:", error);
    res.status(500).json({ error: "Failed to fetch table types", details: error.message });
  }
});
// Assuming you are using Express and MySQL
// Assuming you're using Express and MySQL (or MySQL-compatible database)
// Express API route to fetch matching parts based on the finish name
router.get("/matching-parts/:finish", async (req, res) => {
  try {
    const { finish } = req.params;  // Extract the finish name from URL parameter

    // Log the received finish parameter for debugging purposes
    console.log("Fetching matching parts for finish:", finish);

    // Query to fetch matching parts from the wooden_item_parts table
    const [results] = await db.promise().query(
      `SELECT
        wooden_item_parts.id,
        COALESCE(woodwork_finish.finish, 'No Finish') AS finish_name,
        wooden_item_parts.description,
        wooden_item_parts.type,
        wooden_item_parts.widthMm,
        wooden_item_parts.heightMm,
        wooden_item_parts.widthFeet,
        wooden_item_parts.heightFeet,
        wooden_item_parts.squareFeet,
        wooden_item_parts.quantity,
        wooden_item_parts.rate,
        wooden_item_parts.amount,
        wooden_item_parts.item_code,
        wooden_item_parts.mrp,
        wooden_item_parts.net_amount,
        wooden_item_parts.labour
      FROM wooden_item_parts
      LEFT JOIN woodwork_finish
        ON wooden_item_parts.woodwork_finish_id = woodwork_finish.id
      WHERE woodwork_finish.finish = ? OR wooden_item_parts.woodwork_finish_id IS NULL`, [finish]
    );

    // If no matching parts are found
    if (results.length === 0) {
      return res.status(404).json({ message: "No matching parts found." });
    }

    // Return the matching parts as a JSON response
    res.json(results);
  } catch (error) {
    // Log any errors for debugging
    console.error("Error fetching matching parts:", error);
    res.status(500).json({ error: "Failed to fetch matching parts", details: error.message });
  }
});



  return router;
};
