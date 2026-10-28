const mongoose = require('mongoose');

const nameField = { type: String, required: true, trim: true, minlength: 1, maxlength: 50 };

// Secrets are select: false, so they're only loaded by queries that ask for them with .select('+field')
const userSchema = new mongoose.Schema(
  {
    firstName: nameField,
    lastName: nameField,
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true, select: false },
    verified: { type: Boolean, default: false },
    // verifyToken and resetToken hold the SHA-256 of the emailed token, never the token itself,
    // so a database leak doesn't hand out working links
    verifyToken: { type: String, select: false },
    verifyExpires: { type: Date, select: false },
    resetToken: { type: String, select: false },
    resetExpires: { type: Date, select: false },
  },
  { timestamps: true },
);

// The only user fields any route returns (the `user` shape in docs/api-contract.md)
userSchema.methods.toPublic = function toPublic() {
  return {
    id: this.id,
    firstName: this.firstName,
    lastName: this.lastName,
    email: this.email,
  };
};

module.exports = mongoose.model('User', userSchema);
