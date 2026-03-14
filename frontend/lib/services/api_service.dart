// api_service.dart — HTTP client for all backend REST API calls.
//
// Communicates with the Node.js backend over HTTP using the `http` package.
// On network errors or non-200 responses the service falls back to local sample
// data (cars) or returns empty/null values so the UI degrades gracefully.
//
// Sections:
//   Cars     — getCars(), getCarById(), getCategories()
//   Bookings — createBooking(), getBookings(), cancelBooking()
//   Health   — isBackendAvailable()
//   Helpers  — _localCategories()

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/car.dart';
import '../models/booking.dart';
import 'auth_service.dart';

class ApiService {
  // Base URL:
  //   iOS simulator / macOS native → localhost works directly
  //   Android emulator             → replace with 10.0.2.2
  static const String _baseUrl = 'http://localhost:3000/api';

  // Global request timeout — prevents the UI from hanging indefinitely
  static const Duration _timeout = Duration(seconds: 10);

  // ─── Cars ─────────────────────────────────────────────────────────────────

  static Future<List<Car>> getCars({
    String? category,
    String? search,
    bool? available,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    String? pickupDate,   // 'YYYY-MM-DD'
    String? pickupTime,   // 'HH:MM'
    String? dropoffDate,  // 'YYYY-MM-DD'
    String? dropoffTime,  // 'HH:MM'
    String? state,
    String? place,
  }) async {
    try {
      // Build query string only from non-null/non-empty parameters
      final queryParams = <String, String>{};
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (available != null) queryParams['available'] = available.toString();
      if (sortBy != null) queryParams['sort'] = sortBy;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toStringAsFixed(0);
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toStringAsFixed(0);
      if (pickupDate != null)  queryParams['pickupDate']  = pickupDate;
      if (pickupTime != null)  queryParams['pickupTime']  = pickupTime;
      if (dropoffDate != null) queryParams['dropoffDate'] = dropoffDate;
      if (dropoffTime != null) queryParams['dropoffTime'] = dropoffTime;
      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (place != null && place.isNotEmpty) queryParams['place'] = place;

      final uri = Uri.parse('$_baseUrl/cars').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        return data.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList();
      }
      // Non-200 status — fall back to sample cars
      return Car.getSampleCars();
    } on SocketException {
      // No network connection
      return Car.getSampleCars();
    } on HttpException {
      return Car.getSampleCars();
    } catch (_) {
      return Car.getSampleCars();
    }
  }

  static Future<Car?> getCarById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/cars/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return Car.fromJson(json['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/categories'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        return List<String>.from(data);
      }
      return _localCategories();
    } catch (_) {
      return _localCategories();
    }
  }

  // ─── Bookings ─────────────────────────────────────────────────────────────

  static Future<ApiResult<Booking>> createBooking(Booking booking) async {
    try {
      // Attach JWT if logged in so the booking is linked to the user account
      final token = AuthService().token;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final response = await http
          .post(
            Uri.parse('$_baseUrl/bookings'),
            headers: headers,
            body: jsonEncode(booking.toJson()),
          )
          .timeout(_timeout);

      final Map<String, dynamic> json = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ApiResult.success(Booking.fromJson(json['data'] as Map<String, dynamic>));
      }
      // Surface user-facing error message from the API body
      final message = (json['message'] as String?) ??
          (json['error'] as String?) ??
          'Booking failed. Please try a different slot.';
      return ApiResult.failure(message);
    } on SocketException {
      return const ApiResult.failure('Cannot connect to server. Please try again.');
    } catch (_) {
      return const ApiResult.failure('Booking failed. Please try again.');
    }
  }

  static Future<List<Booking>> getBookings() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/bookings'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
        return data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> cancelBooking(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/bookings/$id'))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Health ───────────────────────────────────────────────────────────────

  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3000/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static List<String> _localCategories() {
    final Set<String> cats = {'All'};
    for (final car in Car.getSampleCars()) {
      cats.add(car.category);
    }
    return cats.toList();
  }
}

/// Generic API result wrapper that carries either a value or an error message.
class ApiResult<T> {
  final T? data;
  final String? error;
  bool get isSuccess => data != null && error == null;

  const ApiResult.success(T value) : data = value, error = null;
  const ApiResult.failure(String msg) : data = null, error = msg;
}