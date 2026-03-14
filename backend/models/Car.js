/**
 * Car.js — Mongoose model for rental car inventory.
 *
 * Each car document stores its make/model, category, pricing, seat count,
 * transmission, fuel type, availability flag, geographic location (state/place),
 * and a list of features (e.g. "Sunroof", "Bluetooth").
 *
 * The toJSON transform exposes a plain `id` string and removes the internal
 * Mongoose fields (_id, __v) so the API response is clean.
 */
const mongoose = require('mongoose');

const carSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Car name is required'],
      trim: true,
    },
    brand: {
      type: String,
      required: [true, 'Brand is required'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: ['Sedan', 'SUV', 'Luxury', 'Sports', 'Electric', 'Economy'],
    },
    pricePerDay: {
      type: Number,
      required: [true, 'Price per day is required'],
      min: [0, 'Price must be positive'],
    },
    imageUrl: {
      type: String,
      required: [true, 'Image URL is required'],
    },
    seats: {
      type: Number,
      required: true,
      min: 2,
      max: 12,
    },
    transmission: {
      type: String,
      required: true,
      enum: ['Automatic', 'Manual'],
    },
    fuelType: {
      type: String,
      required: true,
      enum: ['Petrol', 'Diesel', 'Electric', 'Hybrid', 'CNG'],
    },
    rating: {
      type: Number,
      default: 4.0,
      min: 0,
      max: 5,
    },
    isAvailable: {
      type: Boolean,
      default: true,
    },
    features: {
      type: [String],
      default: [],
    },
    description: {
      // Optional free-text description of the car
      type: String,
      trim: true,
      default: '',
    },
    state: {
      // Indian state where the car is available (e.g. "Maharashtra")
      type: String,
      trim: true,
      default: '',
    },
    place: {
      // City/town within the state (e.g. "Pune")
      type: String,
      trim: true,
      default: '',
    },
  },
  {
    timestamps: true,
    toJSON: {
      // Remap MongoDB _id → id and strip internal fields before sending to client
      transform(doc, ret) {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

module.exports = mongoose.model('Car', carSchema);
