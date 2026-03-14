// user.dart — Data models for authenticated user accounts and saved payment methods.
//
// PaymentMethod  — a single saved card or UPI entry (type, display label, masked token).
// User           — full customer profile: contact info + list of PaymentMethods.
//
// Both classes are immutable and support JSON serialisation, deserialisation,
// and copyWith for producing modified copies without mutation.

// Represents a single saved payment method (card or UPI).
// 'token' is a masked identifier only — raw card numbers are never stored client-side.
class PaymentMethod {
  final String type;
  final String label;
  final String token;

  PaymentMethod({required this.type, required this.label, required this.token});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        type: json['type'] ?? '',
        label: json['label'] ?? '',
        token: json['token'] ?? '',
      );

  Map<String, dynamic> toJson() => {'type': type, 'label': label, 'token': token};
}

// Represents a registered user's profile returned after login/register.
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<PaymentMethod> savedPaymentMethods;

  User({
  // Returns a modified copy of this User, keeping unchanged fields intact.
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.savedPaymentMethods = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        savedPaymentMethods: (json['savedPaymentMethods'] as List<dynamic>? ?? [])
            .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'savedPaymentMethods': savedPaymentMethods.map((e) => e.toJson()).toList(),
      };

  User copyWith({String? name, String? phone, List<PaymentMethod>? savedPaymentMethods}) => User(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        savedPaymentMethods: savedPaymentMethods ?? this.savedPaymentMethods,
      );
}
