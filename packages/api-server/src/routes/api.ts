import { Router } from 'express';

import { generateCPULoad } from 'src/utils/cpu-load';

export const router = Router();

// Health check endpoint for Kubernetes
router.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.npm_package_version || '1.0.0',
  });
});

router.get('/uptime', (req, res) => {
  res.json({
    uptime: process.uptime().toFixed(2),
  });
});

// CPU load testing endpoint for Kubernetes autoscaling tests.
router.get('/load-test', (_, res) => {
  const result = generateCPULoad();

  res.json(result);
});
