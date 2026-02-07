const express = require('express');
const router = express.Router();

// 简单的健康检查
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'UP',
    timestamp: new Date().toISOString(),
    service: 'serial-number-system-api',
    version: '1.0.0'
  });
});

module.exports = router;
