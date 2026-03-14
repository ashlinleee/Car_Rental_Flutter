// price_calculator.dart — Stateless helper for rental price calculations.
//
// Supports two pricing modes:
//   Day-based  — charges by full rental days (date diff + 1)
//   Hour-based — derives an hourly rate from pricePerDay (1 day = 24 hours)
//
// Both modes apply:
//   - Insurance fee  (₹500 / day  or  ₹500/24 per hour)
//   - Fixed service fee (₹750 flat)
//   - 10% tax on the subtotal
//   - Category multiplier: Luxury +15%, Sports +10%, Electric -5%, Economy -10%

import 'package:flutter/material.dart';
import '../models/car.dart';

class PriceCalculator {
  // Base tax rate (10%)
  static const double _taxRate = 0.10;

  // Insurance fee per day / per hour
  static const double _insurancePerDay = 500.0;
  static const double _hoursPerDay = 24.0; // 24-hour day

  // Service fee
  static const double _serviceFee = 750.0;

  // ─── Day-based pricing (legacy) ───────────────────────────────────────────

  /// Calculate total price including taxes and fees (day-based)
  static double calculateTotalPrice(Car car, DateTime startDate, DateTime endDate) {
    final int rentalDays = endDate.difference(startDate).inDays + 1;
    final double basePrice = car.pricePerDay * rentalDays;
    final double insuranceFee = _insurancePerDay * rentalDays;
    const double serviceFee = _serviceFee;
    final double subtotal = basePrice + insuranceFee + serviceFee;
    final double tax = subtotal * _taxRate;
    final double categoryMultiplier = _getCategoryMultiplier(car.category);
    final double total = (subtotal + tax) * categoryMultiplier;
    return double.parse(total.toStringAsFixed(2));
  }

  /// Calculate base rental cost without taxes and fees (day-based)
  static double calculateBasePrice(Car car, DateTime startDate, DateTime endDate) {
    final int rentalDays = endDate.difference(startDate).inDays + 1;
    return car.pricePerDay * rentalDays;
  }

  /// Calculate insurance fee (day-based)
  static double calculateInsuranceFee(DateTime startDate, DateTime endDate) {
    final int rentalDays = endDate.difference(startDate).inDays + 1;
    return _insurancePerDay * rentalDays;
  }

  // ─── Hour-based pricing ───────────────────────────────────────────────────

  // Combines a date-only DateTime with a TimeOfDay to get a full DateTime.
  /// Combine a date and a TimeOfDay into a DateTime
  static DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Calculate total rental hours between two date+time combos.
  /// Always at least 1 hour.
  static double calculateRentalHours(
    DateTime startDate, TimeOfDay startTime,
    DateTime endDate, TimeOfDay endTime,
  ) {
    final start = _combineDateAndTime(startDate, startTime);
    final end = _combineDateAndTime(endDate, endTime);
    final minutes = end.difference(start).inMinutes;
    return (minutes < 60 ? 60 : minutes) / 60.0;
  }

  /// Hourly rate derived from pricePerDay (1 day = 8 hours)
  static double hourlyRate(Car car) => car.pricePerDay / _hoursPerDay;

  /// Total price calculated by hours + taxes + fees
  static double calculateTotalPriceWithTime(
    Car car,
    DateTime startDate,
    TimeOfDay startTime,
    DateTime endDate,
    TimeOfDay endTime,
  ) {
    final double hours = calculateRentalHours(startDate, startTime, endDate, endTime);
    final double rate = hourlyRate(car);
    final double basePrice = rate * hours;
    final double insuranceFee = (_insurancePerDay / _hoursPerDay) * hours;
    const double serviceFee = _serviceFee;
    final double subtotal = basePrice + insuranceFee + serviceFee;
    final double tax = subtotal * _taxRate;
    final double categoryMultiplier = _getCategoryMultiplier(car.category);
    final double total = (subtotal + tax) * categoryMultiplier;
    return double.parse(total.toStringAsFixed(2));
  }

  /// Insurance fee for hour-based booking
  static double calculateInsuranceFeeByHours(double hours) {
    return (_insurancePerDay / _hoursPerDay) * hours;
  }

  /// Detailed breakdown for hour-based booking
  static Map<String, double> calculatePriceBreakdownWithTime(
    Car car,
    DateTime startDate,
    TimeOfDay startTime,
    DateTime endDate,
    TimeOfDay endTime,
  ) {
    final double hours = calculateRentalHours(startDate, startTime, endDate, endTime);
    final double rate = hourlyRate(car);
    final double basePrice = rate * hours;
    final double insuranceFee = (_insurancePerDay / _hoursPerDay) * hours;
    const double serviceFee = _serviceFee;
    final double subtotal = basePrice + insuranceFee + serviceFee;
    final double tax = subtotal * _taxRate;
    final double categoryMultiplier = _getCategoryMultiplier(car.category);
    final double total = (subtotal + tax) * categoryMultiplier;
    return {
      'hours': hours,
      'hourlyRate': double.parse(rate.toStringAsFixed(2)),
      'basePrice': double.parse(basePrice.toStringAsFixed(2)),
      'insuranceFee': double.parse(insuranceFee.toStringAsFixed(2)),
      'serviceFee': serviceFee,
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'tax': double.parse(tax.toStringAsFixed(2)),
      'categoryMultiplier': categoryMultiplier,
      'total': double.parse(total.toStringAsFixed(2)),
    };
  }

  /// Calculate tax amount
  static double calculateTax(double subtotal) {
    return subtotal * _taxRate;
  }

  /// Get category-based pricing multiplier
  static double _getCategoryMultiplier(String category) {
    switch (category.toLowerCase()) {
      case 'luxury':
        return 1.15; // 15% premium
      case 'sports':
        return 1.10; // 10% premium
      case 'electric':
        return 0.95; // 5% discount for eco-friendly
      case 'economy':
        return 0.90; // 10% discount
      default:
        return 1.0; // No adjustment
    }
  }

  /// Calculate price breakdown
  static Map<String, double> calculatePriceBreakdown(Car car, DateTime startDate, DateTime endDate) {
    final int rentalDays = endDate.difference(startDate).inDays + 1;
    final double basePrice = calculateBasePrice(car, startDate, endDate);
    final double insuranceFee = calculateInsuranceFee(startDate, endDate);
    const double serviceFee = _serviceFee;
    final double subtotal = basePrice + insuranceFee + serviceFee;
    final double tax = calculateTax(subtotal);
    final double categoryMultiplier = _getCategoryMultiplier(car.category);
    final double total = (subtotal + tax) * categoryMultiplier;

    return {
      'rentalDays': rentalDays.toDouble(),
      'basePrice': double.parse(basePrice.toStringAsFixed(2)),
      'insuranceFee': double.parse(insuranceFee.toStringAsFixed(2)),
      'serviceFee': double.parse(serviceFee.toStringAsFixed(2)),
      'subtotal': double.parse(subtotal.toStringAsFixed(2)),
      'tax': double.parse(tax.toStringAsFixed(2)),
      'categoryMultiplier': categoryMultiplier,
      'total': double.parse(total.toStringAsFixed(2)),
    };
  }

  /// Apply discount coupon
  static double applyCoupon(double originalPrice, String couponCode) {
    switch (couponCode.toUpperCase()) {
      case 'FIRST10':
        return originalPrice * 0.9; // 10% discount
      case 'WEEKEND15':
        return originalPrice * 0.85; // 15% discount
      case 'STUDENT20':
        return originalPrice * 0.8; // 20% discount
      default:
        return originalPrice; // Invalid coupon
    }
  }

  /// Check if dates qualify for weekend pricing
  static bool isWeekendRental(DateTime startDate, DateTime endDate) {
    return startDate.weekday >= DateTime.saturday || endDate.weekday >= DateTime.saturday;
  }

  /// Calculate long-term rental discount
  static double calculateLongTermDiscount(int rentalDays) {
    if (rentalDays >= 30) {
      return 0.20; // 20% discount for 30+ days
    } else if (rentalDays >= 14) {
      return 0.15; // 15% discount for 14+ days
    } else if (rentalDays >= 7) {
      return 0.10; // 10% discount for 7+ days
    }
    return 0.0; // No discount
  }
}