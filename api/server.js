require('dotenv').config();

const express = require('express');
const cors = require('cors');

const app = express();

app.disable('x-powered-by');

// nginx on the same machine forwards the client's IP in X-Forwarded-For; trust only it,
// so req.ip (and per-IP rate limits) see the real client instead of 127.0.0.1
app.set('trust proxy', 'loopback');

// CORS_ORIGIN is a comma-separated allowlist (production: https://contactshub.site).
// Unset allows any origin, for local development.
const corsOrigin = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((origin) => origin.trim())
  : '*';

app.use(cors({ origin: corsOrigin }));
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

const BODY_ERRORS = {
  'entity.parse.failed': 'Request body must be valid JSON',
  'entity.too.large': 'Request body is too large',
};

// Every error goes out as { error }, never as an HTML page or a stack trace
app.use((err, req, res, next) => {
  const status = err.status || err.statusCode || 500;

  if (status >= 500) {
    console.error(err);
    return res.status(500).json({ error: 'Something went wrong' });
  }

  res.status(status).json({ error: BODY_ERRORS[err.type] || err.message });
});

const PORT = process.env.PORT || 5000;

// Default 0.0.0.0 so other devices on the LAN (e.g. a phone running the Flutter app) can reach it.
// In production set HOST=127.0.0.1 so only nginx can reach Express.
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`Server listening on http://${HOST}:${PORT}`);
});
