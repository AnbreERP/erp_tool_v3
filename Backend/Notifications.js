//  routes/notificationRoutes.js
const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");

module.exports = (db) => {
  //  Middleware to protect routes
  const authenticateToken = (req, res, next) => {
    const token = req.headers["authorization"]?.split(" ")[1];
    if (!token) return res.status(403).json({ error: "Token missing" });

    const jwt = require("jsonwebtoken");
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (err) return res.status(403).json({ error: "Invalid token" });
      req.user = user;
      next();
    });
  };

  //  POST /api/notifications — create new notification
  router.post("/notifications", authenticateToken, async (req, res) => {
    const { user_id, title, message, type = "estimate" } = req.body;
    try {
      const [result] = await db.query(
        `INSERT INTO notifications (user_id, title, message, type)
         VALUES (?, ?, ?, ?)`,
        [user_id, title, message, type]
      );
      res.status(201).json({ id: result.insertId });
    } catch (error) {
      console.error(" Failed to create notification:", error);
      res.status(500).json({ error: "Notification creation failed" });
    }
  });

  //  GET /api/notifications?user_id=...
      router.get("/notifications", authenticateToken, async (req, res) => {
        const userId = req.query.user_id;

      if (!userId) {
        return res.status(400).json({ error: "Missing user_id query parameter" });
      }
        try {
          const [notifications] = await db.query(
            `SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC`,
            [userId]
          );
          res.status(200).json(notifications);
        } catch (error) {
          console.error(" Failed to fetch notifications:", error);
          res.status(500).json({ error: "Could not fetch notifications" });
        }
      });

  //  PATCH /api/notifications/:id/seen — mark one as seen
     router.patch("/notifications/:id/seen", authenticateToken, async (req, res) => {
       const { id } = req.params;

       try {
         const [result] = await db.query(
           `UPDATE notifications SET seen = 1 WHERE id = ?`,
           [id]
         );

         if (result.affectedRows > 0) {
           return res.status(200).json({ message: "Notification marked as seen" });
         } else {
           return res.status(404).json({ error: "Notification not found" });
         }
       } catch (error) {
         console.error(" Failed to mark as seen:", error);
         return res.status(500).json({ error: "Server error" });
       }
     });


  //  PATCH /api/notifications/mark-all — mark all as seen for user
     router.patch("/notifications/mark-all", authenticateToken, async (req, res) => {
       const userId = req.body.userId;

       if (!userId) {
         return res.status(400).json({ error: "Missing userId" });
       }

       try {
         const [result] = await db.query(
           `UPDATE notifications SET seen = 1 WHERE user_id = ?`,
           [userId]
         );

         return res.status(200).json({ message: `Marked ${result.affectedRows} as read` });
       } catch (err) {
         console.error(" Error marking notifications as read:", err);
         res.status(500).json({ error: "Server error" });
       }
     });
    router.delete("/notifications/:id", authenticateToken, async (req, res) => {
      const { id } = req.params;

      try {
        const [result] = await db.query(`DELETE FROM notifications WHERE id = ?`, [id]);

        if (result.affectedRows > 0) {
          return res.status(200).json({ message: "Notification deleted" });
        } else {
          return res.status(404).json({ error: "Notification not found" });
        }
      } catch (err) {
        console.error(" Delete error:", err);
        return res.status(500).json({ error: "Failed to delete notification" });
      }
    });
    router.delete("/notifications/clear-all", authenticateToken, async (req, res) => {
      const userId = req.user.userId;

      try {
        const [result] = await db.query(
          `DELETE FROM notifications WHERE user_id = ?`,
          [userId]
        );
        res.status(200).json({ message: `Deleted ${result.affectedRows} notifications` });
      } catch (err) {
        console.error("❌ Error clearing notifications:", err);
        res.status(500).json({ error: "Failed to clear notifications" });
      }
    });


  return router;
};
