require('dotenv').config(); // Load environment variables from .env
const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const path = require("path");
const bcrypt = require('bcrypt'); //
const http = require("http");
const { Server } = require("socket.io");






const app = express();
const PORT = process.env.SERVER_PORT || 4001;
const server = http.createServer(app);
const io = new Server(server);
io.on("connection", (socket) => {
  console.log("🟢 User connected:", socket.id);

  socket.on("join_room", (roomId) => {
    console.log(`📥 Joining room: room_${roomId}`);
    socket.join(`room_${roomId}`);
  });

  socket.on("send_message", (data) => {
    console.log("📤 Broadcasting to room:", data.roomId, data);
    io.to(`room_${data.roomId}`).emit("receive_message", data);
  });

  socket.on("disconnect", () => {
    console.log("🔴 User disconnected:", socket.id);
  });
});

const corsOptions = {
  origin: '*', // Allow requests from Flutter frontend
  methods: 'GET, POST, PUT, DELETE, OPTIONS, PATCH,',
  allowedHeaders: 'Content-Type, Authorization'
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Handle preflight requests
// ✅ Middleware
//app.use(cors());//live server
app.use((req, res, next) => {
   res.header("Access-Control-Allow-Origin", "*");
   res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH");
   res.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
   next();
 });
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// ✅ MySQL Database Connection
const db = mysql.createPool({
  connectionLimit: 10,
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT
}).promise();



module.exports = db;
// ✅ Test MySQL Connection
db.getConnection()
  .then(() => console.log("✅ Connected to MySQL Database!"))
  .catch((err) => console.error("❌ Database Connection Failed:", err));

// ✅ API Route Imports
const wallpaperRoutes = require("./wallpaper_api");
app.use("/api/wallpaper", wallpaperRoutes(db));

const coreWoodworkRoutes = require("./core_woodwork");
app.use("/api/core-woodwork", coreWoodworkRoutes(db));

const materialRoutes = require("./material_api");
app.use("/api/material", materialRoutes(db));

const eEstimateRoutes = require("./e_estimate_api");
app.use("/api/e-estimate", eEstimateRoutes(db));

const graniteRoutes = require("./granite_estimate_api");
app.use("/api/granite", graniteRoutes(db));

const quartzRoutes = require("./quartz_estimate_api");
app.use("/api", quartzRoutes(db));

const weinscoatingRoutes = require("./weinscoating_api");
app.use("/api/weinscoating", weinscoatingRoutes(db));

const charcoalRoutes = require("./charcoal_api");
app.use("/api/charcoal", charcoalRoutes(db));

const falseCeilingRoutes = require("./false_ceiling_api");
app.use("/api/false-ceiling", falseCeilingRoutes(db));

const customerEstimateRoutes = require("./customer_estimate_api");
app.use("/api/customer", customerEstimateRoutes(db));

const woodworkEstimateRoutes = require("./woodwork_estimate_api");
app.use("/api", woodworkEstimateRoutes(db));

const userRoutes = require('./user_api');
app.use('/api/user', userRoutes(db));

const loginRouter = require("./login");
app.use('/api',loginRouter(db));

const salesRouter = require("./sales_users_api");
app.use('/api', salesRouter(db));

const adminRouter = require("./super_admin_api");
app.use('/api', adminRouter(db));

const GrassRoutes = require("./grass_api");
app.use("/api", GrassRoutes(db));

const MosquitoRoutes = require("./mosquitoNet_api");
app.use("/api/mosquito", MosquitoRoutes(db));

const FlooringRoutes = require("./flooring_database");
app.use("/api", FlooringRoutes(db));

const NotificationsRoutes = require("./Notifications");
app.use("/api", NotificationsRoutes(db));

const ChatRouters = require("./chatRouter.js");
app.use("/api/chat", ChatRouters(db));

// ✅ Sample API Route
app.get("/", (req, res) => {
  res.send("✅ Node.js Backend is running!");
});

// ✅ Start the Server
server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server with WebSocket running at http://localhost:${PORT}/`);
});



// -------------------------------------------
// ✅ Customer API Routes
// -------------------------------------------

// ✅ Fetch all customers
app.get("/api/customers", async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 30;
    const offset = (page - 1) * limit;

    const [results] = await db.query(
      "SELECT * FROM customers LIMIT ? OFFSET ?",
      [limit, offset]
    );

    const [totalCount] = await db.query("SELECT COUNT(*) AS count FROM customers");
    const totalCustomers = totalCount[0].count;

    res.json({
      customers: results,
      totalCustomers,
      totalPages: Math.ceil(totalCustomers / limit),
      currentPage: page
    });

  } catch (error) {
    console.error("❌ Database query failed:", error);
    res.status(500).json({ error: "Database query failed" });
  }
});

// ✅ Fetch a specific customer by ID
app.get("/api/customers/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await db.query("SELECT * FROM customers WHERE id = ?", [id]);

    if (results.length === 0) {
      return res.status(404).json({ error: "Customer not found" });
    }
    res.json(results[0]);
  } catch (error) {
    console.error("❌ Database error:", error);
    res.status(500).json({ error: "Database error" });
  }
});

app.post("/api/customers", async (req, res) => {
  try {
    console.log("Incoming Request Body:", req.body); // Debugging log

    const { name, email, phone, altPhone, type } = req.body;
    const { street, city, postalCode } = req.body.address || {};
    const { siteStreet, siteCity, sitePostalCode, projectName, projectType } = req.body.siteDetails || {};

//    if (!name || !email || !phone || !altPhone || !street || !city || !postalCode ||
//        !siteStreet || !siteCity || !sitePostalCode || !projectName || !projectType || !type) {
//      return res.status(400).json({ error: "All fields are required" });
//    }

    const [results] = await db.query(
      "INSERT INTO customers (name, email, phone, altPhone, street, city, postalCode, siteStreet, siteCity, sitePostalCode, projectName, projectType, type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [name, email, phone, altPhone, street, city, postalCode, siteStreet, siteCity, sitePostalCode, projectName, projectType, type]
    );

    res.status(201).json({ message: "✅ Customer added successfully!", customerId: results.insertId });
  } catch (error) {
    console.error("❌ Database error:", error);
    res.status(500).json({ error: "Database error" });
  }
});


// ✅ Update a customer
app.put("/api/customers/:id", async (req, res) => {
  try {
    console.log("Incoming Update Request Body:", req.body); // 🔍 Debugging log
    const { id } = req.params;
    const updates = req.body;

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: "At least one field is required for update" });
    }

    const [results] = await db.query(
      "UPDATE customers SET ? WHERE id = ?",
      [updates, id]
    );

    if (results.affectedRows === 0) {
      return res.status(404).json({ error: "Customer not found" });
    }

    res.json({ message: "✅ Customer updated successfully!" });
  } catch (error) {
    console.error("❌ Database error:", error);
    res.status(500).json({ error: "Database error" });
  }
});
app.get('/api/customer-info/:customerId', async (req, res) => {
  const customerId = req.params.customerId;

  try {
    const [rows] = await db.query(
      'SELECT id, name, email, phone FROM customers WHERE id = ?',
      [customerId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Customer not found' });
    }

    res.json({
      success: true,
      data: rows[0],
    });
  } catch (error) {
    console.error('❌ Error fetching customer:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});
// ✅ Delete a customer
app.delete("/api/customers/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Soft delete by updating an "is_deleted" field instead of deleting
    const [results] = await db.query("UPDATE customers SET is_deleted = 1 WHERE id = ?", [id]);

    if (results.affectedRows === 0) {
      return res.status(404).json({ error: "Customer not found" });
    }

    res.json({ message: "✅ Customer marked as deleted!" });
  } catch (error) {
    console.error("❌ Database error:", error);
    res.status(500).json({ error: "Database error" });
  }
});
// -------------------------------------------
// ✅ Estimate API Routes
// -------------------------------------------

// ✅ Get All Estimates
app.get("/api/estimates", async (req, res) => {
  try {
    const [results] = await db.query("SELECT * FROM estimates");
    res.json(results);
  } catch (error) {
    res.status(500).json({ error: "Database query failed" });
  }
});

// ✅ Add a New Estimate
app.post("/api/estimates", async (req, res) => {
  try {
    const { customer_id, estimate_type, amount } = req.body;

    if (!customerId || !estimate_type || !amount) {
      return res.status(400).json({ error: "All fields are required" });
    }

    const [results] = await db.query(
      "INSERT INTO estimates (customer_id, estimate_type, amount) VALUES (?, ?, ?)",
      [customer_id, estimate_type, amount]
    );

    res.status(201).json({ message: "✅ Estimate added!", estimateId: results.insertId });
  } catch (error) {
    res.status(500).json({ error: "Database error" });
  }
});

// ✅ Delete an Estimate
app.delete("/api/estimates/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const [results] = await db.query("DELETE FROM estimates WHERE id = ?", [id]);

    if (results.affectedRows === 0) {
      return res.status(404).json({ error: "Estimate not found" });
    }

    res.json({ message: "✅ Estimate deleted!" });
  } catch (error) {
    res.status(500).json({ error: "Database error" });
  }
});
