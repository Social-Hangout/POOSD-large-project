const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const recipeRoutes = require('./routes/recipes');
const { reviews: reviewRoutes } = require('./routes/reviews');
const { comments: commentRoutes } = require('./routes/comments');

// Builds the Express app without connecting to MongoDB or listening, so server.js can start it
// and the tests can load it against their own database.
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

// Safe default security headers (nosniff, HSTS, no framing by other sites, and more) on every response.
// The API only returns JSON, so helmet's strict default Content-Security-Policy costs nothing.
app.use(helmet());
app.use(cors({ origin: corsOrigin }));
app.use(express.json());

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/recipes', recipeRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/comments', commentRoutes);

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

module.exports = app;
