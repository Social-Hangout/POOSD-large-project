const crypto = require('crypto');

// Hex SHA-256, used to store email tokens without storing the tokens themselves
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// A random token for an email link: send `token` to the user, store `hash`
function createEmailToken() {
  const token = crypto.randomBytes(32).toString('hex');
  return { token, hash: hashToken(token) };
}

module.exports = { hashToken, createEmailToken };
