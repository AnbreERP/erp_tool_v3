//require('http').createServer((req, res)=>res.end('HEllO')).listen(9090)

require('dotenv').config(); // Load environment variables from .env

const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const path = require("path");

const app = express();
const PORT = 9090;


// 🔹 Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

// 🔹 MySQL Connection Using .env Variables
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: 9090
});

// 🔹 Test MySQL Connection
db.connect((err) => {
  if (err) {
    console.error("❌ Database Connection Failed:", err);
  } else {
    console.log("✅ Connected to MySQL Database!");
  }
});

// 🔹 Sample API Route
app.get("/", (req, res) => {
  res.send("Hello from Node.js Backend!");
});

// 🔹 Start the Server
app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}/`);
});

app.get("/api/customers", (req, res) => {
  db.query("SELECT * FROM customers", (err, results) => {
    if (err) {
      res.status(500).json({ error: "Database query failed" });
    } else {
      res.json(results);
    }
  });
});




