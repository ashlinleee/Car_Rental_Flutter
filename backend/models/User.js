/**
 * User.js — Mongoose model for registered customers.
 *
 * Stores account credentials (email + bcrypt-hashed password), contact info
 * (name, phone), and an optional list of saved payment methods (card/UPI tokens).
 *
 * Security notes:
 *   - Passwords are bcrypt-hashed (cost 12) via a pre-save hook.
 *   - The toJSON transform strips the password field so it is never sent to clients.
 *   - savedPaymentMethods stores only masked identifiers — no raw card numbers.
 */
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      trim: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    phone: {
      type: String,
      trim: true,
      default: '',
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
    },
    savedPaymentMethods: {
      type: [
        {
          // type: 'card' or 'upi'
          type: { type: String, enum: ['card', 'upi'], default: 'card' },
          label: String,   // e.g. "HDFC •••• 4242"
          token: String,   // masked identifier (no real card data stored)
        },
      ],
      default: [],
    },
  },
  {
    timestamps: true,
    toJSON: {
      // Strip password, _id, and __v before the document reaches the client
      transform(doc, ret) {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        delete ret.password; // never expose password
      },
    },
  },
    // Hash password before creating or updating a user document

// Hash password before save
userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 12);
    // Constant-time comparison to prevent timing attacks
}));

userSchema.methods.comparePassword = function (candidate) {
  return bcrypt.compare(candidate, this.password);
};

module.exports = mongoose.model('User', userSchema);
