# 序列号管理系统

基于 Docker 的序列号生成和管理系统。

## 环境要求
- Docker 20.10+
- Docker Compose 2.0+

## 快速开始

### 1. 克隆项目
git clone https://github.com/lhh297750/serial-number-system.git
cd serial-number-system

### 2. 启动服务
docker-compose up -d

### 3. 查看服务状态
docker-compose ps

## 访问地址
- **前端应用**：http://localhost:8080
- **后端API**：http://localhost:3000
- **MySQL数据库**：localhost:3306

## 默认账户信息
### 数据库
- 用户名：serial_user
- 密码：user123456
- 数据库名：serial_db
- Root密码：root123456

### API认证
- JWT密钥：serial_system_secret_2024

## 项目结构
serial-number-system/
├── backend/              # Node.js后端
│   ├── server.js        # 主程序
│   ├── package.json     # 依赖配置
│   └── Dockerfile       # 容器配置
├── frontend/            # Vue.js前端
│   ├── src/            # 源代码
│   ├── package.json    # 依赖配置
│   ├── vite.config.js  # Vite配置
│   └── Dockerfile.dev  # 容器配置
├── mysql/               # 数据库
│   ├── init.sql        # 初始化脚本
│   └── conf.d/         # 配置目录
└── docker-compose.yml   # 服务编排

## 常用命令
### 启动服务
docker-compose up -d

### 停止服务
docker-compose down

### 查看日志
docker-compose logs -f

### 重启服务
docker-compose restart [服务名]

## 故障排除
### 端口冲突
修改 docker-compose.yml 中的端口映射

### 数据库连接失败
docker-compose logs mysql

## 许可证
MIT License
