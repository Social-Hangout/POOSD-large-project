const { rateLimit, ipKeyGenerator } = require('express-rate-limit');

const MINUTE = 60 * 1000;

// Counts live in memory, which is fine for the single pm2 process; they reset when the API restarts
function limiter({ windowMs, limit, message, key }) {
  return rateLimit({
    windowMs,
    limit,
    keyGenerator: key,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: { error: message },
  });
}

// Runs before validation, so the body may be missing or not a string
function bodyEmail(req) {
  const email = req.body?.email;
  return typeof email === 'string' ? email.trim().toLowerCase() : '';
}

// ipKeyGenerator groups IPv6 addresses by subnet, so one client can't dodge limits by rotating addresses
const byIp = (req) => ipKeyGenerator(req.ip);

const TOO_MANY_LOGINS = 'Too many login attempts. Try again later.';
const TOO_MANY_REQUESTS = 'Too many requests. Try again later.';

// 5 login attempts per 15 minutes per email + IP
const loginLimit = limiter({
  windowMs: 15 * MINUTE,
  limit: 5,
  message: TOO_MANY_LOGINS,
  key: (req) => `${byIp(req)}|${bodyEmail(req)}`,
});

// Routes that send email: 3 per hour per email and 20 per hour per IP, to protect the daily email quota
const emailLimit = [
  limiter({ windowMs: 60 * MINUTE, limit: 20, message: TOO_MANY_REQUESTS, key: byIp }),
  limiter({ windowMs: 60 * MINUTE, limit: 3, message: TOO_MANY_REQUESTS, key: bodyEmail }),
];

module.exports = { loginLimit, emailLimit };
