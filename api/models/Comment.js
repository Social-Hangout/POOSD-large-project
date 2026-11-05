const mongoose = require('mongoose');

// TEMPORARY STAND-IN so the comment routes can run. The real model is DB1's job:
// replace this whole file with DB1's version (rules and limits) when it lands.
// routes/comments.js only needs these fields to exist with these names.
const commentSchema = new mongoose.Schema(
  {
    recipe: { type: mongoose.Schema.Types.ObjectId, ref: 'Recipe', required: true },
    author: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Comment', commentSchema);
