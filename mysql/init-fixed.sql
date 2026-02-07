-- 序列号查询系统数据库初始化脚本 - UTF8修复版
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

-- 序列号表（保持原名serials，创建别名serial_numbers视图）
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

-- 为兼容性创建视图（如果后端使用serial_numbers表名）
CREATE OR REPLACE VIEW serial_numbers AS
SELECT 
    id,
    product_id,
    serial_number,
    CASE status
        WHEN 'valid' THEN '有效'
        WHEN 'used' THEN '已使用'
        WHEN 'expired' THEN '已过期'
    END as status_chinese,
    status as status_english,
    production_date,
    expiration_date,
    customer_name,
    customer_email,
    activated_at,
    created_at,
    updated_at
FROM serials;

-- 查询日志表
CREATE TABLE IF NOT EXISTS query_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    serial_number VARCHAR(100),
    query_ip VARCHAR(45),
    query_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    result VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入中文测试数据
INSERT INTO users (username, password, email, role) VALUES
('admin', '$2a$10$N9qo8uLOickgx2ZMRZoMye7Z7dY8cB7eYV2bH.yY5v6R2B7xK1lW6', 'admin@example.com', 'admin'),
('testuser', '$2a$10$N9qo8uLOickgx2ZMRZoMye7Z7dY8cB7eYV2bH.yY5v6R2B7xK1lW6', 'user@example.com', 'user');

-- 插入中文产品数据
INSERT INTO products (name, code, description, manufacturer) VALUES
('智能手表专业版', 'SW-PRO-2024', '高端智能手表，支持健康监测', '科技巨人公司'),
('笔记本电脑精英版', 'NB-ELITE-X1', '商务办公笔记本电脑', '计算大师公司'),
('软件许可证专业版', 'SW-LICENSE-PRO', '企业级软件许可证', '软体公司'),
('云存储服务', 'CLOUD-STORAGE-1TB', '1TB云存储空间', '云服务提供商'),
('智能摄像头', 'CAM-SMART-V2', '高清智能安防摄像头', '安防科技公司');

-- 插入中文序列号数据
INSERT INTO serials (product_id, serial_number, production_date, expiration_date, status, customer_name, customer_email) VALUES
(1, 'SN-WATCH-2024-001', '2024-01-15', '2026-01-15', 'valid', '张三科技有限公司', 'zhangsan@tech.com'),
(1, 'SN-WATCH-2024-002', '2024-01-15', '2026-01-15', 'used', '李四电子公司', 'lisi@elec.com'),
(2, 'SN-NB-X1-001', '2024-02-01', '2025-02-01', 'valid', '王五信息科技', 'wangwu@info.com'),
(2, 'SN-NB-X1-002', '2024-02-01', '2025-02-01', 'expired', '赵六网络公司', 'zhaoliu@net.com'),
(3, 'SN-SW-PRO-001', '2024-03-01', '2025-03-01', 'valid', '测试用户一', 'test1@example.com'),
(4, 'SN-CLOUD-001', '2024-04-01', '2025-04-01', 'valid', '云服务用户', 'cloud@example.com'),
(5, 'SN-CAM-001', '2024-05-01', '2025-05-01', 'valid', '安防公司', 'security@example.com');

SELECT '✅ 数据库初始化完成（UTF-8修复版）！' AS message;
