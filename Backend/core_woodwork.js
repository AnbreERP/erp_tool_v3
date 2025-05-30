const express = require("express");

module.exports = (db) => {
  const router = express.Router();

  // ✅ Fetch all wooden items
router.get("/wooden-items", async (req, res) => {
  try {
    const [results] = await db.query("SELECT * FROM wooden_item");
    res.json(results);
  } catch (err) {
    console.error("❌ Error fetching wooden items:", err.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});


 // ✅ Get a wooden item by ID with dummy fallback
 router.get("/wooden-items/:id", (req, res) => {
   const { id } = req.params;
   db.query(
     "SELECT id, name FROM wooden_item WHERE id = ?",
     [id],
     (err, results) => {
       if (err) {
         console.error("❌ Error fetching wooden item:", err.message);
         return res.status(500).json({ error: "Internal Server Error" });
       }
       if (results.length === 0) {
         console.warn(`⚠️ Wooden item with ID ${id} not found. Returning dummy data.`);
         return res.status(200).json({
           id: parseInt(id),
           name: `Dummy Item ${id}`,
           description: "This is placeholder dummy data.",
         });
       }
       res.status(200).json(results[0]);
     }
   );
 });


  // ✅ Add a new wooden item
 router.post('/save-parts', (req, res) => {
   const parts = req.body.parts; // Get parts data from request body

   // Prepare the insert query
   const query = 'INSERT INTO wooden_item_parts (wooden_item_id, woodwork_finish_id, table_type, description, type, widthMm, heightMm, widthFeet, heightFeet, squareFeet, quantity, rate, amount, item_code, mrp, net_amount, labour) VALUES ?';

   const values = parts.map(part => [
     part.wooden_item_id,
     part.woodwork_finish_id,
     part.table_type,
     part.description,
     part.type,
     part.widthMm,
     part.heightMm,
     part.widthFeet,
     part.heightFeet,
     part.squareFeet,
     part.quantity,
     part.rate,
     part.amount,
     part.item_code,
     part.mrp,
     part.net_amount,
     part.labour
   ]);

   // Execute the query to insert parts data into the database
   db.query(query, [values], (err, result) => {
     if (err) {
       console.error('Error inserting data:', err);
       return res.status(500).json({ error: 'Failed to save data.' });
     }
     console.log('Data inserted successfully:', result);
     return res.status(201).json({ message: 'Data saved successfully!' });
   });
 });


  // ✅ Delete a wooden item by ID
  router.delete("/wooden-items/:id", (req, res) => {
    const { id } = req.params;
    db.query("DELETE FROM wooden_item WHERE id = ?", [id], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
      res.json({ message: "Wooden item deleted" });
    });
  });

router.get("/get-Finish-and-rate", async (req, res) => {
  try {
    const [results] = await db.query(
      "SELECT unitType, finish, rate FROM woodwork_finish"
    );
    res.status(200).json(results);
  } catch (err) {
    console.error("❌ Error fetching finishes:", err.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});


// ✅ Fetch all woodwork finishes
router.get("/woodwork-finishes", async (req, res) => {
  try {
    const [results] = await db.query("SELECT * FROM woodwork_finish");
    res.json(results);
  } catch (err) {
    console.error("❌ Error fetching woodwork finishes:", err.message);
    res.status(500).json({ error: "Internal Server Error" });
  }
});


  // ✅ Fetch item parts with finish details
  router.get("/wooden-item-parts/:woodenItemId", (req, res) => {
    const { woodenItemId } = req.params;
    db.query(
      `SELECT p.*, f.type AS finish_type, f.rate AS finish_rate
       FROM wooden_item_parts p
       JOIN woodwork_finish f ON p.woodwork_finish_id = f.id
       WHERE p.wooden_item_id = ?`,
      [woodenItemId],
      (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
      }
    );
  });
  // ✅ Add this to your Node.js backend
  router.get("/table-types", (req, res) => {
    res.json(["wooden", "accessory", "sliding"]);
  });

 // ✅ Save wooden item parts
  router.post("/save-parts", async (req, res) => {
    try {
      const { parts } = req.body;

      if (!Array.isArray(parts) || parts.length === 0) {
        return res.status(400).json({ message: "No parts provided" });
      }

      const insertPromises = parts.map((part) => {
        return db.query(
          `INSERT INTO wooden_item_parts
          (
            wooden_item_id, woodwork_finish_id, table_type, description, type,
            widthMm, heightMm, widthFeet, heightFeet, squareFeet,
            quantity, rate, amount, item_code, mrp, net_amount, labour
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            part.wooden_item_id,
            part.woodwork_finish_id,
            part.table_type,
            part.description,
            part.type,
            part.widthMm,
            part.heightMm,
            part.widthFeet,
            part.heightFeet,
            part.squareFeet,
            part.quantity,
            part.rate,
            part.amount,
            part.item_code,
            part.mrp,
            part.net_amount,
            part.labour,
          ]
        );
      });

      await Promise.all(insertPromises);

      res.status(201).json({ message: "Wooden item parts saved successfully!" });
    } catch (err) {
      console.error("❌ Error saving parts:", err.message);
      res.status(500).json({ error: "Failed to save parts" });
    }
  });

  return router;
};
