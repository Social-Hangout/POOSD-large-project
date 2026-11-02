const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

// Sets req.userId from a valid `Authorization: Bearer <token>` header, or responds 401.
// Routes must use req.userId to know who is calling, never an id from the body.
function requireAuth(req, res, next) {
  const match = /^Bearer (\S+)$/.exec(req.headers.authorization || '');

  try {
    if (!match) throw new Error('No bearer token');

    // Pin the algorithm so a token can't pick a weaker one (such as "none")
    const { userId } = jwt.verify(match[1], process.env.JWT_SECRET, { algorithms: ['HS256'] });
    if (typeof userId !== 'string' || !mongoose.isValidObjectId(userId)) {
      throw new Error('Bad token payload');
    }

    req.userId = userId;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or missing token' });
  }
}

module.exports = requireAuth;
