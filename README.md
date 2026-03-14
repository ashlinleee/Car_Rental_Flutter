# Car Rental Booking - Flutter + Node.js

Car Rental Booking is a mobile-first application built with Flutter (frontend) and Node.js/Express + MongoDB (backend). It helps users discover cars, book by date/time slot, manage payment methods, and access booking invoices.

## 1. Problem Understanding

Customers need quick access to rental cars from their phones, including clear pricing and simple booking steps. The objective of this case study is to design and implement a practical mobile workflow that reduces booking friction and improves user experience.

This project focuses on:

- Fast vehicle discovery
- Accurate slot-based booking
- Form validation and error feedback
- Transparent pricing and payment flow
- Booking confirmation and invoice access

## 2. Application Design

### UI layout

- Home screen: car listing, location filters (state/place), search, and selection
- Car details screen: detailed specs, pricing information, sections (ratings/reviews/features/FAQ), and similar cars
- Booking screen: customer form, pickup/drop date and time, fare breakdown, coupons, payment selection
- Confirmation screen: booking summary, payment method summary, invoice PDF download
- Profile screen: user profile, booking history, saved payment methods, invoice preview/download from history

### Navigation flow

1. Home -> Car Details
2. Car Details -> Booking
3. Booking -> Confirmation
4. Profile -> Booking History -> View/Download Invoice

The app uses Navigator routes and argument passing between screens.

## 3. Implemented Features

### Core case-study features

- Vehicle listing for browsing available cars
- Booking form validation (customer and payment inputs)
- Date/time pickers for rental duration
- Price calculation logic with dynamic breakdown
- Route-based booking confirmation flow

### Extended features implemented

- Auth: register/login and profile management
- Saved payment methods (UPI/Card)
- Card validation (number, holder, expiry, CVV) and brand masking
- Coupon support with enabled/locked offers
- Delivery/pickup charge calculation
- Slot overlap validation for availability
- Location-aware filtering (state/place)
- Similar cars with local-priority fallback handling
- Booking history with payment method display
- Invoice preview and PDF download (confirmation + booking history)

## 4. Project Structure

```text
Rental Cars/
  frontend/   # Flutter app
  backend/    # Node.js/Express API + MongoDB models
```

## 5. Tech Stack

- Frontend: Flutter, Dart
- Backend: Node.js, Express
- Database: MongoDB (Mongoose)
- Auth: JWT + bcrypt
- Invoice: PDF generation in Flutter

## 6. Setup and Run

### Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x
- Node.js 16+
- MongoDB (local or remote)

### Backend setup

```bash
cd backend
npm install
```

Create a .env file in backend if needed:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/car_rental
JWT_SECRET=car_rental_jwt_secret_change_in_production
```

Run backend:

```bash
npm run seed   # optional: seed sample cars
npm start
```

### Frontend setup

```bash
cd frontend
flutter pub get
flutter run
```

## 7. API Summary

Important endpoints used by the app:

- GET /api/cars
- GET /api/cars/:id
- POST /api/bookings
- GET /api/profile/bookings
- POST /api/auth/register
- POST /api/auth/login
- GET /health

## 8. Expected Outcome Coverage

The application satisfies the case-study outcome by delivering a complete car browsing and booking workflow with:

- Vehicle discovery
- Booking form flow with validation
- Rental period selection
- Price computation
- Confirmation route and invoice support

It demonstrates how mobile technology can simplify everyday rental tasks with a practical and user-friendly design.
