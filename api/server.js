require('dotenv').config();

const mongoose = require('mongoose');

const app = require('./app');

// Refuse to start without the settings auth depends on, instead of failing on the first request.
// A short JWT_SECRET can be guessed offline from any token, which would let anyone forge logins.
const missing = ['MONGO_URI', 'JWT_SECRET', 'APP_URL'].filter((name) => !process.env[name]);
if (missing.length) {
  throw new Error(`Missing settings in .env: ${missing.join(', ')}`);
}
if (process.env.JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters (see .env.example)');
}

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
