import fs from 'node:fs';
import path from 'node:path';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import morgan from 'morgan';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yaml';
import { env } from './config/env.js';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler.js';
import apiRoutes from './routes.js';

export const createApp = () => {
  const app = express();

  app.use(helmet({ contentSecurityPolicy: false }));
  app.use(cors({ origin: env.corsOrigin, credentials: true }));
  app.use(compression());
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));
  if (!env.isTest) app.use(morgan('dev'));

  app.get('/health', (_req, res) =>
    res.json({
      success: true,
      data: {
        status: 'ok',
        service: 'payneat-api',
        env: env.nodeEnv,
        timestamp: new Date().toISOString(),
      },
    }),
  );

  // เอกสาร API (Swagger UI) — เปิดที่ /docs
  const openApiPath = path.join(env.rootDir, 'docs/openapi.yaml');
  if (fs.existsSync(openApiPath)) {
    const spec = YAML.parse(fs.readFileSync(openApiPath, 'utf8'));
    app.use('/docs', swaggerUi.serve, swaggerUi.setup(spec, { customSiteTitle: 'PaynEat API' }));
    app.get('/openapi.json', (_req, res) => res.json(spec));
  }

  app.use('/api/v1', apiRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};

export default createApp;
