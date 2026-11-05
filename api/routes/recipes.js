const express = require('express');
const mongoose = require('mongoose');

const Recipe = require('../models/Recipe');
const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();

// The contract's recipe limits (docs/api-contract.md, "Limits and validation")
const LIMITS = {
  title: 100,
  minIngredients: 1,
  maxIngredients: 10,
  ingredientName: 50,
  ingredientAmount: 50,
  minSteps: 1,
  maxSteps: 8,
  step: 500,
};

const WHOLE_NUMBER = /^\d+$/;
const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

const RECIPE_NOT_FOUND = { error: 'Recipe not found' };
const NOT_YOUR_RECIPE = { error: 'Not your recipe' };

// Every recipe route needs a login
router.use(requireAuth);

// Reads ?page and ?limit. Returns { page, limit }, or { error } with the contract's message.
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

  return { page: pageNumber, limit: limitNumber };
}

// Returns the trimmed string, or null unless it's a string of min to max characters.
// Rejecting non-strings means a JSON object such as { "$gt": "" } can never reach a query.
function trimmedString(value, min, max) {
  if (typeof value !== 'string') return null;
  const text = value.trim();
  return text.length >= min && text.length <= max ? text : null;
}

// Checks a create/edit body against the contract (12. POST /api/recipes).
// Returns { recipe } with clean fields, or { error } naming the first problem.
function parseRecipe(body) {
  const title = trimmedString(body?.title, 1, LIMITS.title);
  if (!title) return { error: 'Title must be 1 to 100 characters' };

  const { ingredients, steps } = body;
  if (
    !Array.isArray(ingredients) ||
    ingredients.length < LIMITS.minIngredients ||
    ingredients.length > LIMITS.maxIngredients
  ) {
    return { error: 'A recipe needs 1 to 10 ingredients' };
  }

  const cleanIngredients = [];
  for (const item of ingredients) {
    const name = trimmedString(item?.name, 1, LIMITS.ingredientName);
    if (!name) return { error: 'Ingredient names must be 1 to 50 characters' };

    // amount is optional; null or missing becomes ""
    const amount = item.amount ?? '';
    if (typeof amount !== 'string' || amount.trim().length > LIMITS.ingredientAmount) {
      return { error: 'Ingredient amounts can be at most 50 characters' };
    }

    cleanIngredients.push({ name: name.toLowerCase(), amount: amount.trim() });
  }

  if (!Array.isArray(steps) || steps.length < LIMITS.minSteps || steps.length > LIMITS.maxSteps) {
    return { error: 'A recipe needs 1 to 8 steps' };
  }

  const cleanSteps = [];
  for (const step of steps) {
    const text = trimmedString(step, 1, LIMITS.step);
    if (!text) return { error: 'Each step must be 1 to 500 characters' };
    cleanSteps.push(text);
  }

  return { recipe: { title, ingredients: cleanIngredients, steps: cleanSteps } };
}

// The `recipe` shape in docs/api-contract.md. The recipe must have author populated
// with firstName. author is null if the account was deleted.
function toPublicRecipe(recipe) {
  return {
    id: recipe.id,
    title: recipe.title,
    ingredients: recipe.ingredients.map(({ name, amount }) => ({ name, amount: amount ?? '' })),
    steps: [...recipe.steps],
    author: recipe.author ? { id: recipe.author.id, firstName: recipe.author.firstName } : null,
    createdAt: recipe.createdAt,
  };
}

// Loads the recipe in :id, or null if the id isn't a valid ObjectId (so it 404s instead of 500ing)
function findRecipe(id) {
  if (!mongoose.isObjectIdOrHexString(id)) return null;
  return Recipe.findById(id);
}

// 9. List recipes, newest first. ?mine=true returns only the caller's.
router.get('/', async (req, res) => {
  const { page, limit, error } = parsePagination(req.query);
  if (error) return res.status(400).json({ error });

  const { mine = 'false' } = req.query;
  if (mine !== 'true' && mine !== 'false') {
    return res.status(400).json({ error: 'mine must be true or false' });
  }

  const filter = mine === 'true' ? { author: req.userId } : {};
  const total = await Recipe.countDocuments(filter);
  const totalPages = Math.ceil(total / limit);

  // A page past the end is an empty list, not an error; skip the query entirely
  let recipes = [];
  if (page <= totalPages) {
    recipes = await Recipe.find(filter)
      // _id breaks ties between recipes created in the same millisecond, so pages never overlap
      .sort({ createdAt: -1, _id: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('author', 'firstName');
  }

  res.json({ recipes: recipes.map(toPublicRecipe), page, totalPages });
});

// 11. One recipe
router.get('/:id', async (req, res) => {
  const recipe = await findRecipe(req.params.id)?.populate('author', 'firstName');
  if (!recipe) return res.status(404).json(RECIPE_NOT_FOUND);

  res.json(toPublicRecipe(recipe));
});

// 12. Create a recipe. The author always comes from the token, never the body.
router.post('/', async (req, res) => {
  const { recipe: fields, error } = parseRecipe(req.body);
  if (error) return res.status(400).json({ error });

  // A valid token for a deleted account is treated like a bad token (same as /users/me)
  const userExists = await User.exists({ _id: req.userId });
  if (!userExists) return res.status(401).json({ error: 'Invalid or missing token' });

  const recipe = await Recipe.create({ ...fields, author: req.userId });
  await recipe.populate('author', 'firstName');

  res.status(201).json(toPublicRecipe(recipe));
});

// 13. Replace a recipe's title, ingredients and steps. Author only.
router.put('/:id', async (req, res) => {
  const recipe = await findRecipe(req.params.id);
  if (!recipe) return res.status(404).json(RECIPE_NOT_FOUND);
  if (!recipe.author.equals(req.userId)) return res.status(403).json(NOT_YOUR_RECIPE);

  const { recipe: fields, error } = parseRecipe(req.body);
  if (error) return res.status(400).json({ error });

  recipe.set(fields);
  await recipe.save();
  await recipe.populate('author', 'firstName');

  res.json(toPublicRecipe(recipe));
});

// 14. Delete a recipe. Author only.
router.delete('/:id', async (req, res) => {
  const recipe = await findRecipe(req.params.id);
  if (!recipe) return res.status(404).json(RECIPE_NOT_FOUND);
  if (!recipe.author.equals(req.userId)) return res.status(403).json(NOT_YOUR_RECIPE);

  // TODO(API2): once DB1's Review and Comment models land, delete this recipe's reviews and
  // comments here (deleteMany) before the recipe, as the contract's cascade delete requires
  await recipe.deleteOne();

  res.status(204).end();
});

module.exports = router;
