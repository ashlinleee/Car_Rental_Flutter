/**
 * server.js — Express REST API for the Car Rental (Brumm) application.
 *
 * Endpoints:
 *   GET    /health                              — Health/liveness check
 *   GET    /api/cars                            — List/search/filter cars with slot-aware availability
 *   GET    /api/cars/:id                        — Fetch a single car by MongoDB ID
 *   GET    /api/categories                      — Distinct car categories
 *   POST   /api/bookings                        — Create a new booking (overlap-checked)
 *   GET    /api/bookings                        — All bookings, car populated (admin use)
 *   GET    /api/bookings/:id                    — Single booking by ID
 *   DELETE /api/bookings/:id                    — Cancel (delete) a booking
 *   POST   /api/auth/register                   — Register a new user
 *   POST   /api/auth/login                      — Authenticate and receive a JWT
 *   GET    /api/auth/me                         — Current user profile (protected)
 *   PUT    /api/profile                         — Update name/phone (protected)
 *   PUT    /api/profile/password                — Change password (protected)
 *   GET    /api/profile/bookings                — User booking history (protected)
 *   POST   /api/profile/payment-methods         — Save a payment method (protected)
 *   DELETE /api/profile/payment-methods/:index  — Remove a payment method (protected)
 */
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');

const Car = require('./models/Car');
const Booking = require('./models/Booking');
const User = require('./models/User');
const { signToken, protect } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/car_rental';

/**
 * Constructs a UTC Date from a date string and a time string.
 * Using UTC throughout avoids timezone-shift bugs when comparing booking slots.
 *
 * @param {string|Date} dateValue - Date as "YYYY-MM-DD" string or Date object.
 * @param {string}      timeValue - Time as "HH:mm" string.
 * @param {string}      fallback  - Time to use when timeValue is absent/invalid.
 * @returns {Date} UTC Date with the requested calendar date and clock time.
 */
function toDateTime(dateValue, timeValue, fallback = '00:00') {
  let d;
  if (typeof dateValue === 'string' && dateValue.length >= 10) {
    const datePart = dateValue.slice(0, 10);
    const [y, m, day] = datePart.split('-').map((n) => parseInt(n, 10));
    if (Number.isFinite(y) && Number.isFinite(m) && Number.isFinite(day)) {
      d = new Date(Date.UTC(y, m - 1, day)); // UTC midnight — preserves calendar date in ISO string
    }
  }
  d = d || new Date(dateValue);
  const [hh, mm] = String(timeValue || fallback)
    .split(':')
    .map((n) => parseInt(n, 10));
  d.setUTCHours(Number.isFinite(hh) ? hh : 0, Number.isFinite(mm) ? mm : 0, 0, 0);
  return d;
}

/**
 * Returns true when two half-open time intervals [aStart, aEnd) and [bStart, bEnd) overlap.
 * Used to detect whether a new booking conflicts with an existing confirmed booking.
 */
function intervalsOverlap(aStart, aEnd, bStart, bEnd) {
  return aStart < bEnd && aEnd > bStart;
}

// ── Middleware ────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(morgan('dev'));

// ── MongoDB connection ────────────────────────────────────
mongoose
  .connect(MONGODB_URI)
  .then(() => console.log('✅ MongoDB connected:', MONGODB_URI))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
    process.exit(1);
  });

// ── Health check ──────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    db: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
  });
});

// ── GET /api/cars ─────────────────────────────────────────
app.get('/api/cars', async (req, res) => {
  try {
    const { category, available, minPrice, maxPrice, search, sort,
            pickupDate, pickupTime, dropoffDate, dropoffTime,
            state, place } = req.query;

    const filter = {};

    if (state) filter.state = new RegExp(`^${state}$`, 'i');
    if (place) filter.place = new RegExp(`^${place}$`, 'i');
    if (category && category !== 'All') {
      filter.category = new RegExp(`^${category}$`, 'i');
    }

    if (minPrice || maxPrice) {
      filter.pricePerDay = {};
      if (minPrice) filter.pricePerDay.$gte = parseFloat(minPrice);
      if (maxPrice) filter.pricePerDay.$lte = parseFloat(maxPrice);
    }
    if (search) {
      const re = new RegExp(search, 'i');
      filter.$or = [{ name: re }, { brand: re }, { category: re }];
    }

    let sortOrder = { createdAt: -1 };
    if (sort === 'price_asc') sortOrder = { pricePerDay: 1 };
    else if (sort === 'price_desc') sortOrder = { pricePerDay: -1 };
    else if (sort === 'rating_desc') sortOrder = { rating: -1 };
    else if (sort === 'name_asc') sortOrder = { name: 1 };

    const cars = await Car.find(filter).sort(sortOrder);

    // Compute slot-aware availability dynamically from confirmed bookings.
    let conflictingCarIds = new Set();
    if (pickupDate && dropoffDate) {
      const requestStart = toDateTime(`${pickupDate}T00:00:00.000Z`, pickupTime, '00:00');
      const requestEnd = toDateTime(`${dropoffDate}T00:00:00.000Z`, dropoffTime, '23:59');
      const requestStartDay = toDateTime(`${pickupDate}T00:00:00.000Z`, '00:00');
      const requestEndDay = toDateTime(`${dropoffDate}T00:00:00.000Z`, '23:59');

      const roughOverlaps = await Booking.find({
        status: 'Confirmed',
        startDate: { $lte: requestEndDay },
        endDate: { $gte: requestStartDay },
      })
        .select('carId startDate endDate startTime endTime')
        .lean();

      conflictingCarIds = new Set(
        roughOverlaps
          .filter((b) => {
            const bookingStart = toDateTime(b.startDate, b.startTime, '00:00');
            const bookingEnd = toDateTime(b.endDate, b.endTime, '23:59');
            return intervalsOverlap(bookingStart, bookingEnd, requestStart, requestEnd);
          })
          .map((b) => String(b.carId))
      );
    }

    let responseCars = cars.map((car) => {
      const data = car.toJSON();
      data.isAvailable = !conflictingCarIds.has(data.id);
      return data;
    });

    // Explicit availability filter if requested by client.
    if (available !== undefined) {
      const onlyAvailable = available === 'true';
      responseCars = responseCars.filter((c) => c.isAvailable === onlyAvailable);
    }

    res.json({ success: true, data: responseCars, total: responseCars.length });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch cars', error: err.message });
  }
});

// ── GET /api/cars/:id ─────────────────────────────────────
app.get('/api/cars/:id', async (req, res) => {
  try {
    const car = await Car.findById(req.params.id);
    if (!car) return res.status(404).json({ success: false, message: 'Car not found' });
    res.json({ success: true, data: car });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch car', error: err.message });
  }
});

// ── POST /api/bookings ────────────────────────────────────
app.post('/api/bookings', async (req, res) => {
  try {
    const {
      carId,
      customerName,
      customerEmail,
      customerPhone,
      startDate,
      endDate,
      startTime,
      endTime,
      pickupSpot,
      dropoffSpot,
      totalPrice,
      paymentMethodType,
      paymentMethodLabel,
    } = req.body;

    if (!carId || !customerName || !customerEmail || !customerPhone || !startDate || !endDate) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const car = await Car.findById(carId);
    if (!car) return res.status(404).json({ success: false, message: 'Car not found' });

    // Slot-based conflict check: allow booking unless this exact period overlaps another confirmed booking.
    const requestStart = toDateTime(startDate, startTime, '00:00');
    const requestEnd = toDateTime(endDate, endTime, '23:59');
    if (requestEnd <= requestStart) {
      return res.status(400).json({
        success: false,
        message: 'End date/time must be after start date/time.',
      });
    }
    const requestStartDay = toDateTime(startDate, '00:00');
    const requestEndDay = toDateTime(endDate, '23:59');
    const existingBookings = await Booking.find({
      carId,
      status: 'Confirmed',
      startDate: { $lte: requestEndDay },
      endDate: { $gte: requestStartDay },
    })
      .select('startDate endDate startTime endTime')
      .lean();

    const hasConflict = existingBookings.some((b) => {
      const bookingStart = toDateTime(b.startDate, b.startTime, '00:00');
      const bookingEnd = toDateTime(b.endDate, b.endTime, '23:59');
      return intervalsOverlap(bookingStart, bookingEnd, requestStart, requestEnd);
    });

    if (hasConflict) {
      return res.status(409).json({
        success: false,
        message: 'Car is already booked for the selected date/time slot.',
      });
    }

    // Extract userId from Bearer token if provided (optional auth)
    let userId = null;
    const auth = req.headers.authorization;
    if (auth && auth.startsWith('Bearer ')) {
      try {
        const jwt = require('jsonwebtoken');
        const JWT_SECRET = process.env.JWT_SECRET || 'car_rental_jwt_secret_change_in_production';
        const decoded = jwt.verify(auth.split(' ')[1], JWT_SECRET);
        userId = decoded.id;
      } catch { /* token invalid/expired — proceed as guest */ }
    }

    const booking = await Booking.create({
      userId,
      carId: car._id,
      customerName,
      customerEmail,
      customerPhone,
      startDate: toDateTime(startDate, '00:00'),
      endDate: toDateTime(endDate, '00:00'),
      startTime: startTime || '09:00',
      endTime: endTime || '09:00',
      pickupSpot: pickupSpot || '',
      dropoffSpot: dropoffSpot || '',
      totalPrice: parseFloat(totalPrice),
      paymentMethodType: paymentMethodType || '',
      paymentMethodLabel: paymentMethodLabel || '',
      status: 'Confirmed',
    });

    res.status(201).json({
      success: true,
      data: booking,
      message: 'Booking created successfully',
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Failed to create booking',
      error: err.message,
    });
  }
});

// ── GET /api/bookings ─────────────────────────────────────
app.get('/api/bookings', async (req, res) => {
  try {
    const bookings = await Booking.find().sort({ createdAt: -1 }).populate('carId');
    res.json({ success: true, data: bookings, total: bookings.length });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch bookings',
      error: err.message,
    });
  }
});

// ── GET /api/bookings/:id ─────────────────────────────────
app.get('/api/bookings/:id', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id).populate('carId');
    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
    res.json({ success: true, data: booking });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch booking',
      error: err.message,
    });
  }
});

// ── DELETE /api/bookings/:id ──────────────────────────────
app.delete('/api/bookings/:id', async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

    await booking.deleteOne();

    res.json({ success: true, message: 'Booking cancelled successfully' });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Failed to cancel booking',
      error: err.message,
    });
  }
});

// ── GET /api/categories ───────────────────────────────────
app.get('/api/categories', async (req, res) => {
  try {
    const categories = await Car.distinct('category');
    res.json({ success: true, data: categories });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch categories',
      error: err.message,
    });
  }
});

// ── POST /api/auth/register ───────────────────────────────
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, phone, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required.' });
    }
    const existing = await User.findOne({ email: email.toLowerCase().trim() });
    if (existing) {
      return res.status(409).json({ success: false, message: 'An account with this email already exists.' });
    }
    const user = await User.create({ name, email, phone: phone || '', password });
    const token = signToken(user._id);
    res.status(201).json({ success: true, token, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Registration failed', error: err.message });
  }
});

// ── POST /api/auth/login ──────────────────────────────────
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }
    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }
    const token = signToken(user._id);
    // Return user without password (toJSON transform strips it)
    res.json({ success: true, token, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Login failed', error: err.message });
  }
});

// ── GET /api/auth/me ──────────────────────────────────────
app.get('/api/auth/me', protect, (req, res) => {
  res.json({ success: true, data: req.user });
});

// ── PUT /api/profile ──────────────────────────────────────
app.put('/api/profile', protect, async (req, res) => {
  try {
    const { name, phone } = req.body;
    const updates = {};
    if (name) updates.name = name.trim();
    if (phone !== undefined) updates.phone = phone.trim();
    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    });
    res.json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to update profile', error: err.message });
  }
});

// ── PUT /api/profile/password ─────────────────────────────
app.put('/api/profile/password', protect, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Both currentPassword and newPassword are required.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'New password must be at least 6 characters.' });
    }
    const user = await User.findById(req.user._id).select('+password');
    if (!(await user.comparePassword(currentPassword))) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect.' });
    }
    user.password = newPassword;
    await user.save();
    res.json({ success: true, message: 'Password updated successfully.' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to update password', error: err.message });
  }
});

// ── GET /api/profile/bookings ─────────────────────────────
app.get('/api/profile/bookings', protect, async (req, res) => {
  try {
    const bookings = await Booking.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .populate('carId');
    res.json({ success: true, data: bookings, total: bookings.length });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch bookings', error: err.message });
  }
});

// ── POST /api/profile/payment-methods ────────────────────
app.post('/api/profile/payment-methods', protect, async (req, res) => {
  try {
    const { type, label, token } = req.body;
    if (!label || !token) {
      return res.status(400).json({ success: false, message: 'label and token are required.' });
    }
    const user = await User.findById(req.user._id);
    user.savedPaymentMethods.push({ type: type || 'card', label, token });
    await user.save();
    res.json({ success: true, data: user.savedPaymentMethods });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to save payment method', error: err.message });
  }
});

// ── DELETE /api/profile/payment-methods/:index ────────────
app.delete('/api/profile/payment-methods/:index', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const idx = parseInt(req.params.index, 10);
    if (isNaN(idx) || idx < 0 || idx >= user.savedPaymentMethods.length) {
      return res.status(400).json({ success: false, message: 'Invalid index.' });
    }
    user.savedPaymentMethods.splice(idx, 1);
    await user.save();
    res.json({ success: true, data: user.savedPaymentMethods });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to remove payment method', error: err.message });
  }
});

// ── Error handler ─────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error',
  });
});

// ── 404 handler ───────────────────────────────────────────
app.use('*', (req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ── Start ─────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`🚗 Car Rental API running on port ${PORT}`);
  console.log(`📊 Health: http://localhost:${PORT}/health`);
  console.log(`🔗 API:    http://localhost:${PORT}/api`);
});

module.exports = app;
