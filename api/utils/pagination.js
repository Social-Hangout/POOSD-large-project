// ?page and ?limit for every list route (docs/api-contract.md, "Pagination")

const WHOLE_NUMBER = /^\d+$/;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

// Returns { page, limit, skip }, or { error } with the contract's message.
// Bad values are rejected, not clamped. A repeated param (?page=1&page=2) arrives as an
// array, so it fails the string check.
function parsePagination(query) {
  const { page = '1', limit = String(DEFAULT_LIMIT) } = query ?? {};

  const pageNumber = Number(page);
  if (typeof page !== 'string' || !WHOLE_NUMBER.test(page) || !Number.isSafeInteger(pageNumber) || pageNumber < 1) {
    return { error: 'page must be a whole number, 1 or more' };
  }

  const limitNumber = Number(limit);
  if (typeof limit !== 'string' || !WHOLE_NUMBER.test(limit) || limitNumber < 1 || limitNumber > MAX_LIMIT) {
    return { error: 'limit must be a whole number from 1 to 50' };
  }

  // A huge page would make skip too big for MongoDB; anything that far is past the end anyway
  const skip = Math.min((pageNumber - 1) * limitNumber, Number.MAX_SAFE_INTEGER);

  return { page: pageNumber, limit: limitNumber, skip };
}

module.exports = { parsePagination };
