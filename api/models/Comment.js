const mongoose = require('mongoose');

// Backs the `comment` shape in docs/api-contract.md. Every comment belongs to one recipe and one
// user, and a user can leave any number of comments on a recipe.
const commentSchema = new mongoose.Schema(
  {
    recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe', required: true },
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true, trim: true, minlength: 1, maxlength: 500 },
  },
  { timestamps: true },
);

// A recipe's comments, oldest first (GET /api/recipes/:id/comments)
commentSchema.index({ recipe: 1, createdAt: 1 });

module.exports = mongoose.model('Comment', commentSchema);
