const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/User');
const { loginLimit, emailLimit } = require('../middleware/rateLimits');
const { normalizeEmail, normalizeName, isValidPassword } = require('../utils/validate');
const { hashToken, createEmailToken } = require('../utils/tokens');
const { sendVerificationEmail } = require('../utils/authEmails');

const router = express.Router();

const BCRYPT_ROUNDS = 10;
const VERIFY_LINK_MS = 24 * 60 * 60 * 1000;

// Login compares against this when the email has no account, so a wrong email takes as long
// as a wrong password and response time doesn't reveal which emails are registered
const DUMMY_HASH = bcrypt.hashSync('not-a-real-password', BCRYPT_ROUNDS);

// Email tokens are 32 random bytes in hex
const EMAIL_TOKEN_PATTERN = /^[a-f0-9]{64}$/;

// 1. Create an unverified account and email a verification link
router.post('/register', emailLimit, async (req, res) => {
  const body = req.body ?? {};
  const firstName = normalizeName(body.firstName);
  const lastName = normalizeName(body.lastName);
  const email = normalizeEmail(body.email);

  if (!firstName || !lastName) {
    return res.status(400).json({ error: 'First and last name must be 1 to 50 characters' });
  }
  if (!email) {
    return res.status(400).json({ error: 'A valid email is required' });
  }
  if (!isValidPassword(body.password)) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  const passwordHash = await bcrypt.hash(body.password, BCRYPT_ROUNDS);
  const { token, hash } = createEmailToken();

  let user;
  try {
    user = await User.create({
      firstName,
      lastName,
      email,
      passwordHash,
      verified: false,
      verifyToken: hash,
      verifyExpires: new Date(Date.now() + VERIFY_LINK_MS),
    });
  } catch (err) {
    // The unique index on email catches duplicates, including two sign-ups racing each other
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    throw err;
  }

  try {
    await sendVerificationEmail(email, token);
  } catch (err) {
    // Remove the account so the user can register again instead of getting 409
    console.error('Verification email failed on register:', err.message);
    await User.deleteOne({ _id: user._id });
    return res.status(503).json({ error: "Couldn't send the verification email. Try again later." });
  }

  res.status(201).json({ message: 'Verification email sent' });
});

// 2. Mark the account verified using the token from the email link
router.post('/verify', async (req, res) => {
  const token = req.body?.token;
  if (typeof token !== 'string' || !EMAIL_TOKEN_PATTERN.test(token)) {
    return res.status(400).json({ error: 'Invalid or expired link' });
  }

  // One atomic update, so a link can't be used twice
  const user = await User.findOneAndUpdate(
    { verifyToken: hashToken(token), verifyExpires: { $gt: new Date() } },
    { $set: { verified: true }, $unset: { verifyToken: 1, verifyExpires: 1 } },
  );
  if (!user) {
    return res.status(400).json({ error: 'Invalid or expired link' });
  }

  res.json({ message: 'Email verified. You can log in now.' });
});

// 3. Send a new verification link, replacing the old one
router.post('/resend-verification', emailLimit, async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  if (!email) {
    return res.status(400).json({ error: 'A valid email is required' });
  }

  const { token, hash } = createEmailToken();
  const user = await User.findOneAndUpdate(
    { email, verified: false },
    { $set: { verifyToken: hash, verifyExpires: new Date(Date.now() + VERIFY_LINK_MS) } },
  );

  // Not awaited, and the reply is the same either way, so neither the reply nor its timing
  // reveals whether the email has an unverified account
  if (user) {
    sendVerificationEmail(email, token).catch((err) => {
      console.error('Verification email failed on resend:', err.message);
    });
  }

  res.json({ message: 'If that account needs verifying, a new link was sent' });
});

// 4. Check the password and return a 24-hour token
router.post('/login', loginLimit, async (req, res) => {
  const { email, password } = req.body ?? {};
  if (typeof email !== 'string' || !email.trim() || typeof password !== 'string' || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  const user = await User.findOne({ email: email.trim().toLowerCase() }).select('+passwordHash');
  const passwordMatches = await bcrypt.compare(password, user ? user.passwordHash : DUMMY_HASH);

  // Same reply for a wrong email and a wrong password
  if (!user || !passwordMatches) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  if (!user.verified) {
    return res.status(403).json({ error: 'Please verify your email first' });
  }

  const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
    algorithm: 'HS256',
    expiresIn: '24h',
  });

  res.json({ token, user: user.toPublic() });
});

module.exports = router;
