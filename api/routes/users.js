const express = require('express');

const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');
const { normalizeName } = require('../utils/validate');

const router = express.Router();

// A valid token for an account that no longer exists is treated like a bad token
const NO_ACCOUNT = { error: 'Invalid or missing token' };

// 7. The logged-in user
router.get('/me', requireAuth, async (req, res) => {
  const user = await User.findById(req.userId);
  if (!user) return res.status(401).json(NO_ACCOUNT);

  res.json(user.toPublic());
});

// 8. Update the logged-in user's name. Email can't change, and the id comes only from the token.
router.put('/me', requireAuth, async (req, res) => {
  const firstName = normalizeName(req.body?.firstName);
  const lastName = normalizeName(req.body?.lastName);
  if (!firstName || !lastName) {
    return res.status(400).json({ error: 'First and last name must be 1 to 50 characters' });
  }

  const user = await User.findByIdAndUpdate(
    req.userId,
    { $set: { firstName, lastName } },
    { returnDocument: 'after', runValidators: true },
  );
  if (!user) return res.status(401).json(NO_ACCOUNT);

  res.json(user.toPublic());
});

module.exports = router;
