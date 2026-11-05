const mongoose = require('mongoose');

// TEMPORARY STAND-IN so the review routes can run. The real model is DB1's job:
// replace this whole file with DB1's version (rules, limits, and the unique recipe + author
// index for one review per person) when it lands.
// routes/reviews.js only needs these fields to exist with these names.
const reviewSchema = new mongoose.Schema(
  {
    recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe', required: true },
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rating: { type: Number, required: true },
    text: { type: String, default: '' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Review', reviewSchema);
