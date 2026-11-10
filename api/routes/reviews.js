const express = require('express');
const mongoose = require('mongoose');

const Recipe = require('../models/Recipe');
const Review = require('../models/Review');
const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');
const { parsePagination } = require('../utils/pagination');

const MAX_TEXT = 500;

const RECIPE_NOT_FOUND = { error: 'Recipe not found' };
const REVIEW_NOT_FOUND = { error: 'Review not found' };

// The `review` shape in docs/api-contract.md. The review must have author populated
// with firstName. author is null if the account was deleted.
function toPublicReview(review) {
  return {
    id: review.id,
    rating: review.rating,
    text: review.text ?? '',
    author: review.author ? { id: review.author.id, firstName: review.author.firstName } : null,
    createdAt: review.createdAt,
  };
}

// True if :id is a valid ObjectId of a recipe that exists
async function recipeExists(id) {
  return mongoose.isObjectIdOrHexString(id) && Boolean(await Recipe.exists({ _id: id }));
}

// Mounted at /api/recipes/:id/reviews by routes/recipes.js, which already ran requireAuth
const recipeReviews = express.Router({ mergeParams: true });

// 15. A recipe's reviews, newest first
recipeReviews.get('/', async (req, res) => {
  const { page, limit, skip, error } = parsePagination(req.query);
  if (error) return res.status(400).json({ error });

  if (!(await recipeExists(req.params.id))) return res.status(404).json(RECIPE_NOT_FOUND);

  const filter = { recipe: req.params.id };
  const [total, reviews] = await Promise.all([
    Review.countDocuments(filter),
    Review.find(filter).sort({ createdAt: -1, _id: -1 }).skip(skip).limit(limit).populate('author', 'firstName'),
  ]);

  res.json({ reviews: reviews.map(toPublicReview), page, totalPages: Math.ceil(total / limit) });
});

// 16. Review a recipe. One review per user per recipe.
recipeReviews.post('/', async (req, res) => {
  if (!(await recipeExists(req.params.id))) return res.status(404).json(RECIPE_NOT_FOUND);

  const body = req.body ?? {};
  const { rating } = body;
  if (typeof rating !== 'number' || !Number.isInteger(rating) || rating < 1 || rating > 5) {
    return res.status(400).json({ error: 'Rating must be a whole number from 1 to 5' });
  }

  // text is optional; null or missing becomes ""
  const text = body.text ?? '';
  if (typeof text !== 'string' || text.trim().length > MAX_TEXT) {
    return res.status(400).json({ error: 'Review text can be at most 500 characters' });
  }

  // A valid token for a deleted account is treated like a bad token (same as /users/me)
  if (!(await User.exists({ _id: req.userId }))) {
    return res.status(401).json({ error: 'Invalid or missing token' });
  }

  const duplicate = { error: 'You already reviewed this recipe' };

  // This check gives the right answer on its own, but two requests at the same moment can both
  // pass it. The unique index on recipe + author in models/Review.js closes that gap:
  // the second insert then fails with code 11000, which is also mapped to 409 below.
  if (await Review.exists({ recipe: req.params.id, author: req.userId })) {
    return res.status(409).json(duplicate);
  }

  let review;
  try {
    review = await Review.create({ recipe: req.params.id, author: req.userId, rating, text: text.trim() });
  } catch (err) {
    if (err.code === 11000) return res.status(409).json(duplicate);
    throw err;
  }
  await review.populate('author', 'firstName');

  res.status(201).json(toPublicReview(review));
});

// Mounted at /api/reviews in server.js
const reviews = express.Router();

// 17. Delete a review. Its author only.
reviews.delete('/:id', requireAuth, async (req, res) => {
  const review = mongoose.isObjectIdOrHexString(req.params.id) ? await Review.findById(req.params.id) : null;
  if (!review) return res.status(404).json(REVIEW_NOT_FOUND);
  if (!review.author.equals(req.userId)) return res.status(403).json({ error: 'Not your review' });

  await review.deleteOne();

  res.status(204).end();
});

module.exports = { recipeReviews, reviews };
