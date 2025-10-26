// Initialize OpenTelemetry before importing any other modules
import './instrumentation';

import express from 'express';
import { appRouter } from './routes';

const port = process.env.PORT || 3333;
const app = express();

// Middleware
app.use(express.json());

// Routes
app.use(appRouter);

const server = app.listen(port, () => {
  console.log(`🚀 API Server listening at http://localhost:${port}`);
  console.log(`📊 Health check: http://localhost:${port}/api/health`);
  console.log(` Prometheus metrics: http://localhost:9090/metrics`);
});

server.on('error', console.error);
