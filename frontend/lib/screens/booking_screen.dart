// booking_screen.dart — End-to-end booking workflow.
//
// Handles:
//   - Rental period and customer form validation
//   - Logged-in and guest payment flows (UPI/card)
//   - Fare calculation (base + add-ons + coupon discounts)
//   - Booking submission to backend and navigation to confirmation screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';
import '../models/booking.dart';
import '../services/price_calculator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/car_image.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestPaymentDetailController = TextEditingController();
  final _couponController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Car? _selectedCar;
  double _totalPrice = 0.0;
  double _baseTotalPrice = 0.0;
  int _selectedKmPlan = 0; // 0=870km, 1=1450km, 2=Unlimited
  static const List<double> _kmMultipliers = [1.0, 1.18, 1.42];
  bool _isLoading = false;
  String _guestPaymentType = 'upi';
  int? _selectedSavedPaymentIndex;
  String _selectedState = '';
  String _selectedPlace = '';
  String _pickupSpot = '';
  String _dropoffSpot = '';
  double _deliveryCharge = 0;
  double _pickupCharge = 0;
  double _couponDiscount = 0;
  String? _appliedCouponCode;

  static const List<_CouponOffer> _couponOffers = [
    _CouponOffer(
      code: 'BRUMM150',
      title: 'Flat ₹150 Off',
      subtitle: 'Valid on bookings above ₹1,200',
      discountAmount: 150,
      minSubtotal: 1200,
      isEnabled: true,
    ),
    _CouponOffer(
      code: 'SAVE300',
      title: 'Flat ₹300 Off',
      subtitle: 'Valid on bookings above ₹2,500',
      discountAmount: 300,
      minSubtotal: 2500,
      isEnabled: true,
    ),
    _CouponOffer(
      code: 'WEEKEND500',
      title: 'Weekend Saver ₹500',
      subtitle: 'Valid on bookings above ₹4,000',
      discountAmount: 500,
      minSubtotal: 4000,
      isEnabled: true,
    ),
    _CouponOffer(
      code: 'MEGA999',
      title: 'Mega Offer ₹999',
      subtitle: 'Temporarily paused',
      discountAmount: 999,
      minSubtotal: 6000,
      isEnabled: false,
      lockReason: 'Offer paused for this week',
    ),
    _CouponOffer(
      code: 'NEWUSER',
      title: 'New User ₹250',
      subtitle: 'Invite-only offer',
      discountAmount: 250,
      minSubtotal: 1000,
      isEnabled: false,
      lockReason: 'Invite required to unlock',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCar == null) {
      // One-time argument hydration from route payload.
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Car) {
        _selectedCar = args;
      } else if (args is Map<String, dynamic>) {
        _selectedCar = args['car'] as Car?;

        _selectedState = (args['selectedState'] as String? ?? '').trim();
        _selectedPlace = (args['selectedPlace'] as String? ?? '').trim();
        _pickupSpot = (args['pickupSpot'] as String? ?? '').trim();
        _dropoffSpot = (args['dropoffSpot'] as String? ?? '').trim();

        final prePickupDate = args['pickupDate'] as DateTime?;
        final prePickupTime = args['pickupTime'] as TimeOfDay?;
        final preDropoffDate = args['dropoffDate'] as DateTime?;
        final preDropoffTime = args['dropoffTime'] as TimeOfDay?;

        if (prePickupDate != null &&
            prePickupTime != null &&
            preDropoffDate != null &&
            preDropoffTime != null) {
          _startDate = prePickupDate;
          _startTime = prePickupTime;
          _endDate = preDropoffDate;
          _endTime = preDropoffTime;
        }
      }

      // Pre-fill logged-in user's details to reduce friction at checkout.
      final user = AuthService().currentUser;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
        if (user.savedPaymentMethods.isNotEmpty) {
          _selectedSavedPaymentIndex ??= 0;
        }
      }

      _calculatePrice();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _guestPaymentDetailController.dispose();
    _couponController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  bool get _isLoggedIn => AuthService().isLoggedIn;

  String? _resolvePaymentType() {
    final user = AuthService().currentUser;
    if (_isLoggedIn && user != null && user.savedPaymentMethods.isNotEmpty) {
      final idx = _selectedSavedPaymentIndex;
      if (idx == null || idx < 0 || idx >= user.savedPaymentMethods.length) return null;
      return user.savedPaymentMethods[idx].type;
    }
    return _guestPaymentType;
  }

  String? _resolvePaymentLabel() {
    final user = AuthService().currentUser;
    if (_isLoggedIn && user != null && user.savedPaymentMethods.isNotEmpty) {
      final idx = _selectedSavedPaymentIndex;
      if (idx == null || idx < 0 || idx >= user.savedPaymentMethods.length) return null;
      return user.savedPaymentMethods[idx].label;
    }
    if (_guestPaymentType == 'upi') {
      final detail = _guestPaymentDetailController.text.trim();
      return detail.isEmpty ? null : detail;
    }
    final brand = _detectCardBrand(_cardNumberController.text);
    final digits = _digitsOnly(_cardNumberController.text);
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '$brand ••$last4';
  }

  String? _validatePaymentSelection() {
    final user = AuthService().currentUser;
    if (_isLoggedIn && user != null && user.savedPaymentMethods.isNotEmpty) {
      if (_selectedSavedPaymentIndex == null) {
        return 'Please select a saved payment method.';
      }
      return null;
    }
    if (_guestPaymentType == 'upi') {
      if (_guestPaymentDetailController.text.trim().isEmpty) {
        return 'Please enter your UPI ID.';
      }
      return null;
    }

    final numberError = _validateCardNumber(_cardNumberController.text);
    if (numberError != null) return numberError;
    final holderError = _validateCardHolder(_cardHolderController.text);
    if (holderError != null) return holderError;
    final expiryError = _validateCardExpiry(_cardExpiryController.text);
    if (expiryError != null) return expiryError;
    final cvvError = _validateCardCvv(_cardCvvController.text);
    if (cvvError != null) return cvvError;

    return null;
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _detectCardBrand(String input) {
    final digits = _digitsOnly(input);
    if (digits.isEmpty) return 'Card';
    if (RegExp(r'^4').hasMatch(digits)) return 'Visa';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(digits)) return 'Mastercard';
    if (RegExp(r'^(34|37)').hasMatch(digits)) return 'Amex';
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) return 'Discover';
    if (RegExp(r'^(300|301|302|303|304|305|36|38)').hasMatch(digits)) return 'Diners';
    if (RegExp(r'^(35)').hasMatch(digits)) return 'JCB';
    if (RegExp(r'^(60|6521|6522)').hasMatch(digits)) return 'RuPay';
    return 'Card';
  }

  String? _validateCardNumber(String? value) {
    final digits = _digitsOnly(value ?? '');
    if (digits.isEmpty) return 'Please enter card number.';
    final isAmex = RegExp(r'^(34|37)').hasMatch(digits);
    final expectedLength = isAmex ? 15 : 16;
    if (digits.length != expectedLength) {
      return 'Please enter a valid ${isAmex ? '15' : '16'}-digit card number.';
    }
    return null;
  }

  String? _validateCardHolder(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter card holder name.';
    if (v.length < 2) return 'Card holder name is too short.';
    return null;
  }

  String? _validateCardExpiry(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(v)) {
      return 'Use expiry format MM/YY.';
    }
    final parts = v.split('/');
    final month = int.tryParse(parts[0]);
    final year2 = int.tryParse(parts[1]);
    if (month == null || year2 == null) return 'Invalid expiry date.';
    final year = 2000 + year2;
    final now = DateTime.now();
    final expiry = DateTime(year, month + 1, 0, 23, 59, 59);
    if (expiry.isBefore(now)) return 'Card has expired.';
    return null;
  }

  String? _validateCardCvv(String? value) {
    final v = _digitsOnly(value ?? '');
    if (v.isEmpty) return 'Please enter CVV.';
    if (v.length < 3 || v.length > 4) return 'CVV must be 3 or 4 digits.';
    return null;
  }

  void _calculateConvenienceCharges() {
    _deliveryCharge = _pickupSpot.isNotEmpty ? 149 : 0;
    _pickupCharge = _dropoffSpot.isNotEmpty ? 149 : 0;
  }

  double get _fareBeforeDiscount => _totalPrice + _deliveryCharge + _pickupCharge;

  double get _effectiveFare =>
      (_fareBeforeDiscount - _couponDiscount).clamp(0.0, 9999999.0).toDouble();

  void _syncAppliedCoupon() {
    final code = _appliedCouponCode;
    if (code == null) return;
    final offer = _findOfferByCode(code);
    if (offer == null || !_isCouponUnlocked(offer)) {
      _appliedCouponCode = null;
      _couponDiscount = 0;
      return;
    }
    _couponDiscount = offer.discountAmount > _fareBeforeDiscount
        ? _fareBeforeDiscount
        : offer.discountAmount;
  }

  bool _isCouponUnlocked(_CouponOffer offer) {
    return offer.isEnabled && _fareBeforeDiscount >= offer.minSubtotal;
  }

  _CouponOffer? _findOfferByCode(String code) {
    for (final offer in _couponOffers) {
      if (offer.code == code) return offer;
    }
    return null;
  }

  String _couponLockReason(_CouponOffer offer) {
    if (!offer.isEnabled) return offer.lockReason ?? 'Not available right now';
    return 'Unlock at subtotal ₹${offer.minSubtotal.round()}';
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showSnack('Enter a coupon code first.', isError: true);
      return;
    }
    final offer = _findOfferByCode(code);
    if (offer == null) {
      _showSnack('Invalid coupon code.', isError: true);
      return;
    }
    if (!_isCouponUnlocked(offer)) {
      _showSnack(_couponLockReason(offer), isError: true);
      return;
    }
    setState(() {
      _appliedCouponCode = offer.code;
      _couponDiscount =
          offer.discountAmount > _fareBeforeDiscount ? _fareBeforeDiscount : offer.discountAmount;
    });
    _showSnack('${offer.code} applied successfully');
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponDiscount = 0;
      _couponController.clear();
    });
  }

  Widget _buildAmountRow(String label, double amount, {Color? color, bool isNegative = false}) {
    final signedAmount = isNegative ? '-₹${amount.round()}' : '₹${amount.round()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Text(
            signedAmount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPaymentMethodDialog() async {
    final upiCtrl = TextEditingController();
    final addCardNumberCtrl = TextEditingController();
    final addCardHolderCtrl = TextEditingController();
    final addCardExpiryCtrl = TextEditingController();
    final addCardCvvCtrl = TextEditingController();
    String type = 'upi';

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                ],
                onChanged: (v) => setDialogState(() => type = v ?? 'upi'),
              ),
              const SizedBox(height: 12),
              if (type == 'upi')
                TextField(
                  controller: upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: addCardNumberCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        border: const OutlineInputBorder(),
                        helperText: _detectCardBrand(addCardNumberCtrl.text),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addCardHolderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Card Holder Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCardExpiryCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryDateTextFormatter(),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Expiry (MM/YY)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: addCardCvvCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                String label;
                if (type == 'upi') {
                  final upi = upiCtrl.text.trim();
                  if (upi.isEmpty) return;
                  label = upi;
                } else {
                  final numberError = _validateCardNumber(addCardNumberCtrl.text);
                  if (numberError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(numberError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final holderError = _validateCardHolder(addCardHolderCtrl.text);
                  if (holderError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(holderError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final expiryError = _validateCardExpiry(addCardExpiryCtrl.text);
                  if (expiryError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(expiryError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final cvvError = _validateCardCvv(addCardCvvCtrl.text);
                  if (cvvError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(cvvError), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final digits = _digitsOnly(addCardNumberCtrl.text);
                  final last4 = digits.substring(digits.length - 4);
                  final brand = _detectCardBrand(digits);
                  label = '$brand ••$last4';
                }

                final err = await AuthService().addPaymentMethod(
                  type: type,
                  label: label,
                  token: 'tok_${DateTime.now().millisecondsSinceEpoch}',
                );
                if (!mounted || !ctx.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                  );
                  Navigator.of(ctx).pop(false);
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    upiCtrl.dispose();
    addCardNumberCtrl.dispose();
    addCardHolderCtrl.dispose();
    addCardExpiryCtrl.dispose();
    addCardCvvCtrl.dispose();

    if (added == true && mounted) {
      final methods = AuthService().currentUser?.savedPaymentMethods ?? [];
      setState(() {
        if (methods.isNotEmpty) {
          _selectedSavedPaymentIndex = methods.length - 1;
        }
      });
      _showSnack('Payment method added successfully');
    }
  }

  void _calculatePrice() {
    if (_selectedCar != null && _startDate != null && _endDate != null &&
        _startTime != null && _endTime != null) {
      setState(() {
        _baseTotalPrice = PriceCalculator.calculateTotalPriceWithTime(
          _selectedCar!,
          _startDate!,
          _startTime!,
          _endDate!,
          _endTime!,
        );
        _totalPrice = _baseTotalPrice * _kmMultipliers[_selectedKmPlan];
        _calculateConvenienceCharges();
        _syncAppliedCoupon();
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => _datepickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
          _endTime = null;
          _totalPrice = 0;
        } else {
          _calculatePrice();
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      _showSnack('Please select a start date first', isError: true);
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 30)),
      builder: (context, child) => _datepickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculatePrice();
      });
    }
  }

  Future<void> _selectStartTime() async {
    if (_startDate == null) {
      _showSnack('Please select a start date first', isError: true);
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => _timepickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _calculatePrice();
      });
    }
  }

  Future<void> _selectEndTime() async {
    if (_endDate == null) {
      _showSnack('Please select an end date first', isError: true);
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
      builder: (context, child) => _timepickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _calculatePrice();
      });
    }
  }

  Widget _datepickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A2E),
        ),
      ),
      child: child!,
    );
  }

  Widget _timepickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          onPrimary: Colors.white,
          onSurface: Color(0xFF1A1A2E),
        ),
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      child: child!,
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name should only contain letters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  String _timeOfDayToString(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnack('Please select your rental dates', isError: true);
      return;
    }
    if (_startTime == null || _endTime == null) {
      _showSnack('Please select start and end times', isError: true);
      return;
    }
    final startDT = _combineDateAndTime(_startDate!, _startTime!);
    final endDT = _combineDateAndTime(_endDate!, _endTime!);
    if (!endDT.isAfter(startDT)) {
      _showSnack('End date/time must be after start date/time', isError: true);
      return;
    }
    final paymentError = _validatePaymentSelection();
    if (paymentError != null) {
      _showSnack(paymentError, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final draft = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      carId: _selectedCar!.id,
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      startTime: _timeOfDayToString(_startTime!),
      endTime: _timeOfDayToString(_endTime!),
      totalPrice: _effectiveFare,
      paymentMethodType: _resolvePaymentType(),
      paymentMethodLabel: _resolvePaymentLabel(),
      pickupSpot: _pickupSpot.isEmpty ? null : _pickupSpot,
      dropoffSpot: _dropoffSpot.isEmpty ? null : _dropoffSpot,
    );

    final result = await ApiService.createBooking(draft);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(
        context,
        '/confirmation',
        arguments: {
          'booking': result.data!,
          'car': _selectedCar,
        },
      );
    } else {
      _showSnack(result.error ?? 'Booking failed. Please try again.', isError: true);
    }
  }

  double get _rentalHours {
    if (_startDate == null || _endDate == null || _startTime == null || _endTime == null) {
      return 0;
    }
    return PriceCalculator.calculateRentalHours(_startDate!, _startTime!, _endDate!, _endTime!);
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCar == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final car = _selectedCar!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Book Your Car'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selected Car Banner ──────────────────────────
              _buildCarBanner(car),
              const SizedBox(height: 20),

              // ── Customer Information ─────────────────────────
              _sectionHeader('Customer Information', Icons.person_outline),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.name,
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),

              const SizedBox(height: 24),

              // ── Rental Period ────────────────────────────────
              _sectionHeader('Rental Period', Icons.date_range_outlined),
              const SizedBox(height: 12),
              if (_pickupSpot.isNotEmpty || _dropoffSpot.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.teal[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              [_selectedPlace, _selectedState].where((e) => e.isNotEmpty).join(', '),
                              style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                      if (_pickupSpot.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Pickup spot: $_pickupSpot', style: TextStyle(color: Colors.teal[800], fontSize: 12.5)),
                      ],
                      if (_dropoffSpot.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Drop spot: $_dropoffSpot', style: TextStyle(color: Colors.teal[800], fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(child: _buildDateTile(
                    label: 'Start Date',
                    icon: Icons.calendar_today_outlined,
                    date: _startDate,
                    onTap: _selectStartDate,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateTile(
                    label: 'End Date',
                    icon: Icons.event_outlined,
                    date: _endDate,
                    onTap: _selectEndDate,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTimeTile(
                    label: 'Start Time',
                    icon: Icons.schedule_outlined,
                    time: _startTime,
                    onTap: _selectStartTime,
                    placeholder: _startDate == null ? 'Pick date first' : 'Tap to select',
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTimeTile(
                    label: 'End Time',
                    icon: Icons.access_time_filled_outlined,
                    time: _endTime,
                    onTap: _selectEndTime,
                    placeholder: _endDate == null ? 'Pick date first' : 'Tap to select',
                  )),
                ],
              ),

              if (_rentalHours > 0) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _rentalHours < 24
                          ? '${_rentalHours.toStringAsFixed(1)} hour${_rentalHours != 1 ? 's' : ''} rental'
                          : '${(_rentalHours / 24).toStringAsFixed(1)} day${_rentalHours / 24 != 1 ? 's' : ''} rental (${_rentalHours.toStringAsFixed(0)} hrs)',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Km Plan ──────────────────────────────────────
              if (_baseTotalPrice > 0) ...[
                _sectionHeader('Km Plan', Icons.speed_outlined),
                const SizedBox(height: 12),
                _buildKmPlanSelector(),
                const SizedBox(height: 24),
              ],

              // ── Price Breakdown ──────────────────────────────
              if (_totalPrice > 0) ...[
                _sectionHeader('Fare Breakdown', Icons.receipt_long_outlined),
                const SizedBox(height: 12),
                _buildPriceCard(car),
                const SizedBox(height: 24),

                _sectionHeader('Apply Coupon', Icons.local_offer_outlined),
                const SizedBox(height: 12),
                _buildCouponSection(),
                const SizedBox(height: 24),
              ],

              _sectionHeader('Payment Method', Icons.payment_outlined),
              const SizedBox(height: 12),
              _buildPaymentSection(),

              const SizedBox(height: 24),

              // ── Book Now Button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline),
                            SizedBox(width: 10),
                            Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarBanner(Car car) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CarImage(
            imageUrl: car.imageUrl,
            width: 110,
            height: 90,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            iconSize: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.brand} · ${car.category}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('${car.seats} seats',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const SizedBox(width: 12),
                      Icon(Icons.settings_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(car.transmission,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '₹${car.pricePerDay.round()}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: '/day',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(₹${PriceCalculator.hourlyRate(car).round()}/hr)',
                        style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? const Color(0xFF2E7D32) : Colors.grey[200]!,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: hasDate ? const Color(0xFF2E7D32) : Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasDate ? const Color(0xFF2E7D32) : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasDate
                  ? DateFormat('MMM dd, yyyy').format(date)
                  : 'Tap to select',
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasDate ? FontWeight.bold : FontWeight.normal,
                color: hasDate ? const Color(0xFF1A1A2E) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required IconData icon,
    required TimeOfDay? time,
    required VoidCallback onTap,
    String placeholder = 'Tap to select',
  }) {
    final hasTime = time != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasTime ? Colors.orange[400]! : Colors.grey[200]!,
            width: hasTime ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: hasTime ? Colors.orange[600] : Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: hasTime ? Colors.orange[700] : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasTime ? time.format(context) : placeholder,
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasTime ? FontWeight.bold : FontWeight.normal,
                color: hasTime ? const Color(0xFF1A1A2E) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(Car car) {
    const securityDeposit = 5000.0;
    final totalPayable = _effectiveFare + securityDeposit;
    final days = (_startDate != null && _endDate != null)
        ? _endDate!.difference(_startDate!).inDays + 1
        : 1;
    const kmsPerDay = 200;
    final totalKms = kmsPerDay * days;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section title ──────────────────────────────
            const Text(
              'Fare Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),

            // ── 1. Base fare (with ⓘ) ──────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Base fare',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showBaseFareInfo(context),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${_totalPrice.round()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Doorstep delivery & pickup ──────────────
            _buildAmountRow('Doorstep delivery charge', _deliveryCharge),
            _buildAmountRow('Doorstep pickup charge', _pickupCharge),

            // ── 3. Insurance & GST ─────────────────────────
            _tagFareRow(
              'Insurance & GST',
              'Included',
              const Color(0xFF2E7D32),
              Colors.green.shade50,
            ),

            if (_couponDiscount > 0)
              _buildAmountRow(
                'Coupon (${_appliedCouponCode ?? ''})',
                _couponDiscount,
                isNegative: true,
                color: const Color(0xFF2E7D32),
              ),

            // ── 4. Refundable security deposit ─────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Security deposit',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Refundable',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${securityDeposit.round()}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),

            // ── 5. Total ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '₹${totalPayable.round()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Incl. ₹${securityDeposit.round()} refundable deposit',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),

            // ── Separator ──────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),

            // ── 6. Kms limit ───────────────────────────────
            _infoNoteRow(
              Icons.speed_outlined,
              'Kms included',
              '$totalKms km  ($kmsPerDay km/day)',
              const Color(0xFF2E7D32),
            ),

            // ── 7. Fuel: Excluded ──────────────────────────
            _tagFareRow(
              'Fuel',
              'Excluded',
              Colors.orange.shade800,
              Colors.orange.shade50,
            ),

            // ── 8. Extra kms charge ────────────────────────
            _infoNoteRow(
              Icons.add_road_outlined,
              'Extra kms charge',
              '₹7/km beyond limit',
              Colors.grey.shade600,
            ),

            // ── 9. Tolls, Parking & Inter-state taxes ──────
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'Tolls, Parking & Inter-state taxes: ',
                            style:
                                TextStyle(color: Colors.grey.shade700),
                          ),
                          TextSpan(
                            text: 'To be paid by you',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Please Note ────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.campaign_outlined,
                          size: 15, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Text(
                        'Please Note',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _noteItem('Pricing plan cannot be changed after the creation of a booking. Extra Kms charge: ₹7/km'),
                  _noteItem('We do not permit taking the vehicles to Leh/Ladakh region, Kaza/Nako region and Spiti Valley'),
                  _noteItem('Please ensure to return the car at the same fuel level as it was when received'),
                  _noteItem('For a higher security deposit (₹50,000), you have the option to avail lower fares, which excludes the coverage of insurance, wear-and-tear, etc. For further details please call us at +910000000000'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ',
              style: TextStyle(
                  fontSize: 12, color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.5, color: Colors.brown.shade700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKmPlanSelector() {
    const labels = ['870 Kms', '1450 Kms', 'Unlimited'];
    const icons = [
      Icons.social_distance_outlined,
      Icons.add_road_outlined,
      Icons.all_inclusive_outlined,
    ];

    return Column(
      children: [
        Row(
          children: List.generate(3, (i) {
            final price = (_baseTotalPrice * _kmMultipliers[i]).round();
            final isSelected = _selectedKmPlan == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedKmPlan = i;
                    _totalPrice = _baseTotalPrice * _kmMultipliers[i];
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (_baseTotalPrice > 0) ...
                        [
                          const SizedBox(height: 4),
                          Text(
                            '₹$price',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Pricing plan cannot be changed after booking.',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tagFareRow(
      String label, String tag, Color tagColor, Color tagBg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                color: tagColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoNoteRow(
      IconData icon, String label, String note, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              note,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showBaseFareInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined,
                color: Color(0xFF2E7D32), size: 22),
            SizedBox(width: 8),
            Text(
              'Base Fare Info',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'The base fare for each car model is calculated based on the demand of that model during the searched duration.\n\n'
          '🔒 Surge protection promise — Book now to protect yourself from any price changes. Prices at the time of booking will be applicable for all modifications and extensions. Any new peak season added will not affect your booking.',
          style: TextStyle(fontSize: 13, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it',
                style: TextStyle(color: Color(0xFF2E7D32))),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final user = AuthService().currentUser;
    final saved = user?.savedPaymentMethods ?? [];

    if (_isLoggedIn && saved.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose a saved method',
              style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 10),
            ...List.generate(saved.length, (i) {
              final method = saved[i];
              final selected = _selectedSavedPaymentIndex == i;
              return InkWell(
                onTap: () => setState(() => _selectedSavedPaymentIndex = i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                      width: selected ? 1.5 : 1,
                    ),
                    color: selected ? const Color(0xFFE8F5E9) : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        method.type == 'upi' ? Icons.account_balance_wallet_outlined : Icons.credit_card,
                        color: selected ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              method.type.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                    ],
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showAddPaymentMethodDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Payment Method'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isLoggedIn
                ? 'No saved payment methods. Add one or enter details for this booking.'
                : 'Guest checkout: add your payment details for this booking.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _guestPaymentType,
            decoration: const InputDecoration(
              labelText: 'Payment Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'upi', child: Text('UPI')),
              DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
            ],
            onChanged: (v) {
              setState(() {
                _guestPaymentType = v ?? 'upi';
              });
            },
          ),
          const SizedBox(height: 10),
          if (_guestPaymentType == 'upi')
            TextFormField(
              controller: _guestPaymentDetailController,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'name@bank',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_guestPaymentType != 'upi') return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter UPI ID';
                }
                return null;
              },
            )
          else
            Column(
              children: [
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: 'XXXX XXXX XXXX XXXX',
                    border: const OutlineInputBorder(),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(top: 14, right: 10),
                      child: Text(
                        _detectCardBrand(_cardNumberController.text),
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (_guestPaymentType != 'card') return null;
                    return _validateCardNumber(value);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cardHolderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Card Holder Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_guestPaymentType != 'card') return null;
                    return _validateCardHolder(value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cardExpiryController,
                        keyboardType: TextInputType.datetime,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryDateTextFormatter(),
                          ],
                        decoration: const InputDecoration(
                          labelText: 'Valid Thru (MM/YY)',
                          hintText: '08/29',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_guestPaymentType != 'card') return null;
                          return _validateCardExpiry(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cardCvvController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (_guestPaymentType != 'card') return null;
                          return _validateCardCvv(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (_isLoggedIn)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _showAddPaymentMethodDialog,
                icon: const Icon(Icons.add),
                label: const Text('Save as payment method'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code',
                    hintText: 'Enter code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
          if (_appliedCouponCode != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_appliedCouponCode applied · You saved ₹${_couponDiscount.round()}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _removeCoupon, child: const Text('Remove')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Available Offers',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: null,
            decoration: const InputDecoration(
              labelText: 'Select an available offer',
              border: OutlineInputBorder(),
            ),
            items: _couponOffers
                .where(_isCouponUnlocked)
                .map(
                  (offer) => DropdownMenuItem<String>(
                    value: offer.code,
                    child: Text('${offer.code} · ${offer.title}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              final offer = _findOfferByCode(value);
              if (offer == null) return;
              setState(() {
                _couponController.text = offer.code;
              });
              _applyCoupon();
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _couponOffers.where((o) => !_isCouponUnlocked(o)).map((offer) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${offer.code} · Locked',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ExpiryDateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CouponOffer {
  final String code;
  final String title;
  final String subtitle;
  final double discountAmount;
  final double minSubtotal;
  final bool isEnabled;
  final String? lockReason;

  const _CouponOffer({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.discountAmount,
    required this.minSubtotal,
    required this.isEnabled,
    this.lockReason,
  });
}

