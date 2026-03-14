# Case Study Report

## Title

- Project Title: Car Rental Booking Mobile Application
- Subject / Course Name: Flutter
- Student Name: Ashlin Lee George
- Roll Number: 150096723011
- College Name: ITM Skills University
- Submission Date: 13th Feb 2026

---

## Abstract

This project presents the design and development of a Flutter-based Car Rental Booking mobile application created to solve a practical problem: customers need quick, reliable, and user-friendly access to rental cars using mobile devices. The application enables users to browse available vehicles, inspect vehicle details, choose pickup and drop dates/times, complete validated booking forms, and confirm bookings through a clear navigation flow. It also supports payment method selection, booking history review, and invoice preview/download for completed bookings.

The solution is implemented using Flutter and Dart on the frontend, with a Node.js and Express backend connected to MongoDB via Mongoose for data persistence. Authentication and protected workflows are supported with JWT-based login handling. The system includes slot-based availability checks to reduce booking conflicts and pricing logic to generate transparent fare summaries before confirmation.

Key features include vehicle listing, booking form validation, date/time picker integration, dynamic price calculation, route-based confirmation, payment summary display, and invoice generation in PDF format. Overall, the app demonstrates how mobile technology can simplify everyday rental tasks while improving usability, accuracy, and booking efficiency.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Problem Understanding](#2-problem-understanding)
   - 2.1 Problem Statement
   - 2.2 Project Objective
   - 2.3 Expected Outcome
3. [Requirement Analysis](#3-requirement-analysis)
   - 3.1 Functional Requirements
   - 3.2 Non-Functional Requirements
4. [Application Design](#4-application-design)
   - 4.1 UI Design
   - 4.2 Navigation Flow
   - 4.3 System Architecture
   - 4.4 Modules of the System
5. [Documentation of Workflow and Implemented Features](#5-documentation-of-workflow-and-implemented-features)
   - 5.1 End-to-End Workflow
   - 5.2 Core Features Implemented
   - 5.3 Practical Enhancements Implemented
   - 5.4 Visual Evidence (Frontend Screenshots)
   - 5.5 Demo Video Evidence
6. [Technology Stack](#6-technology-stack)
7. [Project Structure](#7-project-structure)
8. [Testing and Validation Summary](#8-testing-and-validation-summary)
9. [Conclusion](#9-conclusion)
10. [Future Scope](#10-future-scope)

---

## 1. Introduction

Car rental systems have evolved from manual desk-based operations to digital platforms that connect customers, vehicles, and booking operations in real time. In traditional rental workflows, users often face delays in checking availability, comparing vehicle options, understanding total cost, and completing documentation. These limitations create friction in the booking journey and can reduce customer confidence, especially when transparency and speed are critical.

In transportation services, mobile applications play a central role by enabling anytime-anywhere access to vehicles and rental services. A well-designed mobile app can simplify the user journey through searchable listings, instant availability checks, guided booking forms, and quick confirmations. Mobile platforms also improve service quality by reducing operational dependency on calls or physical visits and by presenting pricing and booking details in a clear, structured way.

The purpose of this project is to design and implement a Flutter-based Car Rental Booking mobile application that demonstrates practical, user-centric transportation service design. The application is intended to provide a complete booking flow, from vehicle discovery to confirmation, while maintaining usability, validation accuracy, and transparent fare presentation.

The objective of this project is to design and implement an intuitive car rental mobile application that supports:

- Vehicle discovery
- Booking input validation
- Date/time selection for rental duration
- Dynamic price calculation
- Confirmation through route-based navigation

## 2. Problem Understanding

### 2.1 Problem Statement

Renting a car is often a time-sensitive task, but many users face difficulties when trying to find suitable vehicles quickly. Common user challenges include checking real-time availability, comparing multiple cars, understanding total rental cost before booking, and completing bookings without delays. These issues directly affect convenience and user trust, especially for customers who need on-demand transportation.

Traditional booking systems have several limitations. Manual or semi-digital workflows may require phone calls, branch visits, repeated data entry, and delayed confirmations. Availability information may not be updated in real time, and pricing can appear unclear until late in the process. In addition, fragmented communication between customer support, inventory, and payment steps creates friction in the booking journey.

Because of these limitations, a mobile-based solution is necessary. A mobile application can centralize vehicle discovery, availability checks, booking form submission, and confirmation into one streamlined flow. It provides users with anytime-anywhere access, faster interaction, better transparency, and reduced operational dependency on manual processes. Therefore, the core problem addressed in this case study is how to deliver a simple, reliable, and efficient car rental experience through a mobile-first system.

### 2.2 Project Objective

The primary objective of this project is to design and develop a Flutter-based mobile application that provides an end-to-end car rental booking experience for everyday users. The application aims to:

1. **Simplify vehicle discovery** — Allow users to browse and filter available cars based on location, date, and time without requiring phone calls or branch visits.
2. **Streamline the booking process** — Guide users through a structured, validated booking form that captures all required rental information in a single flow.
3. **Ensure transparent pricing** — Compute and display the total rental cost before confirmation so users understand what they will be charged.
4. **Support post-booking management** — Enable users to review past bookings, access payment summaries, and download or preview invoices at any time.
5. **Demonstrate practical mobile UX** — Showcase a complete mobile application architecture using Flutter and a supporting backend, aligned with industry-standard development practices.

### 2.3 Expected Outcome

Upon successful completion, the application is expected to deliver the following outcomes:

| Outcome                    | Description                                                      |
| -------------------------- | ---------------------------------------------------------------- |
| Working mobile application | A fully functional Flutter app runnable on Android, iOS, and web |
| Complete booking flow      | Users can discover → detail → book → confirm without friction    |
| Validated user input       | All forms reject invalid data before API submission              |
| Real-time availability     | Vehicles reflect slot-based availability for selected date/time  |
| Invoice generation         | PDF invoices downloadable from booking history                   |
| Secure authentication      | JWT-protected routes and session management                      |
| Responsive layout          | UI adapts correctly to compact and wide screen formats           |

## 3. Requirement Analysis

### 3.1 Functional Requirements

1. Vehicle listing using GridView-style browsing.
2. Vehicle detail display with relevant specifications.
3. Booking form with validation for user details.
4. Date picker/time picker for rental duration.
5. Price calculation logic for total payable amount.
6. Navigator routes for booking confirmation.

### 3.2 Non-Functional Requirements

1. Mobile-first responsive design.
2. Intuitive and low-friction navigation.
3. Clear validation and error handling.
4. Maintainable structure and modular code organization.

## 4. Application Design

### 4.1 UI Design

#### 4.1.1 Overall Layout

The application uses a screen-per-task layout pattern where each major user action is isolated in its own screen. This reduces cognitive load by showing only what is relevant to the current step. All screens share a consistent visual structure:

- **AppBar** at the top with title, optional back navigation, and action icons.
- **Body** containing the primary content area (scrollable where needed).
- **Bottom action area** (buttons or FAB) for primary CTAs on task-focused screens.

The layout adapts to screen width using `LayoutBuilder` and `MediaQuery` so that content reflows correctly on compact mobile devices as well as on wider tablet or web viewports. For example, on narrow screens the booking action buttons stack vertically using `Column(crossAxisAlignment: CrossAxisAlignment.stretch)`, while on wider screens they appear side-by-side using `Row` with `Expanded` children.

#### 4.1.2 Material Design Components

The application is built on Flutter's Material Design 3 widget system to ensure platform-consistent visual language and interaction patterns:

| Component                   | Used In                                 | Purpose                                    |
| --------------------------- | --------------------------------------- | ------------------------------------------ |
| `Scaffold`                  | All screens                             | Base layout with AppBar and body           |
| `AppBar`                    | All screens                             | Title, back button, and contextual actions |
| `Card`                      | Vehicle list, booking history           | Elevated surface for grouped content       |
| `ListTile`                  | Profile details, booking summary        | Icon + label rows for structured display   |
| `TextFormField`             | Booking form, auth screens              | Validated text input with labels and hints |
| `ElevatedButton`            | Primary CTAs (Book Now, Confirm)        | High-emphasis action buttons               |
| `OutlinedButton`            | Secondary CTAs (View Invoice, Download) | Medium-emphasis supplementary actions      |
| `AlertDialog`               | Invoice preview, confirmations          | Overlay dialogs for quick interactions     |
| `BottomSheet`               | Payment method selector                 | Slide-up panel for contextual choices      |
| `Chip`                      | Filters, vehicle tags                   | Compact labels for specs and categories    |
| `CircularProgressIndicator` | Loading states                          | Feedback during async API calls            |
| `SnackBar`                  | Success / error feedback                | Transient messages post-action             |
| `DatePicker / TimePicker`   | Booking form                            | Platform-native date and time selection    |

#### 4.1.3 GridView Layout (Vehicle Listing)

The Home screen uses Flutter's `GridView.builder` to display available vehicles in a responsive multi-column grid:

```
┌──────────────┬──────────────┐
│  Car Card 1  │  Car Card 2  │
│  [Image]     │  [Image]     │
│  Name        │  Name        │
│  Brand │ Cat │  Brand │ Cat │
│  ₹ / hr      │  ₹ / hr      │
└──────────────┴──────────────┘
┌──────────────┬──────────────┐
│  Car Card 3  │  Car Card 4  │
│     ...      │     ...      │
└──────────────┴──────────────┘
```

- **Column count**: 2 columns on mobile; accommodates more on wider screens via `crossAxisCount` derived from `MediaQuery.of(context).size.width`.
- **Item layout**: Each grid cell renders a `Card` containing a vehicle image, name, brand, category badge, seating capacity, transmission type, and price per hour.
- **Aspect ratio**: `childAspectRatio` is tuned to keep cards uniformly proportioned regardless of text length.
- **Lazy loading**: `GridView.builder` renders only visible items on-screen, reducing widget tree size for large vehicle catalogs.
- **Tap interaction**: Tapping a card navigates to `CarDetailScreen` with the selected car's data passed as a route argument.

### 4.2 Navigation Flow

#### 4.2.1 Screen Transition Map

```
[LoginScreen] ─────────────────────────────────────┐
      │ (on successful login)                       │
      ▼                                             │
[HomeScreen]  ◄──────────────────────────── (back) │
      │ (tap vehicle card)                          │
      ▼                                             │
[CarDetailScreen]  ◄──────────── (back)            │
      │ (tap "Book Now")                            │
      ▼                                             │
[BookingScreen]  ◄──────────── (back)              │
      │ (form valid + submit)                       │
      ▼                                             │
[ConfirmationScreen]  (back navigation disabled)   │
      │ (tap "Back to Home")                        │
      ▼                                             │
[HomeScreen]                                        │
                                                    │
[ProfileScreen]  ◄──────── (bottom nav / drawer) ──┘
      │ (bookings tab)
      ▼
[BookingHistoryTab]
      │ (tap "View Invoice")
      ▼
[InvoicePreviewDialog]  (modal overlay)
      │ (tap "Download PDF")
      ▼
  [File saved to device]
```

#### 4.2.2 Navigation Mechanisms

| Transition                    | Method                           | Reason                                            |
| ----------------------------- | -------------------------------- | ------------------------------------------------- |
| Home → Car Details            | `Navigator.push`                 | Allows back navigation                            |
| Car Details → Booking         | `Navigator.push`                 | Allows back navigation                            |
| Booking → Confirmation        | `Navigator.pushReplacement`      | Replaces booking form; prevents back to re-submit |
| Confirmation → Home           | `Navigator.pushAndRemoveUntil`   | Clears entire back stack; fresh start             |
| Any → Profile                 | `Navigator.push` or bottom nav   | Preserves home stack                              |
| Any → Login (unauthenticated) | `Navigator.pushReplacementNamed` | Clears stack; forces re-login                     |

#### 4.2.3 Route Guard (Auth Check)

Before navigating to protected screens (Booking, Profile), the app checks for a stored JWT token in `shared_preferences`. If no valid token is found, the user is redirected to `LoginScreen` instead of the intended destination. This ensures that unauthenticated users cannot access booking or history data.

```
User taps "Book Now"
        │
        ▼
  Token in storage?
     │         │
    YES        NO
     │         │
     ▼         ▼
BookingScreen  LoginScreen
                (with redirect-back intent)
```

#### 4.2.4 Bottom Navigation

A `BottomNavigationBar` (or equivalent navigation drawer on wider layouts) provides persistent access to the top-level sections:

| Tab     | Screen        | Icon     |
| ------- | ------------- | -------- |
| Home    | HomeScreen    | `home`   |
| Profile | ProfileScreen | `person` |

Switching tabs preserves the state of each section so the user does not lose scroll position or form progress when temporarily switching to another tab.

### 4.3 System Architecture

The application follows a **three-tier client-server architecture**, with clear separation between the presentation layer, the application logic layer, and the data layer.

#### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE CLIENT                            │
│                    (Flutter / Dart)                             │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              User Interface Layer                        │  │
│  │  HomeScreen │ CarDetailScreen │ BookingScreen            │  │
│  │  ConfirmationScreen │ ProfileScreen │ AuthScreens        │  │
│  └──────────────────────┬───────────────────────────────────┘  │
│                         │                                       │
│  ┌──────────────────────▼───────────────────────────────────┐  │
│  │            Application Logic Layer                       │  │
│  │  Form Validation │ Price Calculation │ Date/Time Logic   │  │
│  │  PDF Generation  │ Invoice Export    │ Auth State Mgmt   │  │
│  └──────────────────────┬───────────────────────────────────┘  │
│                         │                                       │
│  ┌──────────────────────▼───────────────────────────────────┐  │
│  │             Navigation System                            │  │
│  │  Named Routes │ Navigator.push │ Navigator.pushReplacement│  │
│  │  Route guards (auth check before protected screens)      │  │
│  └──────────────────────┬───────────────────────────────────┘  │
└────────────────────────┬─────────────────────────────────────── ┘
                         │  HTTP (REST API / JSON)
                         │  Authorization: Bearer <JWT>
┌────────────────────────▼──────────────────────────────────────┐
│                     BACKEND SERVER                            │
│                  (Node.js + Express)                          │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  API / Route Layer                      │ │
│  │  /api/auth  │  /api/cars  │  /api/bookings              │ │
│  │  /api/profile/bookings   │  /api/payments               │ │
│  └──────────────────────┬──────────────────────────────────┘ │
│                         │                                     │
│  ┌──────────────────────▼──────────────────────────────────┐ │
│  │              Middleware Layer                           │ │
│  │  JWT Auth Middleware │ Input Validation │ Error Handler │ │
│  └──────────────────────┬──────────────────────────────────┘ │
│                         │                                     │
│  ┌──────────────────────▼──────────────────────────────────┐ │
│  │              Business Logic Layer                       │ │
│  │  Slot Availability Check │ Booking Conflict Detection   │ │
│  │  bcrypt Password Hashing │ JWT Token Generation         │ │
│  └──────────────────────┬──────────────────────────────────┘ │
└────────────────────────┬──────────────────────────────────────┘
                         │  Mongoose ODM
┌────────────────────────▼──────────────────────────────────────┐
│                      DATA LAYER                               │
│                  (MongoDB Database)                           │
│                                                               │
│  Collections:  Users │ Cars │ Bookings │ Payments            │
└───────────────────────────────────────────────────────────────┘
```

#### 4.3.1 User Interface Layer

The UI layer is built entirely in Flutter using Dart. Each screen is a self-contained widget tree that handles its own layout and rendering. Screens communicate with the logic layer through local state management (StatefulWidget / setState) and shared preferences for session persistence. UI components include custom cards, form fields, date pickers, bottom sheets, and dialog boxes.

**Key screens and their roles:**

| Screen                         | Role                                          |
| ------------------------------ | --------------------------------------------- |
| `HomeScreen`                   | Vehicle listing, search, and filter           |
| `CarDetailScreen`              | Vehicle specs, pricing, and booking CTA       |
| `BookingScreen`                | Customer details form, date/time, payment     |
| `ConfirmationScreen`           | Booking success, fare summary, invoice        |
| `ProfileScreen`                | Auth state, booking history, invoice download |
| `LoginScreen / RegisterScreen` | JWT-based user authentication                 |

#### 4.3.2 Application Logic Layer

This layer handles all data processing and business rules within the Flutter client:

- **Form Validation**: Required field checks, phone/email format rules, date-range consistency, and payment input validation are enforced before submission.
- **Price Calculation**: Duration is computed from selected start/end date-times, multiplied by per-hour/day rate. Coupon discounts and fare components are factored into the total.
- **Date and Time Logic**: Prevents selection of past dates, ensures end date is not before start date, and validates time slot consistency.
- **PDF Invoice Generation**: Uses the `pdf` package to construct a formatted invoice document from booking data, rendered in memory and saved via the `file_selector` package.
- **Auth State Management**: JWT token is stored in `shared_preferences`. All API calls include the token in the `Authorization` header. Screens redirect to login if no valid session is found.

#### 4.3.3 Navigation System

Flutter's `Navigator` stack is used for route-based screen transitions:

- **Named routes** are defined globally in `MaterialApp` for consistent navigation paths.
- **`Navigator.push`** is used for forward navigation (e.g., Home → Car Details → Booking).
- **`Navigator.pushReplacement`** is used post-confirmation to prevent back-navigation to the booking form.
- **Route Guards**: Before navigating to protected screens (Booking, Profile), the app checks for a valid JWT token stored locally. If absent, the user is redirected to the login screen.

| Route           | Action                        |
| --------------- | ----------------------------- |
| `/`             | HomeScreen (vehicle listing)  |
| `/car-detail`   | CarDetailScreen               |
| `/booking`      | BookingScreen                 |
| `/confirmation` | ConfirmationScreen            |
| `/profile`      | ProfileScreen (auth required) |
| `/login`        | LoginScreen                   |
| `/register`     | RegisterScreen                |

#### 4.3.4 Backend Service Layer

The Node.js/Express backend exposes a REST API consumed by the Flutter client over HTTP. Each route group maps to a specific domain:

- **`/api/auth`** — Registration, login, JWT issuance
- **`/api/cars`** — Vehicle listing with slot-aware availability filtering
- **`/api/bookings`** — Booking creation with conflict detection
- **`/api/profile/bookings`** — Authenticated booking history retrieval

Each request to a protected route passes through the `authMiddleware`, which verifies the JWT before allowing handler execution.

#### 4.3.5 Data Layer

MongoDB is used as the persistent store, accessed via Mongoose ODM. Key collections:

| Collection | Purpose                                         |
| ---------- | ----------------------------------------------- |
| `users`    | User accounts (hashed passwords, JWT reference) |
| `cars`     | Vehicle catalog with specs and pricing          |
| `bookings` | Booking records with slot times and status      |

Data flows from the Flutter client as JSON, is validated and processed by the Express handlers, and persisted or queried from MongoDB before the response is returned to the client.

### 4.4 Modules of the System

The application is divided into clearly defined functional modules. Each module handles a specific responsibility and communicates with adjacent modules through well-defined interfaces (API calls, route arguments, and shared state).

#### Module Overview Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    CAR RENTAL APPLICATION                        │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│  Auth        │  Vehicle     │  Booking     │  Profile &         │
│  Module      │  Module      │  Module      │  History Module    │
├──────────────┼──────────────┼──────────────┼────────────────────┤
│  Payment     │  Availability│  Invoice     │  Profile &         │
│  Module      │  Module      │  Module      │  History Support   │
└──────────────┴──────────────┴──────────────┴────────────────────┘
                         │
              ┌──────────▼──────────┐
              │   Backend API Layer  │
              │  (Node.js / Express) │
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │   MongoDB Database   │
              └─────────────────────┘
```

---

#### Module 1 — Authentication Module

**Purpose:** Manages user identity — registration, login, session persistence, and logout.

**Screens involved:** `LoginScreen`, `RegisterScreen`

**Key responsibilities:**

- Accepts user credentials (name, email, phone, password) for registration.
- Validates credential format before submission.
- Sends registration/login request to `/api/auth/register` and `/api/auth/login`.
- Receives and stores JWT token in `shared_preferences` for session continuity.
- Provides token to all other modules for authenticated API requests.
- Clears token on logout and redirects to `LoginScreen`.

**Backend endpoints:**

| Endpoint             | Method | Description                         |
| -------------------- | ------ | ----------------------------------- |
| `/api/auth/register` | POST   | Create new user account             |
| `/api/auth/login`    | POST   | Validate credentials and return JWT |

---

#### Module 2 — Vehicle Browsing Module

**Purpose:** Displays the catalog of available rental vehicles and allows users to explore vehicle details.

**Screens involved:** `HomeScreen`, `CarDetailScreen`

**Key responsibilities:**

- Fetches vehicle list from `/api/cars` with optional query params (pickup date, time, location).
- Renders vehicles in a 2-column `GridView` with image, name, brand, category, seating, and price.
- Supports search and filter by availability, location, and vehicle type.
- Navigates to `CarDetailScreen` with the selected car's full data passed as route arguments.
- Displays complete specifications (fuel type, transmission, seating, pricing) for decision-making.

**Backend endpoints:**

| Endpoint        | Method | Description                                           |
| --------------- | ------ | ----------------------------------------------------- |
| `/api/cars`     | GET    | Fetch all available vehicles (supports filter params) |
| `/api/cars/:id` | GET    | Fetch single vehicle by ID                            |

---

#### Module 3 — Booking Module

**Purpose:** Collects and validates all information required to create a rental booking.

**Screens involved:** `BookingScreen`, `ConfirmationScreen`

**Key responsibilities:**

- Captures customer name, email, phone number, pickup/dropoff spots.
- Integrates `DatePicker` and `TimePicker` for start and end date/time selection.
- Validates all form fields (required fields, phone format, email format, date-time consistency).
- Calculates total rental price based on duration and per-hour/day rate.
- Applies coupon codes and displays a fare breakdown before submission.
- Submits validated booking data to `/api/bookings` with the JWT token.
- On success, navigates to `ConfirmationScreen` using `Navigator.pushReplacement`.

**Backend endpoints:**

| Endpoint        | Method | Description                          |
| --------------- | ------ | ------------------------------------ |
| `/api/bookings` | POST   | Create a new booking (auth required) |

---

#### Module 4 — Availability Module

**Purpose:** Ensures that a vehicle is not double-booked for overlapping time slots.

**Layer:** Backend (Node.js)

**Key responsibilities:**

- When the vehicles list is requested with `pickupDate`, `pickupTime`, `dropoffDate`, `dropoffTime` query parameters, each car's `isAvailable` flag is computed dynamically.
- Checks the `bookings` collection for any confirmed bookings where the requested slot overlaps with an existing one.
- A car is marked unavailable if: `requestedStart < existingEnd` AND `requestedEnd > existingStart`.
- Unavailable cars are still returned in the listing but flagged, allowing the UI to disable the booking CTA.

---

#### Module 5 — Payment Module

**Purpose:** Manages payment method selection, validation, and storage with booking records.

**Screens involved:** `BookingScreen` (payment section), `ConfirmationScreen`

**Key responsibilities:**

- Presents payment method options: UPI (with UPI ID input) and Card (with card number/expiry input).
- Validates UPI ID format (`user@bank`) and card number format before allowing submission.
- Stores payment method type and label with the booking record.
- Displays payment summary (method label, amount paid) on `ConfirmationScreen` and booking history cards.

---

#### Module 6 — Profile & Booking History Module

**Purpose:** Displays the authenticated user's account info and all past bookings.

**Screens involved:** `ProfileScreen` (tabs: Profile, Bookings, Payments)

**Key responsibilities:**

- Retrieves user profile and booking history from `/api/profile/bookings` using the stored JWT.
- Displays each booking as a card with car name, dates, duration, total price, and payment method.
- Provides actions per booking card: View Invoice (opens preview dialog) and Download Invoice (saves PDF).
- Responsive card layout: full-width stacked buttons on narrow screens; side-by-side on wider screens.

**Backend endpoints:**

| Endpoint                | Method | Description                                               |
| ----------------------- | ------ | --------------------------------------------------------- |
| `/api/profile/bookings` | GET    | Fetch all bookings for the logged-in user (auth required) |

---

#### Module 7 — Invoice Module

**Purpose:** Generates and delivers booking invoices in both plain-text preview and PDF download formats.

**Layer:** Flutter client (in-app generation)

**Key responsibilities:**

- `_historyInvoiceText()` — builds a structured plain-text invoice string from booking data.
- `_showHistoryInvoicePreview()` — displays invoice text in an `AlertDialog` with `SelectableText` (copyable), Copy button, and Download PDF button.
- `_buildHistoryInvoicePdfBytes()` — constructs a formatted PDF document using the `pdf` package (`pw.Document`, `pw.MultiPage`, `PdfPageFormat.a4`).
- `_downloadHistoryInvoice()` — opens a system save dialog via `file_selector` on desktop/web; falls back to clipboard copy on unsupported platforms.

**Invoice content includes:** booking ID, customer details, vehicle name and category, rental period, pickup/dropoff spots, fare breakdown, payment method, and total amount.

---

#### Module Summary Table

| Module            | Layer              | Primary Screen(s)        | Backend Endpoint(s)        |
| ----------------- | ------------------ | ------------------------ | -------------------------- |
| Authentication    | Frontend + Backend | Login, Register          | `/api/auth/*`              |
| Vehicle Browsing  | Frontend + Backend | Home, Car Detail         | `/api/cars`                |
| Booking           | Frontend + Backend | Booking, Confirmation    | `/api/bookings`            |
| Availability      | Backend only       | (used by Vehicle module) | `/api/cars?pickupDate=...` |
| Payment           | Frontend           | Booking, Confirmation    | (stored with booking)      |
| Profile & History | Frontend + Backend | Profile                  | `/api/profile/bookings`    |
| Invoice           | Frontend only      | Profile History cards    | (in-app generation)        |

---

## 5. Documentation of Workflow and Implemented Features

The Car Rental Booking application was implemented using the Flutter framework for the frontend and Node.js with Express for backend services. Flutter Material widgets were used to design the mobile interface, while REST APIs enabled communication between the mobile client and the backend server. Core functionality such as vehicle listing, booking form validation, date selection, and price calculation was implemented using Flutter widgets and Dart logic. The backend handles authentication, booking creation, and availability checks while storing data in a MongoDB database.

### 5.1 End-to-End Workflow

1. User opens app and browses vehicle options.
2. User selects a car and reviews detailed specifications.
3. User enters booking details (personal info, dates/times, payment method).
4. Application validates input fields and date/time consistency.
5. Application computes payable amount using pricing logic.
6. Booking is submitted and confirmation screen is shown.
7. User can later revisit bookings and access invoice preview/download.

### 5.2 Core Features Implemented (Case Study Alignment)

1. Vehicle listing for rental browsing.
2. Form validation for booking accuracy.
3. Date picker/time picker for rental duration.
4. Dynamic price calculation and fare summary.
5. Navigator route-based booking confirmation.

### 5.3 Practical Enhancements Implemented

1. Location-aware vehicle filtering (state/place).
2. Slot-based availability checks to prevent overlap conflicts.
3. Payment method management (UPI/Card) with validation.
4. Coupon and fare component handling.
5. Booking history with payment display.
6. Invoice preview and PDF download.
7. Mobile layout refinements for compact screens.

### 5.4 Visual Evidence (Frontend Screenshots)

All frontend screenshots have been included below as implementation evidence.

#### 5.4.1 Home, Search, and Filters

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-01.png" alt="Figure 1: Home screen with location/date-time input form and search CTA." title="Figure 1: Home screen with location/date-time input form and search CTA." width="360" />
  <div><em>Figure 1: Home screen with location/date-time input form and search CTA.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-05.png" alt="Figure 2: Home screen after search with category chips, sorting, and vehicle cards." title="Figure 2: Home screen after search with category chips, sorting, and vehicle cards." width="360" />
  <div><em>Figure 2: Home screen after search with category chips, sorting, and vehicle cards.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-02.png" alt="Figure 3: State selection bottom sheet from search form." title="Figure 3: State selection bottom sheet from search form." width="360" />
  <div><em>Figure 3: State selection bottom sheet from search form.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-03.png" alt="Figure 4: Date picker dialog used for rental period selection." title="Figure 4: Date picker dialog used for rental period selection." width="360" />
  <div><em>Figure 4: Date picker dialog used for rental period selection.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-04.png" alt="Figure 5: Time picker dialog used for rental period selection." title="Figure 5: Time picker dialog used for rental period selection." width="360" />
  <div><em>Figure 5: Time picker dialog used for rental period selection.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-06.png" alt="Figure 6: Filter and sort panel with price range, fuel type filters, etc." title="Figure 6: Filter and sort panel with price range, fuel type filters, etc." width="360" />
  <div><em>Figure 6: Filter and sort panel with price range, fuel type filters, etc.</em></div>
</div>

#### 5.4.2 Vehicle Details Experience

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-07.png" alt="Figure 7: Vehicle details top section with image, availability, and rating." title="Figure 7: Vehicle details top section with image, availability, and rating." width="360" />
  <div><em>Figure 7: Vehicle details top section with image, availability, and rating.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-08.png" alt="Figure 8: Vehicle pricing information and feature chips." title="Figure 8: Vehicle pricing information and feature chips." width="360" />
  <div><em>Figure 8: Vehicle pricing information and feature chips.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-09.png" alt="Figure 9: Inclusions and exclusions information block." title="Figure 9: Inclusions and exclusions information block." width="360" />
  <div><em>Figure 9: Inclusions and exclusions information block.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-11.png" alt="Figure 10: FAQs accordion section on vehicle details screen." title="Figure 10: FAQs accordion section on vehicle details screen." width="360" />
  <div><em>Figure 10: FAQs accordion section on vehicle details screen.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-12.png" alt="Figure 11: Important points and policy reminders section." title="Figure 11: Important points and policy reminders section." width="360" />
  <div><em>Figure 11: Important points and policy reminders section.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-13.png" alt="Figure 11A: Additional important points and policy reminders section." title="Figure 11A: Additional important points and policy reminders section." width="360" />
  <div><em>Figure 11A: Additional important points and policy reminders section.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-10.png" alt="Figure 12: User reviews and similar cars recommendation section." title="Figure 12: User reviews and similar cars recommendation section." width="360" />
  <div><em>Figure 12: User reviews and similar cars recommendation section.</em></div>
</div>

#### 5.4.3 Booking and Payment Flow

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-14.png" alt="Figure 13: Booking screen with customer information and rental period summary." title="Figure 13: Booking screen with customer information and rental period summary." width="360" />
  <div><em>Figure 13: Booking screen with customer information and rental period summary.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-15.png" alt="Figure 14: Kilometer plan selection and fare breakdown." title="Figure 14: Kilometer plan selection and fare breakdown." width="360" />
  <div><em>Figure 14: Kilometer plan selection and fare breakdown.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-16.png" alt="Figure 15: Coupon section with locked/available offers." title="Figure 15: Coupon section with locked/available offers." width="360" />
  <div><em>Figure 15: Coupon section with locked/available offers.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-18.png" alt="Figure 16: Coupon applied state with discount confirmation." title="Figure 16: Coupon applied state with discount confirmation." width="360" />
  <div><em>Figure 16: Coupon applied state with discount confirmation.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-17.png" alt="Figure 17: Payment method section using UPI mode." title="Figure 17: Payment method section using UPI mode." width="360" />
  <div><em>Figure 17: Payment method section using UPI mode.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-19.png" alt="Figure 18: Payment method section using credit/debit card mode." title="Figure 18: Payment method section using credit/debit card mode." width="360" />
  <div><em>Figure 18: Payment method section using credit/debit card mode.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-20.png" alt="Figure 19: Booking confirmation summary screen." title="Figure 19: Booking confirmation summary screen." width="360" />
  <div><em>Figure 19: Booking confirmation summary screen.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-21.png" alt="Figure 20: Confirmation details showing customer and payment summary cards." title="Figure 20: Confirmation details showing customer and payment summary cards." width="360" />
  <div><em>Figure 20: Confirmation details showing customer and payment summary cards.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-22.png" alt="Figure 20A: End of confirmation details showing customer and payment summary cards." title="Figure 20A: End of confirmation details showing customer and payment summary cards." width="360" />
  <div><em>Figure 20A: End of confirmation details showing customer and payment summary cards.</em></div>
</div>

#### 5.4.4 Authentication and Profile Management

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-24.png" alt="Figure 21: Sign In screen." title="Figure 21: Sign In screen." width="360" />
  <div><em>Figure 21: Sign In screen.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-30.png" alt="Figure 22: Create Account screen." title="Figure 22: Create Account screen." width="360" />
  <div><em>Figure 22: Create Account screen.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-25.png" alt="Figure 23: Profile tab with personal information and password update form." title="Figure 23: Profile tab with personal information and password update form." width="360" />
  <div><em>Figure 23: Profile tab with personal information and password update form.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-26.png" alt="Figure 24: Bookings tab with booking cards and invoice actions." title="Figure 24: Bookings tab with booking cards and invoice actions." width="360" />
  <div><em>Figure 24: Bookings tab with booking cards and invoice actions.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-27.png" alt="Figure 25: Payments tab with saved payment method management." title="Figure 25: Payments tab with saved payment method management." width="360" />
  <div><em>Figure 25: Payments tab with saved payment method management.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-29.png" alt="Figure 26: Sign-out confirmation dialog from profile." title="Figure 26: Sign-out confirmation dialog from profile." width="360" />
  <div><em>Figure 26: Sign-out confirmation dialog from profile.</em></div>
</div>

#### 5.4.5 Invoice and Post-Booking Evidence

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-28.png" alt="Figure 27: Invoice preview dialog in booking history." title="Figure 27: Invoice preview dialog in booking history." width="360" />
  <div><em>Figure 27: Invoice preview dialog in booking history.</em></div>
</div>

<div style="text-align:center; page-break-inside: avoid; break-inside: avoid; margin: 12px 0 18px;">
  <img src="docs/case-study/screenshots/fig-23.png" alt="Figure 28: Downloaded invoice PDF document view." title="Figure 28: Downloaded invoice PDF document view." width="360" />
  <div><em>Figure 28: Downloaded invoice PDF document view.</em></div>
</div>

### 5.5 Demo Video Evidence

The complete frontend flow demonstration video is available at:

- [YouTube: Car Rental Booking Application](https://youtube.com/shorts/fLtVBOuXiho)
  
## 6. Technology Stack

### 6.1 Frontend — Flutter & Dart

The client application is built with **Flutter** (v3.x, stable channel) using **Dart** as the programming language. Flutter's widget-based architecture delivers a consistent, high-performance UI across Android, iOS, web, and desktop from a single codebase. State is managed using `StatefulWidget` with `setState`, and navigation uses Flutter's `Navigator` stack with named routes.

| Package              | Purpose                                   |
| -------------------- | ----------------------------------------- |
| `http`               | REST API communication with the backend   |
| `shared_preferences` | JWT token and session storage             |
| `intl`               | Date and time formatting and localization |
| `pdf`                | Client-side PDF invoice generation        |
| `file_selector`      | Cross-platform native file save dialog    |
| `flutter_rating_bar` | Star rating display on vehicle cards      |

### 6.2 Backend — Node.js & Express

The server is built with **Node.js** (v18.x LTS) and **Express**, providing a lightweight, middleware-driven REST API. Each route group handles a distinct domain (auth, vehicles, bookings, profile). A custom `authMiddleware` validates JWT tokens before processing protected requests.

| Package        | Purpose                                         |
| -------------- | ----------------------------------------------- |
| `express`      | HTTP server, routing, and middleware            |
| `mongoose`     | MongoDB object modeling (ODM)                   |
| `jsonwebtoken` | JWT token issuance and verification             |
| `bcryptjs`     | Secure password hashing (salt rounds: 10)       |
| `dotenv`       | Environment variable configuration              |
| `cors`         | Cross-origin resource sharing for client access |

### 6.3 Database — MongoDB

**MongoDB** (v6.x) is used as the NoSQL document store, accessed via **Mongoose** ODM. Its schema-flexible design suits the varying structure of vehicle catalogs and booking records. Data is organized into three primary collections: `users`, `cars`, and `bookings`.

### 6.4 Authentication — JWT

**JSON Web Tokens (JWT)** provide stateless, secure authentication. On login or registration, the server issues a signed token. The Flutter client stores it in `shared_preferences` and sends it as `Authorization: Bearer <token>` on every protected API call. The server-side middleware verifies the token before handler execution.

### 6.5 Invoice — Client-Side PDF Generation

PDF invoices are generated entirely on the client using the **`pdf`** Flutter package. The invoice is built as an in-memory `Uint8List` using `pw.Document` and `pw.MultiPage` (A4 format), then saved to the device via **`file_selector`** (native save dialog on desktop/web) or copied to clipboard as a fallback.

## 7. Project Structure

### 7.1 Directory Layout

```
Rental Cars/
├── backend/                        # Node.js REST API server
│   ├── models/
│   │   ├── User.js                 # User schema (name, email, phone, hashed password)
│   │   ├── Car.js                  # Vehicle schema (specs, pricing, availability)
│   │   └── Booking.js              # Booking schema (dates, slots, payment, spots)
│   ├── routes/
│   │   ├── auth.js                 # POST /api/auth/register, /api/auth/login
│   │   ├── cars.js                 # GET /api/cars (with availability filter)
│   │   ├── bookings.js             # POST /api/bookings
│   │   └── profile.js              # GET /api/profile/bookings
│   ├── middleware/
│   │   └── authMiddleware.js       # JWT verification for protected routes
│   ├── seed.js                     # Database seed script (sample vehicles)
│   ├── server.js                   # Express app entry point
│   └── .env                        # DB URI, JWT secret, port
│
├── frontend/                       # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart               # App entry point, MaterialApp, named routes
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── car_detail_screen.dart
│   │       ├── booking_screen.dart
│   │       ├── confirmation_screen.dart
│   │       ├── profile_screen.dart
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   ├── pubspec.yaml                # Flutter dependencies
│   └── ...                         # Platform-specific build configs
│
├── README.md                       # Project overview and setup guide
├── docs/case-study/screenshots/    # Frontend screenshots used in report
├── CASE_STUDY_REPORT.md            # Concise case study version
└── CASE_STUDY_REPORT_FORMAL.md     # This formal academic report
```

### 7.2 Layer Responsibilities

| Layer             | Location                | Responsibility                                |
| ----------------- | ----------------------- | --------------------------------------------- |
| Presentation      | `frontend/lib/screens/` | UI rendering and user interaction             |
| Application Logic | `frontend/lib/screens/` | Validation, price calculation, PDF generation |
| API Communication | `frontend/lib/screens/` | HTTP requests to the backend                  |
| Route Handling    | `backend/routes/`       | Request parsing and response formatting       |
| Business Logic    | `backend/routes/`       | Slot conflict detection, auth checks          |
| Data Access       | `backend/models/`       | Mongoose schemas and database queries         |
| Configuration     | `backend/.env`          | Secrets, DB URI, server port                  |

## 8. Testing and Validation Summary

### 8.1 Frontend Form Validation Testing

| Test Case                 | Input Scenario                        | Expected Behaviour              | Result  |
| ------------------------- | ------------------------------------- | ------------------------------- | ------- |
| Required fields — booking | Left all fields blank, tapped submit  | Inline errors shown per field   | ✅ Pass |
| Phone number format       | Entered non-numeric / too-short value | Field error: invalid phone      | ✅ Pass |
| Email format              | Entered malformed email string        | Field error: invalid email      | ✅ Pass |
| Date range consistency    | Set end date before start date        | Submission blocked, error shown | ✅ Pass |
| Time slot consistency     | Set end time before start on same day | Submission blocked              | ✅ Pass |
| UPI ID format             | Entered ID without `@` separator      | Validation error displayed      | ✅ Pass |
| Card number format        | Entered short / non-numeric card      | Validation error displayed      | ✅ Pass |

### 8.2 Backend API Testing

API endpoints were tested using `curl` commands against the locally running server:

| Endpoint                       | Test                                 | Expected                | Result  |
| ------------------------------ | ------------------------------------ | ----------------------- | ------- |
| `POST /api/auth/register`      | Register new user                    | JWT returned            | ✅ Pass |
| `POST /api/auth/login`         | Login with valid credentials         | JWT returned            | ✅ Pass |
| `POST /api/auth/login`         | Login with wrong password            | 401 error               | ✅ Pass |
| `GET /api/cars`                | Fetch all vehicles                   | Vehicle array returned  | ✅ Pass |
| `GET /api/cars?pickupDate=...` | Availability filter for booked slot  | `isAvailable: false`    | ✅ Pass |
| `GET /api/cars?pickupDate=...` | Availability filter for free slot    | `isAvailable: true`     | ✅ Pass |
| `POST /api/bookings`           | Create booking with valid JWT        | Booking record created  | ✅ Pass |
| `POST /api/bookings`           | Create overlapping slot booking      | Conflict error returned | ✅ Pass |
| `GET /api/profile/bookings`    | Fetch history with valid JWT         | Booking list returned   | ✅ Pass |
| Protected route — no token     | Request without Authorization header | 401 Unauthorized        | ✅ Pass |

### 8.3 Static Code Analysis

Flutter's built-in static analyzer was run after every code change:

```
cd frontend && flutter analyze
Analyzing frontend...
No issues found!
```

All linting rules satisfied. No deprecated API usages, unresolved imports, or type errors in the final codebase.

### 8.4 UI and Layout Testing

| Test                | Scenario                                  | Fix Applied                             | Result   |
| ------------------- | ----------------------------------------- | --------------------------------------- | -------- |
| RenderFlex overflow | Booking history buttons on narrow screen  | Replaced `Row` with `LayoutBuilder`     | ✅ Fixed |
| Button alignment    | Invoice buttons misaligned on mobile      | Full-width `Column` for compact screens | ✅ Fixed |
| GridView rendering  | Vehicle listing on small and wide screens | `childAspectRatio` tuned                | ✅ Pass  |
| Invoice dialog      | Preview dialog on small screen            | `SelectableText` in scrollable dialog   | ✅ Pass  |

## 9. Conclusion

The Car Rental Booking mobile application successfully demonstrates how a practical, end-to-end transportation service can be delivered through a Flutter-based mobile platform. Starting from a clearly identified problem — the friction and inefficiency in traditional car rental booking processes — the application was designed and implemented to address real user needs: real-time vehicle discovery, seamless booking, transparent pricing, and accessible booking history.

The project covers the full software development lifecycle: requirement analysis, system design, modular implementation, and validation testing. A three-tier architecture (Flutter frontend, Node.js/Express backend, MongoDB database) maintains a clear separation of concerns and supports scalability. Seven functional modules — Authentication, Vehicle Browsing, Booking, Availability, Payment, Profile & History, and Invoice — each handle a discrete responsibility and communicate through well-defined interfaces.

**Key technical achievements include:**

- Slot-based availability conflict detection preventing double bookings.
- Form validation across all user-facing input screens before API submission.
- Dynamic pricing and fare breakdown displayed before booking confirmation.
- JWT-based stateless authentication securing all protected routes.
- Client-side PDF invoice generation and cross-platform file export.
- Responsive layout adapting correctly to compact and wide screen formats.
- Static analysis verified a clean codebase with no linting issues.

In conclusion, the application fulfills all objectives stated in this case study and demonstrates that a well-structured Flutter mobile solution can effectively replace manual or fragmented rental workflows with a unified, transparent, and user-centric digital experience.

## 10. Future Scope

1. Online payment gateway integration.
2. Notification and reminder system.
3. Advanced analytics and admin dashboard.
4. Offline caching for weak network areas.
5. Automated test suite expansion.
