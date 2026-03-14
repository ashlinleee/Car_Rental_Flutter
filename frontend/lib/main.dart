// main.dart — Application entry point for the Car Rental (Brumm) Flutter app.
//
// Bootstraps the app by:
//   1. Calling WidgetsFlutterBinding.ensureInitialized() so async work can run
//      before the widget tree is built.
//   2. Restoring any persisted login session via AuthService.init().
//   3. Launching CarRentalApp, which owns the route table for all screens.

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/car_details_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/confirmation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Required before any async operation in main()
  WidgetsFlutterBinding.ensureInitialized();
  // Restore JWT + user profile from SharedPreferences (if a previous session exists)
  await AuthService().init();
  runApp(const CarRentalApp());
}

// Root widget — configures the app theme and declares the named route table.
class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brumm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      initialRoute: '/',
      // Named routes — each screen is registered here for Navigator.pushNamed() calls
      routes: {
        '/': (context) => const HomeScreen(),
        '/car_details': (context) => const CarDetailsScreen(),
        '/booking': (context) => const BookingScreen(),
        '/confirmation': (context) => const ConfirmationScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}