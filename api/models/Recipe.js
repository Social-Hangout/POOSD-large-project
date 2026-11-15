const mongoose = require('mongoose');

// Backs the `recipe` shape in docs/api-contract.md. Limits match "Limits and validation" there;
// routes/recipes.js checks the same limits first so users get the contract's error messages,
// and these are the last line of defense for anything that writes to the database directly.
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

function arrayLength(min, max, label) {
  return {
    validator: (items) => Array.isArray(items) && items.length >= min && items.length <= max,
    message: `A recipe needs ${min} to ${max} ${label}`,
  };
}

const ingredientSchema = new mongoose.Schema(
  {
    // Stored lowercase so search and display are consistent
    name: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
      minlength: 1,
      maxlength: LIMITS.ingredientName,
    },
    // Plain text such as "2 cups"; always present, "" when not given
    amount: { type: String, trim: true, maxlength: LIMITS.ingredientAmount, default: '' },
  },
  { _id: false },
);

const recipeSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, minlength: 1, maxlength: LIMITS.title },
    ingredients: {
      type: [ingredientSchema],
      validate: arrayLength(LIMITS.minIngredients, LIMITS.maxIngredients, 'ingredients'),
    },
    steps: {
      type: [{ type: String, trim: true, minlength: 1, maxlength: LIMITS.step }],
      validate: arrayLength(LIMITS.minSteps, LIMITS.maxSteps, 'steps'),
    },
    // A user has many recipes
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true },
);

// Newest-first list (GET /api/recipes); _id breaks ties so pages never overlap
recipeSchema.index({ createdAt: -1, _id: -1 });
// The caller's own recipes (GET /api/recipes?mine=true)
recipeSchema.index({ author: 1, createdAt: -1 });

const Recipe = mongoose.model('Recipe', recipeSchema);
Recipe.LIMITS = LIMITS;

module.exports = Recipe;
