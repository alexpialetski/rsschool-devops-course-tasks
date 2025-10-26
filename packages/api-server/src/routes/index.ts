import path from 'path';
import express from 'express';

import { router as apiRouter } from './api';

export const appRouter = express.Router();

const ASSETS_PATH = path.join(__dirname, 'assets');

appRouter.get('/', (_, res) => {
  res.sendFile(path.join(ASSETS_PATH, 'index.html'));
});

appRouter.use('/assets', express.static(ASSETS_PATH));

appRouter.use('/api', apiRouter);
