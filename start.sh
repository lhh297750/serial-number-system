#!/bin/bash
echo "🚀 启动序列号管理系统..."
docker-compose up -d
echo "✅ 服务启动完成"
echo ""
echo "🌐 访问地址："
echo "前端：http://localhost:8080"
echo "后端API：http://localhost:3000"
echo "数据库：localhost:3306"
echo ""
echo "📋 查看日志：docker-compose logs -f"
echo "🛑 停止服务：docker-compose down"
