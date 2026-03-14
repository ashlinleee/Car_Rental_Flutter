# Car Rental Booking Flutter App

A Flutter mobile application for car rental booking with intuitive interface and comprehensive booking functionality.

## Features

- **Vehicle Listing with GridView**: Browse available cars in an organized grid layout
- **Advanced Form Validation**: Comprehensive validation for booking forms including name, email, and phone validation
- **Date Picker Integration**: Easy-to-use date pickers for selecting rental duration
- **Dynamic Price Calculation**: Real-time price calculation with taxes, fees, and category-based adjustments
- **Navigator Routes**: Smooth navigation between screens for better user experience
- **Responsive Design**: Clean, modern UI that works on different screen sizes

## Screens

1. **Home Screen**: Vehicle listing with search and filtering functionality
2. **Booking Screen**: Detailed booking form with validation and price calculation
3. **Confirmation Screen**: Booking confirmation with complete details

## Technical Features

### Form Validation

- **Name Validation**: Checks for minimum length and alphabetic characters only
- **Email Validation**: Validates proper email format using regex
- **Phone Validation**: Ensures valid phone number format
- **Date Validation**: Prevents invalid date selections

### Price Calculation Logic

- Base rental price calculation
- Insurance fees (per day)
- Service fees
- Tax calculation (10%)
- Category-based pricing adjustments:
  - Luxury cars: +15% premium
  - Sports cars: +10% premium
  - Electric cars: -5% discount (eco-friendly)
  - Economy cars: -10% discount

### Navigation Routes

- `/`: Home screen (vehicle listing)
- `/booking`: Booking form screen
- `/confirmation`: Booking confirmation screen

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── car.dart             # Car data model
│   └── booking.dart         # Booking data model
├── screens/
│   ├── home_screen.dart     # Vehicle listing screen
│   ├── booking_screen.dart  # Booking form screen
│   └── confirmation_screen.dart # Confirmation screen
├── widgets/
│   └── car_card.dart        # Car display card widget
└── services/
    └── price_calculator.dart # Price calculation logic
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter extensions
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**

   ```bash
   cd frontend
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Dependencies

- `flutter`: Flutter framework
- `cupertino_icons`: iOS style icons
- `intl`: Internationalization support for date formatting

## Features Implementation

### GridView Vehicle Listing

The home screen implements a responsive GridView that displays car cards with:

- Car images from network URLs
- Car details (name, brand, category, seats, transmission)
- Pricing information
- Availability status
- Rating display
- Search and filter functionality

### Form Validation

The booking screen includes comprehensive validation for:

- **Customer name**: Must be at least 2 characters, letters only
- **Email**: Valid email format validation
- **Phone**: International phone number format validation
- **Dates**: Start date must be today or future, end date must be after start date

### Date Picker Implementation

- Material Design date pickers
- Prevents selection of past dates
- Automatic validation of date ranges
- User-friendly date display formatting

### Price Calculation

Dynamic price calculation including:

- Daily rental rates based on selected dates
- Insurance fees per day
- Service fees
- Tax calculation
- Category-based adjustments
- Real-time price updates

## Sample Data

The app includes sample car data with various categories:

- Sedans (Toyota Camry)
- SUVs (Honda CR-V, Chevrolet Tahoe)
- Luxury cars (BMW 3 Series)
- Sports cars (Ford Mustang)
- Electric vehicles (Tesla Model 3)

## Future Enhancements

- Backend API integration
- User authentication
- Payment gateway integration
- Push notifications
- Booking history
- Car availability tracking
- Location-based services
- Multi-language support

## Development Notes

- Uses Material Design 3
- Implements proper state management
- Follows Flutter best practices
- Responsive design principles
- Error handling and validation
- Clean code architecture

## Testing

To run tests:

```bash
flutter test
```

## Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Add tests
5. Submit a pull request

## License

This project is for educational purposes as part of the ITM Skills University Case Study 31.
