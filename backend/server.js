const express = require("express");
const mysql = require("mysql2/promise");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

console.log("🔧 开始启动后端服务...");

// 创建数据库连接池
let pool;
let dbConnected = false;

// 初始化数据库连接（异步，不阻塞启动）
async function initDatabase() {
  try {
    console.log("尝试连接数据库...");
    pool = mysql.createPool({
      host: process.env.DB_HOST || "mysql",
      port: parseInt(process.env.DB_PORT) || 3306,
      user: process.env.DB_USER || "serial_user",
      password: process.env.DB_PASSWORD || "user123456",
      database: process.env.DB_NAME || "serial_db",
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
    });
    
    // 测试连接
    const connection = await pool.getConnection();
    connection.release();
    dbConnected = true;
    console.log("✅ 数据库连接成功");
  } catch (error) {
    console.log("⚠️  数据库连接失败:", error.message);
    console.log("服务将继续运行，数据库连接将稍后重试");
    dbConnected = false;
  }
}

// ========== 路由定义 ==========

// 1. 健康检查（必须可用）
app.get('/health', (req, res) => {
  res.json({
    status: 'UP',
    service: 'backend',
    database: dbConnected ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  });
});

// 2. API 健康检查
app.get('/api/health', async (req, res) => {
  if (dbConnected) {
    try {
      await pool.query('SELECT 1');
      res.json({ success: true, message: "服务正常运行" });
    } catch (error) {
      res.status(500).json({ success: false, message: "数据库查询失败" });
    }
  } else {
    res.status(503).json({ success: false, message: "数据库未连接" });
  }
});

// 3. 产品列表
app.get('/api/products', async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ error: "数据库未连接" });
  }
  
  try {
    const [products] = await pool.execute("SELECT * FROM products ORDER BY name");
    res.json({ success: true, data: products });
  } catch (error) {
    console.error("获取产品列表错误:", error);
    res.status(500).json({ success: false, error: "服务器内部错误" });
  }
});

// 4. 序列号查询
app.get("/api/serial/:number", async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ error: "数据库未连接" });
  }
  
  try {
    const { number } = req.params;
    const [rows] = await pool.execute(
      "SELECT * FROM serial_numbers WHERE serial_number = ?",
      [number]
    );
    
    if (rows.length === 0) {
      res.json({ success: false, message: "序列号不存在" });
    } else {
      res.json({ success: true, data: rows[0] });
    }
  } catch (error) {
    console.error("序列号查询错误:", error);
    res.status(500).json({ success: false, error: "服务器内部错误" });
  }
});

// 5. 用户登录
app.post("/api/auth/login", async (req, res) => {
  if (!dbConnected) {
    return res.status(503).json({ error: "数据库未连接" });
  }
  
  try {
    const { username, password } = req.body;
    
    // 简单验证
    if (username === "admin" && password === "admin123") {
      const jwt = require("jsonwebtoken");
      const token = jwt.sign(
        { userId: 1, username: "admin" },
        process.env.JWT_SECRET || "serial_system_secret_2024",
        { expiresIn: "24h" }
      );
      res.json({ success: true, message: "登录成功", token });
    } else {
      res.json({ success: false, message: "用户名或密码错误" });
    }
  } catch (error) {
    console.error("登录错误:", error);
    res.status(500).json({ success: false, error: "服务器内部错误" });
  }
});

// ========== 启动服务 ==========
const PORT = process.env.PORT || 3000;

// 先启动服务，再初始化数据库
app.listen(PORT, async () => {
  console.log("=".repeat(40));
  console.log("🚀 后端服务启动成功！");
  console.log("📡 监听端口:", PORT);
  console.log("🌐 访问地址: http://localhost:" + PORT);
  console.log("=".repeat(40));
  console.log("🔗 可用端点:");
  console.log("  • GET /health");
  console.log("  • GET /api/health");
  console.log("  • GET /api/products");
  console.log("  • GET /api/serial/:number");
  console.log("  • POST /api/auth/login");
  console.log("=".repeat(40));
  
  // 异步初始化数据库
  initDatabase();
});

module.exports = app;
