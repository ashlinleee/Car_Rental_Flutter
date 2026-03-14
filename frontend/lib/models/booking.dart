// booking.dart — Immutable data model representing a single car rental booking.
//
// Handles JSON serialisation/deserialisation for API communication and carries
// all booking details: customer info, car reference, rental period (date + time),
// total price, payment method, status, and optional pickup/dropoff spots.

class Booking {
  final String id;
  final String carId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime; // "HH:mm" format, e.g. "09:00"
  final String endTime;   // "HH:mm" format, e.g. "17:00"
  final double totalPrice;
  final String status;
  final String? paymentMethodType;
  final String? paymentMethodLabel;
  final String? pickupSpot;
  final String? dropoffSpot;

  // All required fields must be supplied; optional fields default to sensible values.
  Booking({
    required this.id,
    required this.carId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.startDate,
    required this.endDate,
    this.startTime = '09:00',
    this.endTime = '09:00',
    required this.totalPrice,
    this.status = 'Confirmed',
    this.paymentMethodType,
    this.paymentMethodLabel,
    this.pickupSpot,
    this.dropoffSpot,
  });

  int get rentalDays {
    // +1 so a same-day rental counts as 1 day (inclusive end date)
    return endDate.difference(startDate).inDays + 1;
  }

  // Serialises a DateTime to "YYYY-MM-DD" string, stripping time/timezone info.
  // This prevents UTC-offset shifts from changing the calendar date in the API payload.
  static String _toDateOnly(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  // Parses a date received from the API into a time-free DateTime.
  // Accepts full ISO strings (takes only the first 10 chars) or plain "YYYY-MM-DD".
  // Falls back to DateTime.now() if the value cannot be parsed.
  static DateTime _parseDateOnly(dynamic raw) {
    if (raw == null) return DateTime.now();
    final s = raw.toString();
    final datePart = s.length >= 10 ? s.substring(0, 10) : s;
    final parts = datePart.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }
    final parsed = DateTime.tryParse(s);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    return DateTime.now();
  }

  // Returns a copy of this Booking with specified fields replaced.
  // Unspecified fields retain their current values (null-coalescing pattern).
  Booking copyWith({
    String? id,
    String? carId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    double? totalPrice,
    String? status,
    String? paymentMethodType,
    String? paymentMethodLabel,
    String? pickupSpot,
    String? dropoffSpot,
  }) {
    return Booking(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      paymentMethodLabel: paymentMethodLabel ?? this.paymentMethodLabel,
      pickupSpot: pickupSpot ?? this.pickupSpot,
      dropoffSpot: dropoffSpot ?? this.dropoffSpot,
    );
  }

  // Serialises to a Map for HTTP POST/PUT bodies.
  // Nullable optional fields are omitted when null/empty to keep the payload minimal.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carId': carId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'startDate': _toDateOnly(startDate),
      'endDate': _toDateOnly(endDate),
      'startTime': startTime,
      'endTime': endTime,
      'totalPrice': totalPrice,
      'status': status,
      if (paymentMethodType != null) 'paymentMethodType': paymentMethodType,
      if (paymentMethodLabel != null) 'paymentMethodLabel': paymentMethodLabel,
      if (pickupSpot != null && pickupSpot!.isNotEmpty) 'pickupSpot': pickupSpot,
      if (dropoffSpot != null && dropoffSpot!.isNotEmpty) 'dropoffSpot': dropoffSpot,
    };
  }

  // Deserialises from a JSON map returned by the API.
  // Handles both integer and double totalPrice via (num).toDouble().
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      carId: json['carId'],
      customerName: json['customerName'],
      customerEmail: json['customerEmail'],
      customerPhone: json['customerPhone'],
      startDate: _parseDateOnly(json['startDate']),
      endDate: _parseDateOnly(json['endDate']),
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '09:00',
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'] ?? 'Confirmed',
      paymentMethodType: json['paymentMethodType'],
      paymentMethodLabel: json['paymentMethodLabel'],
      pickupSpot: (json['pickupSpot'] as String?)?.trim(),
      dropoffSpot: (json['dropoffSpot'] as String?)?.trim(),
    );
  }
}