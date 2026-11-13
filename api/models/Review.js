const mongoose = require('mongoose');

// Backs the `review` shape in docs/api-contract.md. Every review belongs to one recipe and one user.
const reviewSchema = new mongoose.Schema(
  {
    recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe', required: true },
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
      validate: { validator: Number.isInteger, message: 'Rating must be a whole number from 1 to 5' },
    },
    // Optional; always present, "" when not given
    text: { type: String, trim: true, maxlength: 500, default: '' },
  },
  { timestamps: true },
);

// One review per user per recipe. A second insert fails with code 11000, which the route maps to 409.
reviewSchema.index({ recipe: 1, author: 1 }, { unique: true });
// A recipe's reviews, newest first (GET /api/recipes/:id/reviews)
reviewSchema.index({ recipe: 1, createdAt: -1 });

module.exports = mongoose.model('Review', reviewSchema);
