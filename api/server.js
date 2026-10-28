require('dotenv').config();

const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');

// Refuse to start without the settings auth depends on, instead of failing on the first request.
// A short JWT_SECRET can be guessed offline from any token, which would let anyone forge logins.
const missing = ['MONGO_URI', 'JWT_SECRET', 'APP_URL'].filter((name) => !process.env[name]);
if (missing.length) {
  throw new Error(`Missing settings in .env: ${missing.join(', ')}`);
}
if (process.env.JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters (see .env.example)');
}

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
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

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

// Connect before accepting requests. If MongoDB is unreachable the process exits, and pm2 restarts it.
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    app.listen(PORT, HOST, () => {
      console.log(`Server listening on http://${HOST}:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Could not connect to MongoDB:', err.message);
    process.exit(1);
  });
