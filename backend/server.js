const express = require("express");
const mysql = require("mysql2/promise");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");

const app = express();
app.use(cors());
app.use(express.json());

// 数据库连接池
const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || "serial_user",
  password: process.env.DB_PASSWORD || "user123456",
  database: process.env.DB_NAME || "serial_db",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// API响应格式
const apiResponse = (success, message, data = null) => ({
  success,
  message,
  data,
  timestamp: new Date().toISOString(),
});

// 健康检查
app.get("/api/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json(apiResponse(true, "服务正常运行", { status: "healthy" }));
  } catch (error) {
    res.status(500).json(apiResponse(false, "数据库连接失败"));
  }
});

// 获取产品列表
app.get("/api/products", async (req, res) => {
  try {
    const [products] = await pool.execute("SELECT * FROM products ORDER BY name");
    res.json(apiResponse(true, "获取成功", products));
  } catch (error) {
    console.error("获取产品列表错误:", error);
    res.status(500).json(apiResponse(false, "服务器内部错误"));
  }
});

// 序列号查询
app.get("/api/serial/:serialNumber", async (req, res) => {
  const { serialNumber } = req.params;
  const clientIp = req.ip || req.connection.remoteAddress;

  if (!serialNumber || serialNumber.trim() === "") {
    return res.status(400).json(apiResponse(false, "序列号不能为空"));
  }

  try {
    // 查询序列号详细信息
    const [serials] = await pool.execute(
      `SELECT
        s.*,
        p.name as product_name,
        p.code as product_code,
        p.manufacturer,
        p.description as product_description
      FROM serials s
      LEFT JOIN products p ON s.product_id = p.id
      WHERE s.serial_number = ?`,
      [serialNumber.trim()]
    );

    let result = "not_found";
    let responseData = null;

    if (serials.length > 0) {
      const serialData = serials[0];
      result = serialData.status;
      responseData = {
        serialNumber: serialData.serial_number,
        productName: serialData.product_name,
        productCode: serialData.product_code,
        manufacturer: serialData.manufacturer,
        batchNumber: serialData.batch_number || "",
        productionDate: serialData.production_date,
        expirationDate: serialData.expiration_date,
        status: serialData.status,
        customerName: serialData.customer_name,
        customerEmail: serialData.customer_email,
        purchaseDate: serialData.purchase_date || null,
        activatedAt: serialData.activated_at,
        notes: serialData.notes || "",
        created: serialData.created_at,
        lastUpdated: serialData.updated_at,
      };

      // 更新最后查询时间
      await pool.execute(
        "UPDATE serials SET updated_at = CURRENT_TIMESTAMP WHERE id = ?",
        [serialData.id]
      );
    }

    // 记录查询日志 - 修复版
    await pool.execute(
      "INSERT INTO query_logs (serial_number, query_ip, result) VALUES (?, ?, ?)",
      [serialNumber, clientIp, result]
    );

    if (serials.length === 0) {
      return res.status(404).json(apiResponse(false, "序列号不存在", { serialNumber }));
    }

    res.json(apiResponse(true, "查询成功", responseData));
  } catch (error) {
    console.error("查询序列号错误:", error);
    res.status(500).json(apiResponse(false, "服务器内部错误"));
  }
});

// 其他路由保持不变...
const PORT = process.env.PORT || 3000;

// 数据库连接测试
(async () => {
  try {
    const connection = await pool.getConnection();
    console.log("✅ 数据库连接成功");
    const [rows] = await connection.query("SELECT VERSION() as version");
    console.log("📊 MySQL版本:", rows[0].version);
    connection.release();

    app.listen(PORT, () => {
      console.log("=".repeat(40));
      console.log("🚀 序列号查询系统后端启动成功！");
      console.log("📡 监听端口:", PORT);
      console.log("🕐 启动时间:", new Date().toLocaleString("zh-CN"));
      console.log("🌐 API地址: http://localhost:" + PORT);
      console.log("📊 数据库: mysql:3306/serial_db");
      console.log("=".repeat(40));
      console.log("🔗 主要API端点:");
      console.log("  • 健康检查: GET /api/health");
      console.log("  • 序列号查询: GET /api/serial/:number");
      console.log("  • 产品列表: GET /api/products");
      console.log("  • 用户登录: POST /api/auth/login");
      console.log("  • 批量查询: POST /api/serial/batch");
      console.log("  • 管理接口: /api/admin/* (需要管理员权限)");
      console.log("=".repeat(40));
    });
  } catch (error) {
    console.error("❌ 数据库连接失败:", error.message);
    process.exit(1);
  }
})();
