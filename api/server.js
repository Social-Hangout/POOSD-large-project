require('dotenv').config();

const express = require('express');
const cors = require('cors');

const app = express();

app.use(express.json());
app.use(cors());

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

const PORT = process.env.PORT || 5000;

// Default 0.0.0.0 so other devices on the LAN (e.g. a phone running the Flutter app) can reach it.
// In production set HOST=127.0.0.1 so only Apache's proxy can reach Express.
const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`Server listening on http://${HOST}:${PORT}`);
});
