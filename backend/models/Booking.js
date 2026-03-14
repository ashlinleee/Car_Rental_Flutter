/**
 * Booking.js — Mongoose model for car rental bookings.
 *
 * Stores the complete booking record including:
 *   - Customer contact details (name, email, phone)
 *   - Reference to the booked car (carId) and optional linked user (userId)
 *   - Rental period: startDate/endDate (Date) + startTime/endTime ("HH:mm")
 *   - Pricing, payment method info, pickup/dropoff spots
 *   - Status lifecycle: Confirmed → Completed | Cancelled
 *
 * The toJSON transform exposes a plain `id` string, flattens a populated
 * carId object (adds id, removes _id/__v), and strips internal Mongoose fields.
 */
const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    userId: {
      // Optional — null for guest bookings, set for logged-in users
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    carId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Car',
      required: [true, 'Car ID is required'],
    },
    customerName: {
      type: String,
      required: [true, 'Customer name is required'],
      trim: true,
    },
    customerEmail: {
      type: String,
      required: [true, 'Customer email is required'],
      trim: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email'],
    },
    customerPhone: {
      type: String,
      required: [true, 'Customer phone is required'],
      trim: true,
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date,
      required: [true, 'End date is required'],
    },
    startTime: {
      // Pickup time in "HH:mm" format
      type: String,
      default: '09:00',
    },
    endTime: {
      // Drop-off time in "HH:mm" format
      type: String,
      default: '09:00',
    },
    pickupSpot: {
      type: String,
      trim: true,
      default: '',
    },
    dropoffSpot: {
      type: String,
      trim: true,
      default: '',
    },
    totalPrice: {
      type: Number,
      required: [true, 'Total price is required'],
      min: 0,
    },
    paymentMethodType: {
      type: String,
      trim: true,
      default: '',
    },
    paymentMethodLabel: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['Confirmed', 'Cancelled', 'Completed'],
      default: 'Confirmed',
    },
  },
  {
    timestamps: true,
    toJSON: {
      // Flatten populated carId and remap _id → id for clean API output
      transform(doc, ret) {
        ret.id = ret._id.toString();
        if (doc.populated('carId') && ret.carId && typeof ret.carId === 'object') {
          if (ret.carId._id) {
            ret.carId.id = ret.carId._id.toString();
            delete ret.carId._id;
          }
          delete ret.carId.__v;
        } else {
          ret.carId = ret.carId?.toString();
        }
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

module.exports = mongoose.model('Booking', bookingSchema);
