const express = require('express');
const router = express.Router();
const db = require('../db'); // MySQL connection

// API to save Wainscoting estimate
router.post('/saveWainscotingEstimate', async (req, res) => {
    const { customerId, customerName, transportCharges, gst, totalAmount, estimateType, estimateRows } = req.body;

    try {
        const [result] = await db.query(
            "CALL SaveWainscotingEstimate(?, ?, ?, ?, ?, ?, @newEstimateId); SELECT @newEstimateId AS estimateId;",
            [customerId, customerName, transportCharges, gst, totalAmount, estimateType]
        );

        const estimateId = result[1][0].estimateId; // Get the new estimateId

        // Insert estimate rows into MySQL
        for (const row of estimateRows) {
            await db.query(
                "INSERT INTO weinscoating_estimate_row (estimateId, description, length, width, area, panel, rate, laying, labour, amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                [
                    estimateId,
                    row.description,
                    row.length,
                    row.width,
                    row.area,
                    row.panel,
                    row.rate,
                    row.laying,
                    row.labour,
                    row.amount
                ]
            );
        }

        res.json({ success: true, message: "Estimate saved successfully", estimateId });
    } catch (error) {
        console.error("Error saving estimate:", error);
        res.status(500).json({ success: false, message: "Failed to save estimate" });
    }
});

// Fetch estimate details and rows using stored procedure
router.get('/fetchEstimate/:id', async (req, res) => {
    const estimateId = req.params.id;

    try {
        // Call the stored procedure
        const [estimateResult, fields] = await db.query("CALL FetchEstimateDetails(?)", [estimateId]);

        // Separate the results
        const estimate = estimateResult[0]?.[0] || null; // First query result (main estimate)
        const rows = estimateResult[1] || []; // Second query result (estimate rows)

        if (!estimate) {
            return res.status(404).json({ error: "Estimate not found" });
        }

        res.json({ estimate, rows });
    } catch (error) {
        console.error("Error fetching estimate details:", error);
        res.status(500).json({ error: "Failed to fetch estimate details" });
    }
});


module.exports = router;
