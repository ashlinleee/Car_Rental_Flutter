// auth_service.dart — Singleton service managing user authentication state.
//
// Persists the JWT token and serialised User profile in SharedPreferences so
// that login sessions survive app restarts without requiring re-authentication.
//
// Public API:
//   init()               — Restore persisted session on app startup
//   register(...)        — Create account and auto-login
//   login(...)           — Authenticate with email/password
//   logout()             — Clear token and user from memory and storage
//   updateProfile(...)   — Update name / phone on the backend
//   changePassword(...)  — Change password (requires current password)
//   getBookingHistory()  — Fetch past bookings for the logged-in user
//   addPaymentMethod()   — Save a new card/UPI token to the profile
//   removePaymentMethod()— Delete a saved payment method by index

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // In-memory state; mirrored to SharedPreferences for persistence
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  String _extractMessage(Map<String, dynamic> data, String fallback) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    final error = data['error'];
    if (error is String && error.isNotEmpty) return error;
    return fallback;
  }

  List<PaymentMethod> _parsePaymentMethods(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(PaymentMethod.fromJson)
        .toList();
  }

  // Restores a previously saved session from SharedPreferences on app start.
  // Called once in main() before runApp().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }
  }

  // Persists both the JWT and the user profile after a successful login/register.
  Future<void> _saveAuth(String token, User user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Clears all auth state from memory and persistent storage (logout).
  Future<void> clearAuth() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Builds the Authorization header map; used for all protected endpoint calls.
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Register a new user. Returns error message or null on success.
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        final user = User.fromJson(data['data']);
        await _saveAuth(data['token'], user);
        return null;
      }
      return _extractMessage(data, 'Registration failed');
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Login. Returns error message or null on success.
  Future<String?> login({required String email, required String password}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final user = User.fromJson(data['data']);
        await _saveAuth(data['token'], user);
        return null;
      }
      return _extractMessage(data, 'Login failed');
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<void> logout() => clearAuth();

  /// Update name/phone. Returns error message or null on success.
  Future<String?> updateProfile({String? name, String? phone}) async {
    if (_token == null) return 'Not logged in';
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/profile'),
        headers: _authHeaders,
        body: jsonEncode({if (name != null) 'name': name, if (phone != null) 'phone': phone}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _currentUser = User.fromJson(data['data']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        return null;
      }
      return _extractMessage(data, 'Update failed');
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Change password. Returns error message or null on success.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) return 'Not logged in';
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/profile/password'),
        headers: _authHeaders,
        body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return null;
      return _extractMessage(data, 'Password change failed');
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Fetch booking history for logged-in user.
  Future<List<dynamic>?> getBookingHistory() async {
    if (_token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/profile/bookings'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] as List<dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Add a payment method.
  Future<String?> addPaymentMethod({
    required String type,
    required String label,
    required String token,
  }) async {
    if (_token == null) return 'Not logged in';
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/profile/payment-methods'),
        headers: _authHeaders,
        body: jsonEncode({'type': type, 'label': label, 'token': token}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final paymentMethods = _parsePaymentMethods(data['data']);
        _currentUser = (_currentUser ??
                User(id: '', name: '', email: '', phone: '', savedPaymentMethods: const []))
            .copyWith(savedPaymentMethods: paymentMethods);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        return null;
      }
      return _extractMessage(data, 'Failed to add payment method');
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Remove payment method at index.
  Future<String?> removePaymentMethod(int index) async {
    if (_token == null) return 'Not logged in';
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/profile/payment-methods/$index'),
        headers: _authHeaders,
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final paymentMethods = _parsePaymentMethods(data['data']);
        _currentUser = (_currentUser ??
                User(id: '', name: '', email: '', phone: '', savedPaymentMethods: const []))
            .copyWith(savedPaymentMethods: paymentMethods);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
        return null;
      }
      return _extractMessage(data, 'Failed to remove payment method');
    } catch (e) {
      return 'Network error: $e';
    }
  }
}
