const express = require('express');
const mongoose = require('mongoose');

const Recipe = require('../models/Recipe');
const Review = require('../models/Review');
const Comment = require('../models/Comment');
const User = require('../models/User');
const requireAuth = require('../middleware/requireAuth');
const { parsePagination } = require('../utils/pagination');
const { recipeReviews } = require('./reviews');
const { recipeComments } = require('./comments');

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

// Search limits (docs/api-contract.md, "Search rule")
const MAX_SEARCH_LENGTH = 200;
const MAX_SEARCH_TERMS = 10;

const RECIPE_NOT_FOUND = { error: 'Recipe not found' };
const NOT_YOUR_RECIPE = { error: 'Not your recipe' };

// Every recipe route needs a login, including the nested reviews and comments below
router.use(requireAuth);

// 15-16 and 18-19 live in their own files but sit under /api/recipes/:id/...
router.use('/:id/reviews', recipeReviews);
router.use('/:id/comments', recipeComments);

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

// Turns ?q into search terms, following the contract's search rule steps 1-2.
// Returns { terms }, or { error } with the contract's message.
function parseSearchTerms(q) {
  if (typeof q !== 'string') return { error: 'Search text is required' };
  if (q.length > MAX_SEARCH_LENGTH) return { error: 'Search text can be at most 200 characters' };

  const terms = [];
  for (const piece of q.split(',')) {
    let term = piece.trim().toLowerCase();
    if (!term) continue;

    // "tomatoes" -> "tomato", "eggs" -> "egg"; short words like "gas" are left alone
    if (term.length > 3) {
      if (term.endsWith('es')) term = term.slice(0, -2);
      else if (term.endsWith('s')) term = term.slice(0, -1);
    }

    // "egg, eggs" is one term, so it can't count as two matches
    if (!terms.includes(term)) terms.push(term);
    if (terms.length === MAX_SEARCH_TERMS) break;
  }

  return terms.length ? { terms } : { error: 'Search text is required' };
}

// Escapes regex special characters, so input like "(" is searched for literally instead of
// crashing the query or being used to build a slow pattern
function escapeRegex(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Aggregation expression: true if the pattern appears in the recipe's title or any ingredient name
function termMatches(pattern) {
  return {
    $or: [
      { $regexMatch: { input: '$title', regex: pattern, options: 'i' } },
      {
        $anyElementTrue: [
          {
            $map: {
              input: { $ifNull: ['$ingredients', []] },
              as: 'ingredient',
              in: { $regexMatch: { input: '$$ingredient.name', regex: pattern, options: 'i' } },
            },
          },
        ],
      },
    ],
  };
}

// Loads the recipe in :id, or null if the id isn't a valid ObjectId (so it 404s instead of 500ing)
function findRecipe(id) {
  if (!mongoose.isObjectIdOrHexString(id)) return null;
  return Recipe.findById(id);
}

// 9. List recipes, newest first. ?mine=true returns only the caller's.
router.get('/', async (req, res) => {
  const { page, limit, skip, error } = parsePagination(req.query);
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
      .skip(skip)
      .limit(limit)
      .populate('author', 'firstName');
  }

  res.json({ recipes: recipes.map(toPublicRecipe), page, totalPages });
});

// 10. Partial-match ingredient search, best match first (docs/api-contract.md, "Search rule").
// Declared before GET /:id, or Express would treat "search" as a recipe id.
router.get('/search', async (req, res) => {
  const { terms, error: searchError } = parseSearchTerms(req.query.q);
  if (searchError) return res.status(400).json({ error: searchError });

  const { page, limit, skip, error } = parsePagination(req.query);
  if (error) return res.status(400).json({ error });

  const patterns = terms.map(escapeRegex);

  const [{ results, total }] = await Recipe.aggregate([
    // Step 4: recipes where any term is in the title or an ingredient name
    {
      $match: {
        $or: patterns.flatMap((pattern) => [
          { title: { $regex: pattern, $options: 'i' } },
          { 'ingredients.name': { $regex: pattern, $options: 'i' } },
        ]),
      },
    },
    // Step 5: count how many of the terms each recipe matched
    { $addFields: { matchedTerms: { $add: patterns.map((pattern) => ({ $cond: [termMatches(pattern), 1, 0] })) } } },
    // Step 6: best match first, then title A to Z (_id keeps pages stable when titles tie)
    { $sort: { matchedTerms: -1, title: 1, _id: 1 } },
    { $facet: { results: [{ $skip: skip }, { $limit: limit }], total: [{ $count: 'count' }] } },
  ])
    // Case-insensitive title sort, so "apple pie" doesn't land after "Zucchini"
    .collation({ locale: 'en', strength: 2 });

  // aggregate returns plain objects; turn them back into documents to reuse populate and toPublicRecipe
  const recipes = results.map((raw) => Recipe.hydrate(raw));
  await Recipe.populate(recipes, { path: 'author', select: 'firstName' });

  const count = total[0]?.count ?? 0;
  res.json({
    results: recipes.map((recipe, i) => ({
      ...toPublicRecipe(recipe),
      matchedTerms: results[i].matchedTerms,
      totalTerms: terms.length,
    })),
    page,
    totalPages: Math.ceil(count / limit),
  });
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

  // Cascade delete. Children go first: if the server dies halfway, the worst case is a recipe
  // missing some reviews, never reviews pointing at a recipe that's gone. (A real all-or-nothing
  // delete needs a transaction, which our single-server MongoDB doesn't support.)
  await Promise.all([Review.deleteMany({ recipe: recipe._id }), Comment.deleteMany({ recipe: recipe._id })]);
  await recipe.deleteOne();

  res.status(204).end();
});

module.exports = router;
