// The data rules from the models (docs/api-contract.md, "Limits and validation"), checked both
// through the API routes and directly against the database.
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');

const Recipe = require('../models/Recipe');
const Review = require('../models/Review');
const Comment = require('../models/Comment');
const User = require('../models/User');
const { start, stop, clearDatabase, createUser, api, validRecipe } = require('./helpers');

before(start);
after(stop);
beforeEach(clearDatabase);

describe('users and recipes', () => {
  it('creates a valid user and a recipe owned by them', async () => {
    const user = await createUser('Ana');
    assert.equal(await User.countDocuments(), 1);

    const res = await api('POST', '/recipes', {
      user,
      body: validRecipe({ ingredients: [{ name: '  Garlic ' }] }),
    });

    assert.equal(res.status, 201);
    assert.equal(res.body.title, 'Garlic Butter Pasta');
    assert.deepEqual(res.body.ingredients, [{ name: 'garlic', amount: '' }]);
    assert.deepEqual(res.body.author, { id: user.id, firstName: 'Ana' });
    assert.ok(res.body.id && !('_id' in res.body), 'returns id, never _id');

    const saved = await Recipe.findById(res.body.id);
    assert.ok(saved.author.equals(user._id), 'recipe belongs to the user who made it');
  });
});

describe('reviews', () => {
  it('rejects a second review from the same user on the same recipe', async () => {
    const author = await createUser('Ana');
    const reviewer = await createUser('Ben');
    const recipe = (await api('POST', '/recipes', { user: author, body: validRecipe() })).body;

    const first = await api('POST', `/recipes/${recipe.id}/reviews`, { user: reviewer, body: { rating: 5 } });
    assert.equal(first.status, 201);

    const second = await api('POST', `/recipes/${recipe.id}/reviews`, { user: reviewer, body: { rating: 3 } });
    assert.equal(second.status, 409);
    assert.deepEqual(second.body, { error: 'You already reviewed this recipe' });

    // The unique index blocks it even when the route's check is skipped (two requests at once)
    await assert.rejects(
      Review.create({ recipe: recipe.id, author: reviewer.id, rating: 4 }),
      (err) => err.code === 11000,
    );
    assert.equal(await Review.countDocuments(), 1);
  });
});

describe('recipe limits', () => {
  it('rejects a recipe over the size limits', async () => {
    const user = await createUser();

    const tooManyIngredients = validRecipe({
      ingredients: Array.from({ length: 11 }, (_, i) => ({ name: `ingredient ${i}` })),
    });
    let res = await api('POST', '/recipes', { user, body: tooManyIngredients });
    assert.equal(res.status, 400);
    assert.deepEqual(res.body, { error: 'A recipe needs 1 to 10 ingredients' });

    res = await api('POST', '/recipes', { user, body: validRecipe({ steps: Array(9).fill('Stir.') }) });
    assert.equal(res.status, 400);
    assert.deepEqual(res.body, { error: 'A recipe needs 1 to 8 steps' });

    res = await api('POST', '/recipes', { user, body: validRecipe({ title: 'x'.repeat(101) }) });
    assert.equal(res.status, 400);
    assert.deepEqual(res.body, { error: 'Title must be 1 to 100 characters' });

    // The model enforces the same limits for anything that skips the routes
    await assert.rejects(
      Recipe.create({ ...tooManyIngredients, author: user.id }),
      mongoose.Error.ValidationError,
    );
    assert.equal(await Recipe.countDocuments(), 0);
  });
});

describe('recipe references', () => {
  it("rejects a review or comment on a recipe that doesn't exist", async () => {
    const user = await createUser();
    const missingId = new mongoose.Types.ObjectId().toString();

    const review = await api('POST', `/recipes/${missingId}/reviews`, { user, body: { rating: 5 } });
    assert.equal(review.status, 404);
    assert.deepEqual(review.body, { error: 'Recipe not found' });

    const comment = await api('POST', `/recipes/${missingId}/comments`, { user, body: { text: 'Yum' } });
    assert.equal(comment.status, 404);
    assert.deepEqual(comment.body, { error: 'Recipe not found' });

    // An id that isn't an ObjectId at all is also a 404, not a 500
    const badId = await api('POST', '/recipes/not-an-id/comments', { user, body: { text: 'Yum' } });
    assert.equal(badId.status, 404);

    assert.equal(await Review.countDocuments(), 0);
    assert.equal(await Comment.countDocuments(), 0);
  });
});
