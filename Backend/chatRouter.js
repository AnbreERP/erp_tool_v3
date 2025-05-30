const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");

module.exports = (db) => {
  //  Middleware to protect routes
  const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    console.log("🔐 Incoming Authorization:", authHeader);

    const token = authHeader?.split(" ")[1];
    if (!token) {
      console.log("❌ Token missing");
      return res.status(403).json({ error: "Token missing" });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (err) {
        console.log("❌ Invalid token", err);
        return res.status(403).json({ error: "Invalid token" });
      }
      req.user = user;
      next();
    });
  };


  router.post('/rooms', authenticateToken, async (req, res) => {
    const { name, isGroup, memberIds = [] } = req.body;
    const creatorId = req.user.userId;

    if (!name) return res.status(400).json({ error: 'Room name is required' });

    try {
      // 1. Insert room
      const [roomResult] = await db.query(
        `INSERT INTO chat_rooms (name, is_group, created_by) VALUES (?, ?, ?)`,
        [name, isGroup ? 1 : 0, creatorId]
      );
      const roomId = roomResult.insertId;

      // 2. Add creator to room
      const values = [[roomId, creatorId]];

      // 3. Add other members if group
      if (Array.isArray(memberIds)) {
        for (const memberId of memberIds) {
          if (memberId !== creatorId) {
            values.push([roomId, memberId]);
          }
        }
      }

      // 4. Bulk insert into chat_room_members
      await db.query(
        `INSERT INTO chat_room_members (room_id, user_id) VALUES ?`,
        [values]
      );

      return res.status(201).json({ roomId });
    } catch (err) {
      console.error("❌ Failed to create chat room:", err);
      return res.status(500).json({ error: 'Failed to create chat room' });
    }
  });


router.post('/messages', authenticateToken, async (req, res) => {
  const { roomId, message } = req.body;
  const senderId = req.user.userId;

  try {
    const [roomRows] = await db.query(
        `SELECT id FROM chat_rooms WHERE id = ?`,
        [roomId]
      );

      if (roomRows.length === 0) {
        return res.status(400).json({ error: 'Invalid room ID: Room does not exist' });
      }
    const [result] = await db.query(
      `INSERT INTO chat_messages (room_id, sender_id, message) VALUES (?, ?, ?)`,
      [roomId, senderId, message]
    );
    res.status(201).json({ messageId: result.insertId });
  } catch (err) {
    console.error('❌ Send message error:', err);
    res.status(500).json({ error: 'Internal error' });
  }
});

router.get('/rooms', authenticateToken, async (req, res) => {
  const userId = req.user.userId;

  try {
    const [rooms] = await db.query(
      `SELECT r.id, r.name, r.is_group
       FROM chat_rooms r
       JOIN chat_room_members m ON r.id = m.room_id
       WHERE m.user_id = ?`,
      [userId]
    );
    res.json(rooms);
  } catch (err) {
    res.status(500).json({ error: 'Internal error' });
  }
});

router.get('/messages/:roomId', authenticateToken, async (req, res) => {
  const roomId = req.params.roomId;
  console.log("📥 Message payload:", req.body, "Room ID:", roomId, "Sender:", req.user.userId);

  try {
    const [messages] = await db.query(
       `SELECT m.id, m.message, m.sender_id, m.room_id,
                    CONCAT(u.first_name, ' ', u.last_name) as sender_name,
                    m.sent_at
             FROM chat_messages m
             JOIN users u ON m.sender_id = u.id
             WHERE m.room_id = ?
             ORDER BY m.sent_at ASC`,
      [roomId]
    );

    res.json(messages);

  } catch (err) {
    console.error("❌ SQL Error in /messages/:roomId =>", err); // Add this line
    res.status(500).json({ error: 'Internal error' });
  }
});


router.post('/messages/:messageId/seen', authenticateToken, async (req, res) => {
  const messageId = req.params.messageId;
  const userId = req.user.userId;

  await db.query(
    `INSERT IGNORE INTO chat_seen_status (message_id, user_id) VALUES (?, ?)`,
    [messageId, userId]
  );
  res.status(200).json({ message: 'Marked as seen' });
});

router.post('/rooms/:roomId/members', authenticateToken, async (req, res) => {
  const roomId = req.params.roomId;
  const { memberIds } = req.body;

  if (!Array.isArray(memberIds)) {
    return res.status(400).json({ error: 'memberIds must be an array' });
  }

  try {
    const values = memberIds.map(userId => [roomId, userId]);
    await db.query(`INSERT IGNORE INTO chat_room_members (room_id, user_id) VALUES ?`, [values]);
    res.status(200).json({ message: 'Members added successfully' });
  } catch (err) {
    console.error("❌ Failed to add members:", err);
    res.status(500).json({ error: 'Internal error' });
  }
});

router.get('/users', authenticateToken, async (req, res) => {
  const userId = req.user.userId; // ✅ use the correct variable

  try {
    const [users] = await db.query(
      `SELECT id, CONCAT(first_name, ' ', last_name) AS name, email
       FROM users
       WHERE id != ?`,
      [userId]
    );
    res.json(users);
  } catch (err) {
    console.error("❌ Failed to fetch users:", err);
    res.status(500).json({ error: 'Internal error' });
  }
});

router.post('/private-room', authenticateToken, async (req, res) => {
  const { targetUserId } = req.body;
  const currentUserId = req.user.userId;

  try {
    // Check if room already exists
    const [existing] = await db.query(
      `SELECT r.id FROM chat_rooms r
       JOIN chat_room_members m1 ON r.id = m1.room_id
       JOIN chat_room_members m2 ON r.id = m2.room_id
       WHERE r.is_group = 0 AND m1.user_id = ? AND m2.user_id = ?`,
      [currentUserId, targetUserId]
    );

    if (existing.length > 0) {
      return res.json({ roomId: existing[0].id });
    }

    // Create room
    const [roomResult] = await db.query(
      `INSERT INTO chat_rooms (name, is_group, created_by) VALUES (?, 0, ?)`,
      [`Private Chat`, currentUserId]
    );

    const roomId = roomResult.insertId;

    // Add both users
    await db.query(
      `INSERT INTO chat_room_members (room_id, user_id) VALUES (?, ?), (?, ?)`,
      [roomId, currentUserId, roomId, targetUserId]
    );

    res.status(201).json({ roomId });
  } catch (err) {
    res.status(500).json({ error: 'Error creating private chat' });
  }
});
// ✅ Send message
router.post('/dm/send', authenticateToken, async (req, res) => {
  const { receiverId, message } = req.body;
  const senderId = req.user.userId;

  try {
    await db.query(
      "INSERT INTO direct_messages (sender_id, receiver_id, message) VALUES (?, ?, ?)",
      [senderId, receiverId, message]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("❌ DM Send Error:", err);
    res.status(500).json({ error: "Failed to send message" });
  }
});

// ✅ Fetch conversation
router.get('/dm/:userId', authenticateToken, async (req, res) => {
  const userId = req.user.userId;
  const otherId = req.params.userId;

  try {
    const [messages] = await db.query(`
      SELECT * FROM direct_messages
      WHERE (sender_id = ? AND receiver_id = ?)
         OR (sender_id = ? AND receiver_id = ?)
      ORDER BY sent_at ASC
    `, [userId, otherId, otherId, userId]);

    res.json(messages);
  } catch (err) {
    console.error("❌ Fetch DM Error:", err);
    res.status(500).json({ error: "Failed to fetch messages" });
  }
});
router.post('/rooms/:roomId/mark-seen', authenticateToken, async (req, res) => {
  const userId = req.user.userId;
  const roomId = req.params.roomId;

  try {
    const [messageIds] = await db.query(`
      SELECT m.id FROM chat_messages m
      LEFT JOIN chat_seen_status s
        ON m.id = s.message_id AND s.user_id = ?
      WHERE s.user_id IS NULL AND m.room_id = ?
    `, [userId, roomId]);

    if (messageIds.length === 0) return res.json({ updated: 0 });

    const values = messageIds.map(m => [m.id, userId]);
    await db.query(`INSERT IGNORE INTO chat_seen_status (message_id, user_id) VALUES ?`, [values]);

    res.json({ updated: values.length });
  } catch (err) {
    console.error("❌ Mark seen error:", err);
    res.status(500).json({ error: "Internal error" });
  }
});
router.get('/unread-count', authenticateToken, async (req, res) => {
  const userId = req.user.userId;

  try {
    const [rows] = await db.query(`
      SELECT m.room_id, COUNT(*) AS unread
      FROM chat_messages m
      LEFT JOIN chat_seen_status s
        ON m.id = s.message_id AND s.user_id = ?
      WHERE s.user_id IS NULL
      GROUP BY m.room_id
    `, [userId]);

    const counts = {};
    for (const row of rows) {
      counts[row.room_id] = row.unread;
    }

    res.json(counts);
  } catch (err) {
    console.error("❌ Error fetching unread count:", err);
    res.status(500).json({ error: "Internal error" });
  }
});
router.post('/dm/:senderId/mark-seen', authenticateToken, async (req, res) => {
  const receiverId = req.user.userId;
  const senderId = req.params.senderId;

  try {
    await db.query(
      `UPDATE direct_messages SET is_seen = 1
       WHERE sender_id = ? AND receiver_id = ? AND is_seen = 0`,
      [senderId, receiverId]
    );
    res.status(200).json({ message: 'DMs marked as seen' });
  } catch (err) {
    console.error("❌ DM mark seen error:", err);
    res.status(500).json({ error: 'Internal error' });
  }
});

    return router;
};