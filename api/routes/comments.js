const express = require('express');
const mongoose = require('mongoose');

const Recipe = require('../models/Recipe');
const Comment = require('../models/Comment');
const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');
const { parsePagination } = require('../utils/pagination');

const MAX_TEXT = 500;

const RECIPE_NOT_FOUND = { error: 'Recipe not found' };
const COMMENT_NOT_FOUND = { error: 'Comment not found' };

// The `comment` shape in docs/api-contract.md. The comment must have author populated
// with firstName. author is null if the account was deleted.
function toPublicComment(comment) {
  return {
    id: comment.id,
    text: comment.text,
    author: comment.author ? { id: comment.author.id, firstName: comment.author.firstName } : null,
    createdAt: comment.createdAt,
  };
}

// True if :id is a valid ObjectId of a recipe that exists
async function recipeExists(id) {
  return mongoose.isObjectIdOrHexString(id) && Boolean(await Recipe.exists({ _id: id }));
}

// Mounted at /api/recipes/:id/comments by routes/recipes.js, which already ran requireAuth
const recipeComments = express.Router({ mergeParams: true });

// 18. A recipe's comments, oldest first so they read like a conversation
recipeComments.get('/', async (req, res) => {
  const { page, limit, skip, error } = parsePagination(req.query);
  if (error) return res.status(400).json({ error });

  if (!(await recipeExists(req.params.id))) return res.status(404).json(RECIPE_NOT_FOUND);

  const filter = { recipe: req.params.id };
  const [total, comments] = await Promise.all([
    Comment.countDocuments(filter),
    Comment.find(filter).sort({ createdAt: 1, _id: 1 }).skip(skip).limit(limit).populate('author', 'firstName'),
  ]);

  res.json({ comments: comments.map(toPublicComment), page, totalPages: Math.ceil(total / limit) });
});

// 19. Comment on a recipe. Any number per user.
recipeComments.post('/', async (req, res) => {
  if (!(await recipeExists(req.params.id))) return res.status(404).json(RECIPE_NOT_FOUND);

  const { text } = req.body ?? {};
  const trimmed = typeof text === 'string' ? text.trim() : '';
  if (!trimmed) return res.status(400).json({ error: 'Comment text is required' });
  if (trimmed.length > MAX_TEXT) {
    return res.status(400).json({ error: 'Comment text can be at most 500 characters' });
  }

  // A valid token for a deleted account is treated like a bad token (same as /users/me)
  if (!(await User.exists({ _id: req.userId }))) {
    return res.status(401).json({ error: 'Invalid or missing token' });
  }

  const comment = await Comment.create({ recipe: req.params.id, author: req.userId, text: trimmed });
  await comment.populate('author', 'firstName');

  res.status(201).json(toPublicComment(comment));
});

// Mounted at /api/comments in server.js
const comments = express.Router();

// 20. Delete a comment. Its author only.
comments.delete('/:id', requireAuth, async (req, res) => {
  const comment = mongoose.isObjectIdOrHexString(req.params.id) ? await Comment.findById(req.params.id) : null;
  if (!comment) return res.status(404).json(COMMENT_NOT_FOUND);
  if (!comment.author?.equals(req.userId)) return res.status(403).json({ error: 'Not your comment' });

  await comment.deleteOne();

  res.status(204).end();
});

module.exports = { recipeComments, comments };
