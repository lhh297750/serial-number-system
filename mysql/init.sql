-- 序列号查询系统数据库初始化脚本 - 中文优化版
SET NAMES utf8mb4;

-- 创建数据库（指定字符集）
CREATE DATABASE IF NOT EXISTS serial_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE serial_db;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    role ENUM('admin', 'user') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 产品表
CREATE TABLE IF NOT EXISTS products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    manufacturer VARCHAR(100),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 序列号表
CREATE TABLE IF NOT EXISTS serials (
    id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    status ENUM('valid', 'used', 'expired') DEFAULT 'valid',
    production_date DATE,
    expiration_date DATE,
    customer_name VARCHAR(100),
    customer_email VARCHAR(100),
    activated_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 查询日志表
CREATE TABLE IF NOT EXISTS query_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    serial_number VARCHAR(100),
    query_ip VARCHAR(45),
    query_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入默认管理员
INSERT IGNORE INTO users (username, password, email, role) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMye7Z7dY8cB7eYV2bH.yY5v6R2B7xK1lW6', 'admin@example.com', 'admin');

-- 清空并重新插入中文产品数据
DELETE FROM products;
INSERT INTO products (name, code, description, manufacturer) VALUES
('智能手表专业版', 'SW-PRO-2024', '高端智能手表，支持健康监测和运动追踪', '科技巨人有限公司'),
('笔记本电脑精英版', 'NB-ELITE-X1', '商务办公笔记本电脑，超长续航', '计算大师科技有限公司'),
('软件许可证专业版', 'SW-LICENSE-PRO', '企业级软件许可证，包含技术支持', '软体股份有限公司'),
('云存储服务1TB', 'CLOUD-STORAGE-1TB', '安全可靠的云存储解决方案', '云端服务提供商'),
('智能安防摄像头', 'CAM-SMART-V2', '高清智能安防摄像头，支持夜视', '安防科技有限公司');

-- 清空并重新插入中文序列号数据
DELETE FROM serials;
INSERT INTO serials (product_id, serial_number, production_date, expiration_date, status, customer_name, customer_email) VALUES
(1, 'SN-WATCH-2024-001', '2024-01-15', '2026-01-15', 'valid', '张三科技有限公司', 'zhangsan@tech.com'),
(1, 'SN-WATCH-2024-002', '2024-01-15', '2026-01-15', 'used', '李四电子有限公司', 'lisi@electronics.com'),
(2, 'SN-NB-X1-001', '2024-02-01', '2025-02-01', 'valid', '王五信息科技有限公司', 'wangwu@info.com'),
(2, 'SN-NB-X1-002', '2024-02-01', '2025-02-01', 'expired', '赵六网络服务公司', 'zhaoliu@network.com'),
(3, 'SN-SW-PRO-001', '2024-03-01', '2025-03-01', 'valid', '测试用户一号', 'test1@example.com'),
(4, 'SN-CLOUD-001', '2024-04-01', '2025-04-01', 'valid', '云服务企业客户', 'cloud@enterprise.com'),
(5, 'SN-CAM-001', '2024-05-01', '2025-05-01', 'valid', '安防系统集成商', 'security@integration.com');

SELECT '✅ 数据库初始化完成（中文优化版）！' AS message;
