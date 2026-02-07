<template>
  <div class="container">
    <!-- 头部 -->
    <header class="header">
      <h1>🔍 序列号查询系统</h1>
      <div class="user-info" v-if="user">
        欢迎，{{ user.username }} ({{ user.role === 'admin' ? '管理员' : '用户' }})
        <button @click="logout" class="logout-btn">退出</button>
      </div>
      <button v-else @click="showLogin = true" class="login-btn">管理员登录</button>
    </header>

    <!-- 登录模态框 -->
    <div v-if="showLogin" class="modal-overlay">
      <div class="modal">
        <h2>管理员登录</h2>
        <div class="form-group">
          <input v-model="loginForm.username" placeholder="用户名" />
        </div>
        <div class="form-group">
          <input v-model="loginForm.password" type="password" placeholder="密码" />
        </div>
        <div class="modal-buttons">
          <button @click="handleLogin" class="btn-primary">登录</button>
          <button @click="showLogin = false" class="btn-secondary">取消</button>
        </div>
        <p class="hint">测试账号：admin / admin123</p>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <main class="main-content">
      <!-- 查询区域 -->
      <section class="search-section">
        <div class="search-box">
          <input 
            v-model="searchInput" 
            @keyup.enter="searchSerial"
            placeholder="请输入序列号进行查询..."
            class="search-input"
          />
          <button @click="searchSerial" class="search-btn">查询</button>
          <button @click="clearSearch" class="clear-btn">清空</button>
        </div>
        <div class="examples">
          <p>📋 示例序列号：</p>
          <div class="example-list">
            <span v-for="example in examples" :key="example" @click="useExample(example)" class="example-item">
              {{ example }}
            </span>
          </div>
        </div>
      </section>

      <!-- 查询结果 -->
      <section v-if="loading" class="loading-section">
        <div class="loading-spinner"></div>
        <p>查询中...</p>
      </section>

      <section v-else-if="searchResult" class="result-section">
        <div class="result-card" :class="getStatusClass(searchResult.status)">
          <h3>查询结果</h3>
          
          <div v-if="searchResult.success">
            <div class="result-row">
              <span class="label">序列号：</span>
              <span class="value">{{ searchResult.data.serialNumber }}</span>
            </div>
            <div class="result-row">
              <span class="label">产品名称：</span>
              <span class="value">{{ searchResult.data.productName || '未知' }}</span>
            </div>
            <div class="result-row">
              <span class="label">产品编码：</span>
              <span class="value">{{ searchResult.data.productCode || '未知' }}</span>
            </div>
            <div class="result-row">
              <span class="label">状态：</span>
              <span class="status-badge">{{ getStatusText(searchResult.data.status) }}</span>
            </div>
            <div v-if="searchResult.data.productionDate" class="result-row">
              <span class="label">生产日期：</span>
              <span class="value">{{ formatDate(searchResult.data.productionDate) }}</span>
            </div>
            <div v-if="searchResult.data.expirationDate" class="result-row">
              <span class="label">过期日期：</span>
              <span class="value">{{ formatDate(searchResult.data.expirationDate) }}</span>
            </div>
            <div v-if="searchResult.data.customerName" class="result-row">
              <span class="label">客户姓名：</span>
              <span class="value">{{ searchResult.data.customerName }}</span>
            </div>
            <div v-if="searchResult.data.activatedAt" class="result-row">
              <span class="label">激活时间：</span>
              <span class="value">{{ formatDateTime(searchResult.data.activatedAt) }}</span>
            </div>
            <div v-if="searchResult.data.lastUpdated" class="result-row">
              <span class="label">最后查询：</span>
              <span class="value">{{ formatDateTime(searchResult.data.lastUpdated) }}</span>
            </div>
          </div>
          
          <div v-else class="error-result">
            <p class="error-text">❌ {{ searchResult.error }}</p>
            <p v-if="searchResult.serialNumber">序列号：{{ searchResult.serialNumber }}</p>
          </div>
        </div>
      </section>

      <!-- 产品列表 -->
      <section class="products-section">
        <h2>📦 产品列表</h2>
        <div class="products-grid">
          <div v-for="product in products" :key="product.id" class="product-card">
            <h3>{{ product.name }}</h3>
            <p class="product-code">{{ product.code }}</p>
            <p class="product-desc">{{ product.description }}</p>
            <p class="product-manufacturer">厂商：{{ product.manufacturer }}</p>
            <div class="product-status" :class="product.status">
              {{ product.status === 'active' ? '在售' : '停产' }}
            </div>
          </div>
        </div>
      </section>

      <!-- 管理员面板 -->
      <section v-if="user?.role === 'admin'" class="admin-section">
        <h2>👑 管理员面板</h2>
        <div class="admin-actions">
          <button @click="showAllSerials" class="admin-btn">查看所有序列号</button>
          <button @click="showStats" class="admin-btn">系统统计</button>
          <button @click="showAddSerial" class="admin-btn">添加序列号</button>
        </div>
        
        <!-- 所有序列号表格 -->
        <div v-if="showSerialsTable" class="serials-table">
          <h3>所有序列号 ({{ serials.length }})</h3>
          <table>
            <thead>
              <tr>
                <th>序列号</th>
                <th>产品</th>
                <th>状态</th>
                <th>创建时间</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="serial in serials" :key="serial.id">
                <td>{{ serial.serial_number }}</td>
                <td>{{ serial.product_name || '未分配' }}</td>
                <td :class="serial.status">{{ getStatusText(serial.status) }}</td>
                <td>{{ formatDateTime(serial.created_at) }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- 统计信息 -->
        <div v-if="showStatsInfo" class="stats-info">
          <h3>系统统计</h3>
          <div class="stats-grid">
            <div class="stat-card">
              <div class="stat-number">{{ stats?.serials?.total || 0 }}</div>
              <div class="stat-label">总序列号</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">{{ stats?.queries?.total || 0 }}</div>
              <div class="stat-label">总查询次数</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">{{ stats?.queries?.today || 0 }}</div>
              <div class="stat-label">今日查询</div>
            </div>
            <div class="stat-card">
              <div class="stat-number">{{ stats?.queries?.uniqueIPs || 0 }}</div>
              <div class="stat-label">唯一IP数</div>
            </div>
          </div>
        </div>
      </section>
    </main>

    <!-- 页脚 -->
    <footer class="footer">
      <p>序列号查询系统 &copy; 2024 | 后端API: http://localhost:3000</p>
      <p class="system-status">
        系统状态: 
        <span :class="systemStatus">{{ systemStatus === 'healthy' ? '正常' : '异常' }}</span>
        | 最后检查: {{ lastCheckTime }}
      </p>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

// API配置
const API_BASE = 'http://localhost:3000/api'

// 响应式数据
const searchInput = ref('')
const searchResult = ref(null)
const loading = ref(false)
const products = ref([])
const user = ref(null)
const showLogin = ref(false)
const loginForm = ref({ username: '', password: '' })
const serials = ref([])
const showSerialsTable = ref(false)
const showStatsInfo = ref(false)
const stats = ref(null)
const systemStatus = ref('unknown')
const lastCheckTime = ref('')

// 示例序列号
const examples = ref([
  'SN-WATCH-2024-001',
  'SN-WATCH-2024-002',
  'SN-NB-X1-001',
  'SN-SW-PRO-001'
])

// 初始化
onMounted(() => {
  loadProducts()
  checkSystemHealth()
  
  // 每30秒检查系统状态
  setInterval(checkSystemHealth, 30000)
})

// 方法
const searchSerial = async () => {
  if (!searchInput.value.trim()) {
    alert('请输入序列号')
    return
  }
  
  loading.value = true
  searchResult.value = null
  
  try {
    const response = await axios.get(`${API_BASE}/serial/${searchInput.value.trim()}`)
    searchResult.value = response.data
  } catch (error) {
    searchResult.value = error.response?.data || { error: '查询失败，请检查网络连接' }
  } finally {
    loading.value = false
  }
}

const clearSearch = () => {
  searchInput.value = ''
  searchResult.value = null
}

const useExample = (example) => {
  searchInput.value = example
  searchSerial()
}

const loadProducts = async () => {
  try {
    const response = await axios.get(`${API_BASE}/products`)
    products.value = response.data.data || response.data
  } catch (error) {
    console.error('加载产品失败:', error)
  }
}

const handleLogin = async () => {
  try {
    const response = await axios.post(`${API_BASE}/auth/login`, loginForm.value)
    user.value = response.data.data.user
    localStorage.setItem('token', response.data.data.token)
    showLogin.value = false
    loginForm.value = { username: '', password: '' }
  } catch (error) {
    alert(error.response?.data?.message || '登录失败')
  }
}

const logout = () => {
  user.value = null
  localStorage.removeItem('token')
  serials.value = []
  showSerialsTable.value = false
  showStatsInfo.value = false
}

const showAllSerials = async () => {
  try {
    const token = localStorage.getItem('token')
    const response = await axios.get(`${API_BASE}/admin/serials`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    serials.value = response.data.data.serials || response.data.data
    showSerialsTable.value = true
    showStatsInfo.value = false
  } catch (error) {
    alert('获取序列号失败: ' + (error.response?.data?.message || error.message))
  }
}

const showStats = async () => {
  try {
    const token = localStorage.getItem('token')
    const response = await axios.get(`${API_BASE}/admin/stats`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    stats.value = response.data.data
    showStatsInfo.value = true
    showSerialsTable.value = false
  } catch (error) {
    alert('获取统计失败: ' + (error.response?.data?.message || error.message))
  }
}

const showAddSerial = () => {
  alert('添加序列号功能开发中...')
}

const checkSystemHealth = async () => {
  try {
    const response = await axios.get(`${API_BASE}/health`)
    systemStatus.value = response.data.success ? 'healthy' : 'error'
    lastCheckTime.value = new Date().toLocaleTimeString('zh-CN')
  } catch (error) {
    systemStatus.value = 'error'
    lastCheckTime.value = new Date().toLocaleTimeString('zh-CN')
  }
}

// 工具函数
const getStatusClass = (status) => {
  const statusMap = {
    'valid': 'status-valid',
    'used': 'status-used',
    'expired': 'status-expired',
    'invalid': 'status-invalid'
  }
  return statusMap[status] || 'status-unknown'
}

const getStatusText = (status) => {
  const statusMap = {
    'valid': '有效',
    'used': '已使用',
    'expired': '已过期',
    'invalid': '无效'
  }
  return statusMap[status] || status
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  return new Date(dateString).toLocaleDateString('zh-CN')
}

const formatDateTime = (dateTimeString) => {
  if (!dateTimeString) return ''
  return new Date(dateTimeString).toLocaleString('zh-CN')
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  padding: 20px;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  background: white;
  border-radius: 15px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
  overflow: hidden;
}

/* 头部样式 */
.header {
  background: linear-gradient(135deg, #667eea 0%, #5a67d8 100%);
  color: white;
  padding: 1.5rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header h1 {
  font-size: 1.8rem;
  font-weight: 600;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 15px;
}

.logout-btn, .login-btn {
  background: rgba(255,255,255,0.2);
  border: 1px solid rgba(255,255,255,0.3);
  color: white;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.3s;
}

.logout-btn:hover, .login-btn:hover {
  background: rgba(255,255,255,0.3);
}

/* 模态框 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal {
  background: white;
  padding: 2rem;
  border-radius: 10px;
  width: 90%;
  max-width: 400px;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group input {
  width: 100%;
  padding: 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 16px;
}

.modal-buttons {
  display: flex;
  gap: 10px;
  margin-top: 1.5rem;
}

.btn-primary, .btn-secondary {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-secondary {
  background: #e2e8f0;
  color: #4a5568;
}

.hint {
  margin-top: 1rem;
  font-size: 14px;
  color: #718096;
  text-align: center;
}

/* 主要内容 */
.main-content {
  padding: 2rem;
}

/* 搜索区域 */
.search-section {
  margin-bottom: 2rem;
}

.search-box {
  display: flex;
  gap: 10px;
  margin-bottom: 1rem;
}

.search-input {
  flex: 1;
  padding: 15px;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  font-size: 16px;
  transition: border 0.3s;
}

.search-input:focus {
  border-color: #667eea;
  outline: none;
}

.search-btn, .clear-btn {
  padding: 15px 25px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 16px;
  font-weight: 500;
}

.search-btn {
  background: #48bb78;
  color: white;
}

.clear-btn {
  background: #e53e3e;
  color: white;
}

.examples {
  background: #f7fafc;
  padding: 1rem;
  border-radius: 8px;
}

.example-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 0.5rem;
}

.example-item {
  background: #edf2f7;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 14px;
  cursor: pointer;
  transition: background 0.3s;
}

.example-item:hover {
  background: #cbd5e0;
}

/* 加载状态 */
.loading-section {
  text-align: center;
  padding: 3rem;
}

.loading-spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* 查询结果 */
.result-section {
  margin-bottom: 2rem;
}

.result-card {
  background: #f7fafc;
  border-radius: 10px;
  padding: 1.5rem;
  border-left: 5px solid #48bb78;
}

.result-card.status-valid { border-left-color: #48bb78; }
.result-card.status-used { border-left-color: #ed8936; }
.result-card.status-expired { border-left-color: #e53e3e; }
.result-card.status-invalid { border-left-color: #9f7aea; }

.result-row {
  display: flex;
  margin-bottom: 0.8rem;
  padding-bottom: 0.8rem;
  border-bottom: 1px solid #e2e8f0;
}

.result-row:last-child {
  border-bottom: none;
  margin-bottom: 0;
  padding-bottom: 0;
}

.label {
  font-weight: 600;
  color: #4a5568;
  min-width: 120px;
}

.value {
  color: #2d3748;
  flex: 1;
}

.status-badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 500;
}

.status-valid .status-badge { background: #c6f6d5; color: #22543d; }
.status-used .status-badge { background: #feebc8; color: #744210; }
.status-expired .status-badge { background: #fed7d7; color: #742a2a; }
.status-invalid .status-badge { background: #e9d8fd; color: #44337a; }

.error-result {
  color: #e53e3e;
}

.error-text {
  font-size: 18px;
  margin-bottom: 0.5rem;
}

/* 产品列表 */
.products-section {
  margin-bottom: 2rem;
}

.products-section h2 {
  margin-bottom: 1rem;
  color: #2d3748;
}

.products-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 1rem;
}

.product-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1.5rem;
  transition: transform 0.3s, box-shadow 0.3s;
}

.product-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0,0,0,0.1);
}

.product-code {
  color: #667eea;
  font-weight: 600;
  margin: 0.5rem 0;
}

.product-desc {
  color: #718096;
  font-size: 14px;
  margin-bottom: 1rem;
}

.product-manufacturer {
  color: #4a5568;
  font-size: 14px;
  margin-bottom: 0.5rem;
}

.product-status {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}

.product-status.active { background: #c6f6d5; color: #22543d; }
.product-status.inactive { background: #fed7d7; color: #742a2a; }

/* 管理员面板 */
.admin-section {
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #f7fafc;
  border-radius: 10px;
}

.admin-section h2 {
  margin-bottom: 1rem;
  color: #2d3748;
}

.admin-actions {
  display: flex;
  gap: 10px;
  margin-bottom: 1.5rem;
}

.admin-btn {
  background: #667eea;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: background 0.3s;
}

.admin-btn:hover {
  background: #5a67d8;
}

/* 序列号表格 */
.serials-table {
  margin-top: 1rem;
}

.serials-table h3 {
  margin-bottom: 1rem;
  color: #4a5568;
}

table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

thead {
  background: #667eea;
  color: white;
}

th, td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid #e2e8f0;
}

tbody tr:hover {
  background: #f7fafc;
}

/* 统计信息 */
.stats-info {
  margin-top: 1rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 1rem;
  margin-top: 1rem;
}

.stat-card {
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  padding: 1.5rem;
  text-align: center;
  transition: transform 0.3s;
}

.stat-card:hover {
  transform: translateY(-5px);
}

.stat-number {
  font-size: 2rem;
  font-weight: 700;
  color: #667eea;
  margin-bottom: 0.5rem;
}

.stat-label {
  color: #718096;
  font-size: 14px;
}

/* 页脚 */
.footer {
  background: #2d3748;
  color: white;
  padding: 1.5rem 2rem;
  text-align: center;
}

.footer p {
  margin-bottom: 0.5rem;
}

.system-status {
  font-size: 14px;
  color: #a0aec0;
}

.system-status span {
  font-weight: 600;
}

.system-status span.healthy { color: #68d391; }
.system-status span.error { color: #fc8181; }
.system-status span.unknown { color: #a0aec0; }

/* 响应式设计 */
@media (max-width: 768px) {
  .header {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
  
  .search-box {
    flex-direction: column;
  }
  
  .search-input, .search-btn, .clear-btn {
    width: 100%;
  }
  
  .products-grid {
    grid-template-columns: 1fr;
  }
  
  .admin-actions {
    flex-direction: column;
  }
  
  .admin-btn {
    width: 100%;
  }
  
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  table {
    display: block;
    overflow-x: auto;
  }
}
</style>
