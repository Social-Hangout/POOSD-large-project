const mongoose = require('mongoose');

// TEMPORARY STAND-IN so the recipe routes can run. The real model is DB1's job:
// replace this whole file with DB1's version (rules, limits, indexes) when it lands.
// routes/recipes.js only needs these fields to exist with these names.
const recipeSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    ingredients: [{ _id: false, name: { type: String, required: true }, amount: { type: String, default: '' } }],
    steps: [String],
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Recipe', recipeSchema);
