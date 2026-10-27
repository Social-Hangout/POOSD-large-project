// Input checks shared by routes. Every check rejects non-strings, so a JSON object such as
// { "$gt": "" } can never reach a MongoDB query as an operator.

const MAX_EMAIL_LENGTH = 254;

// Deliberately loose: something@something.something. The verification email proves the rest.
// Length is checked first, which also keeps the regex fast.
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Returns the trimmed, lowercase email, or null if it isn't a valid email
function normalizeEmail(value) {
  if (typeof value !== 'string') return null;
  const email = value.trim().toLowerCase();
  if (email.length > MAX_EMAIL_LENGTH || !EMAIL_PATTERN.test(email)) return null;
  return email;
}

// Returns the trimmed name, or null unless it's 1 to 50 characters
function normalizeName(value) {
  if (typeof value !== 'string') return null;
  const name = value.trim();
  return name.length >= 1 && name.length <= 50 ? name : null;
}

function isValidPassword(value) {
  return typeof value === 'string' && value.length >= 8;
}

module.exports = { normalizeEmail, normalizeName, isValidPassword };
