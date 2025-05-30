const express = require('express');
const jwt = require('jsonwebtoken');


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
      req.user = user; // Attach user data to request object
      next();
    });
  };

  // Sample route to get the customer count (using promise-based query)
   router.get("/customer-count", authenticateToken, async (req, res) => {
     try {
       // Use promise-based query
       const [rows] = await db.query("SELECT COUNT(*) AS count FROM customers");
       const customerCount = rows[0].count;
       res.status(200).json({ count: customerCount });
     } catch (err) {
       console.error("Error fetching customer count:", err);
       res.status(500).json({ message: "Failed to fetch customer count", error: err });
     }
   });

   // Sample route to get the user count (using promise-based query)
   router.get("/user-count", authenticateToken, async (req, res) => {
     try {
       // Use promise-based query
       const [rows] = await db.query("SELECT COUNT(*) AS count FROM users");
       const userCount = rows[0].count;
       res.status(200).json({ count: userCount });
     } catch (err) {
       console.error("Error fetching user count:", err);
       res.status(500).json({ message: "Failed to fetch user count", error: err });
     }
   });

  return router;
};
