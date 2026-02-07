# ============ 生产环境 Dockerfile ============
FROM node:18-alpine as builder

WORKDIR /app

# 复制 package 文件
COPY package*.json ./

# 安装生产依赖（不安装开发依赖）
RUN npm ci --only=production

# ============ 运行阶段 ============
FROM node:18-alpine

WORKDIR /app

# 从构建阶段复制 node_modules
COPY --from=builder /app/node_modules ./node_modules

# 复制应用代码
COPY . .

# 创建非root用户（安全考虑）
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
USER nodejs

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { \
    if(r.statusCode === 200) process.exit(0); else process.exit(1) \
  })" || exit 1

# 暴露端口
EXPOSE 3000

# 启动命令（生产环境）
CMD ["node", "server.js"]
