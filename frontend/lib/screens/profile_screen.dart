// profile_screen.dart — Account hub for authenticated users.
//
// Contains 3 tabs:
//   - Profile  : view/edit personal details and change password
//   - Bookings : booking history with invoice support
//   - Payments : manage saved payment methods
//
// Redirects unauthenticated users to login.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    // Ask for confirmation before clearing persisted auth state.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _auth.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      // If session expired/missing, bounce to login on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            Tab(icon: Icon(Icons.history), text: 'Bookings'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProfileTab(user: user, auth: _auth),
          _BookingsTab(auth: _auth),
          _PaymentsTab(user: user, auth: _auth),
        ],
      ),
    );
  }
}

// ─── Profile Tab ────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final User user;
  final AuthService auth;
  const _ProfileTab({required this.user, required this.auth});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _editMode = false;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    final err = await widget.auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _savingProfile = false;
      if (err == null) _editMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Profile updated'),
      backgroundColor: err != null ? Colors.red : Colors.green,
    ));
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    final err = await widget.auth.changePassword(
      currentPassword: _currentPassCtrl.text,
      newPassword: _newPassCtrl.text,
    );
    if (!mounted) return;
    setState(() => _savingPassword = false);
    if (err == null) {
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Password changed successfully'),
      backgroundColor: err != null ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = widget.auth.currentUser ?? widget.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cs.primaryContainer,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 32, color: cs.onPrimaryContainer, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(user.email, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
          ),
          const SizedBox(height: 24),

          // Profile form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Personal Info',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (!_editMode)
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            onPressed: () => setState(() => _editMode = true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: _editMode,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      enabled: _editMode,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                    ),
                    if (_editMode) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _editMode = false;
                                  _nameCtrl.text = user.name;
                                  _phoneCtrl.text = user.phone;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _savingProfile ? null : _saveProfile,
                              child: _savingProfile
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Change password
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Change Password',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentPassCtrl,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v != _newPassCtrl.text) ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _savingPassword ? null : _changePassword,
                      child: _savingPassword
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Change Password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bookings Tab ────────────────────────────────────────────────────────────

class _BookingsTab extends StatefulWidget {
  final AuthService auth;
  const _BookingsTab({required this.auth});

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  List<dynamic>? _bookings;
  bool _loading = true;
  String? _error;
  final Map<String, Map<String, dynamic>> _carByIdCache = {};

  String _historyPaymentSummary(Map<String, dynamic> booking) {
    final paymentType = (booking['paymentMethodType'] as String? ?? '').trim().toLowerCase();
    final paymentLabel = (booking['paymentMethodLabel'] as String? ?? '').trim();

    final typeTitle = switch (paymentType) {
      'upi' => 'UPI',
      'card' => 'Card',
      _ => paymentType.isEmpty ? 'Payment' : paymentType.toUpperCase(),
    };

    if (paymentLabel.isEmpty) return typeTitle;
    if (typeTitle.toLowerCase() == paymentLabel.toLowerCase()) return typeTitle;
    return '$typeTitle - $paymentLabel';
  }

  String _historyInvoiceText(
    Map<String, dynamic> booking,
    String carName,
    String brand,
    String category,
  ) {
    final startDate = DateTime.tryParse((booking['startDate'] as String?) ?? '');
    final endDate = DateTime.tryParse((booking['endDate'] as String?) ?? '');
    final startTime = (booking['startTime'] as String?) ?? '--';
    final endTime = (booking['endTime'] as String?) ?? '--';
    final bookingId = (booking['id'] as String?) ?? (booking['_id'] as String?) ?? '--';
    final customerName = (booking['customerName'] as String?) ?? '--';
    final customerEmail = (booking['customerEmail'] as String?) ?? '--';
    final customerPhone = (booking['customerPhone'] as String?) ?? '--';
    final pickupSpot = (booking['pickupSpot'] as String? ?? '').trim();
    final dropoffSpot = (booking['dropoffSpot'] as String? ?? '').trim();
    final status = (booking['status'] as String? ?? 'Confirmed').trim();
    final total = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;

    final dateFmt = DateFormat('dd MMM yyyy');
    final createdAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return [
      'BRUMM - INVOICE',
      'Generated: $createdAt',
      'Invoice ID: INV-$bookingId',
      'Booking ID: $bookingId',
      '',
      'Customer Details',
      'Name: $customerName',
      'Email: $customerEmail',
      'Phone: $customerPhone',
      '',
      'Trip Details',
      'Vehicle: $carName${brand.isNotEmpty ? ' ($brand)' : ''}',
      'Category: ${category.isEmpty ? '--' : category}',
      'Pickup Date: ${startDate != null ? dateFmt.format(startDate) : '--'} $startTime',
      'Return Date: ${endDate != null ? dateFmt.format(endDate) : '--'} $endTime',
      'Pickup Spot: ${pickupSpot.isNotEmpty ? pickupSpot : 'Not selected'}',
      'Drop Spot: ${dropoffSpot.isNotEmpty ? dropoffSpot : 'Not selected'}',
      '',
      'Payment Details',
      'Payment Method: ${_historyPaymentSummary(booking)}',
      'Amount Paid: INR ${total.toStringAsFixed(0)}',
      'Booking Status: $status',
      '',
      'Thank you for choosing Brumm.',
    ].join('\n');
  }

  Future<Uint8List> _buildHistoryInvoicePdfBytes(
    Map<String, dynamic> booking,
    String carName,
    String brand,
    String category,
  ) async {
    final doc = pw.Document();

    final startDate = DateTime.tryParse((booking['startDate'] as String?) ?? '');
    final endDate = DateTime.tryParse((booking['endDate'] as String?) ?? '');
    final startTime = (booking['startTime'] as String?) ?? '--';
    final endTime = (booking['endTime'] as String?) ?? '--';
    final bookingId = (booking['id'] as String?) ?? (booking['_id'] as String?) ?? '--';
    final customerName = (booking['customerName'] as String?) ?? '--';
    final customerEmail = (booking['customerEmail'] as String?) ?? '--';
    final customerPhone = (booking['customerPhone'] as String?) ?? '--';
    final pickupSpot = (booking['pickupSpot'] as String? ?? '').trim();
    final dropoffSpot = (booking['dropoffSpot'] as String? ?? '').trim();
    final status = (booking['status'] as String? ?? 'Confirmed').trim();
    final total = (booking['totalPrice'] as num?)?.toDouble() ?? 0.0;

    final dateFmt = DateFormat('dd MMM yyyy');
    final createdAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pw.Widget item(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
            ),
            pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text('BRUMM INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Generated: $createdAt', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text('Invoice & Booking', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Invoice ID', 'INV-$bookingId'),
          item('Booking ID', bookingId),
          item('Status', status),
          pw.SizedBox(height: 10),
          pw.Text('Customer Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Name', customerName),
          item('Email', customerEmail),
          item('Phone', customerPhone),
          pw.SizedBox(height: 10),
          pw.Text('Trip Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Vehicle', '$carName${brand.isNotEmpty ? ' ($brand)' : ''}'),
          item('Category', category.isEmpty ? '--' : category),
          item('Pickup', '${startDate != null ? dateFmt.format(startDate) : '--'} $startTime'),
          item('Return', '${endDate != null ? dateFmt.format(endDate) : '--'} $endTime'),
          item('Pickup Spot', pickupSpot.isNotEmpty ? pickupSpot : 'Not selected'),
          item('Drop Spot', dropoffSpot.isNotEmpty ? dropoffSpot : 'Not selected'),
          pw.SizedBox(height: 10),
          pw.Text('Payment Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Payment Method', _historyPaymentSummary(booking)),
          item('Amount Paid', 'INR ${total.toStringAsFixed(0)}'),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text('Thank you for choosing Brumm.', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _downloadHistoryInvoice(
    BuildContext context,
    Map<String, dynamic> booking,
    String carName,
    String brand,
    String category,
  ) async {
    final bookingId = (booking['id'] as String?) ?? (booking['_id'] as String?) ?? 'booking';
    final fileName = 'brumm-invoice-$bookingId.pdf';
    final fallbackText = _historyInvoiceText(booking, carName, brand, category);

    try {
      final bytes = await _buildHistoryInvoicePdfBytes(booking, carName, brand, category);

      if (kIsWeb) {
        final file = XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: fileName,
        );
        await file.saveTo(fileName);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice PDF downloaded successfully')),
        );
        return;
      }

      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF', extensions: ['pdf']),
        ],
      );
      if (location == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice download cancelled')),
        );
        return;
      }

      final file = XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: fileName,
      );
      await file.saveTo(location.path);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice PDF downloaded successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save invoice ($e). Invoice copied to clipboard.'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      await Clipboard.setData(ClipboardData(text: fallbackText));
    }
  }

  Future<void> _showHistoryInvoicePreview(
    BuildContext context,
    Map<String, dynamic> booking,
    String carName,
    String brand,
    String category,
  ) async {
    final invoiceText = _historyInvoiceText(booking, carName, brand, category);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invoice Preview'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              invoiceText,
              style: const TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invoiceText));
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice content copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _downloadHistoryInvoice(context, booking, carName, brand, category);
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.auth.getBookingHistory();
    if (!mounted) return;
    if (result != null) {
      await _hydrateMissingCars(result);
      if (!mounted) return;
    }
    setState(() {
      _loading = false;
      if (result == null) {
        _error = 'Failed to load bookings';
      } else {
        _bookings = result;
      }
    });
  }

  Future<void> _hydrateMissingCars(List<dynamic> bookings) async {
    final missingIds = <String>{};
    for (final raw in bookings) {
      if (raw is! Map<String, dynamic>) continue;
      final carValue = raw['carId'];
      if (carValue is String && carValue.isNotEmpty && !_carByIdCache.containsKey(carValue)) {
        missingIds.add(carValue);
      }
    }

    for (final carId in missingIds) {
      final car = await ApiService.getCarById(carId);
      if (car != null) {
        _carByIdCache[carId] = {
          'id': car.id,
          'name': car.name,
          'brand': car.brand,
          'category': car.category,
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadBookings, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_bookings == null || _bookings!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No bookings yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Your booking history will appear here',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy');
    final dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final b = _bookings![idx] as Map<String, dynamic>;
            final rawCarId = b['carId'] is String ? (b['carId'] as String) : null;
            final car = (b['carId'] is Map<String, dynamic>)
              ? b['carId'] as Map<String, dynamic>
              : (b['car'] is Map<String, dynamic>
                ? b['car'] as Map<String, dynamic>
                : (rawCarId != null ? _carByIdCache[rawCarId] : null));
          final carName = car != null
              ? '${car['name'] ?? ''}'.trim().isNotEmpty
                  ? '${car['name']}'
                  : '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim()
              : 'Unknown Car';
            final carBrand = car != null ? ((car['brand'] as String?) ?? '').trim() : '';
            final carCategory = car != null ? ((car['category'] as String?) ?? '').trim() : '';
          final pickup = b['startDate'] != null ? DateTime.tryParse(b['startDate']) : null;
          final dropoff = b['endDate'] != null ? DateTime.tryParse(b['endDate']) : null;
          final total = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;
          final status = (b['status'] as String? ?? 'Confirmed').trim();
          final paymentType = (b['paymentMethodType'] as String? ?? '').toUpperCase();
          final paymentLabel = (b['paymentMethodLabel'] as String? ?? '').trim();
          final createdAt = b['createdAt'] != null ? DateTime.tryParse(b['createdAt']) : null;
          final bookingId = (b['id'] as String?) ?? (b['_id'] as String?) ?? '--';
          final customerName = (b['customerName'] as String?) ?? '--';
          final startTime = (b['startTime'] as String?) ?? '--';
          final endTime = (b['endTime'] as String?) ?? '--';
            final pickupSpot = (b['pickupSpot'] as String? ?? '').trim();
            final dropoffSpot = (b['dropoffSpot'] as String? ?? '').trim();
          final rentalDays = (pickup != null && dropoff != null)
              ? (dropoff.difference(pickup).inDays + 1)
              : null;

          Color statusBg;
          Color statusFg;
          switch (status.toLowerCase()) {
            case 'cancelled':
              statusBg = Colors.red.shade100;
              statusFg = Colors.red.shade800;
              break;
            case 'completed':
              statusBg = Colors.green.shade100;
              statusFg = Colors.green.shade800;
              break;
            default:
              statusBg = Colors.green.shade100;
              statusFg = Colors.green.shade800;
          }

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          carName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusFg, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: ${bookingId.length > 12 ? bookingId.substring(0, 12) : bookingId}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(customerName, style: const TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (pickup != null && dropoff != null)
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFmt.format(pickup)} → ${dateFmt.format(dropoff)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Start: $startTime  •  End: $endTime',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  if (rentalDays != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timelapse_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$rentalDays day${rentalDays == 1 ? '' : 's'} rental',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Pickup: ${pickupSpot.isNotEmpty ? pickupSpot : 'Not selected'}\nDrop: ${dropoffSpot.isNotEmpty ? dropoffSpot : 'Not selected'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  if (paymentLabel.isNotEmpty || paymentType.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.payment_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            paymentLabel.isNotEmpty
                                ? 'Paid via $paymentType • $paymentLabel'
                                : 'Paid via $paymentType',
                            style: const TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_note_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Booked on ${dateTimeFmt.format(createdAt)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        fmt.format(total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 430;

                      final viewBtn = OutlinedButton.icon(
                        onPressed: () => _showHistoryInvoicePreview(
                          context,
                          b,
                          carName,
                          carBrand,
                          carCategory,
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('View Invoice'),
                      );

                      final downloadBtn = OutlinedButton.icon(
                        onPressed: () => _downloadHistoryInvoice(
                          context,
                          b,
                          carName,
                          carBrand,
                          carCategory,
                        ),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Download Invoice'),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            viewBtn,
                            const SizedBox(height: 8),
                            downloadBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: viewBtn),
                          const SizedBox(width: 8),
                          Expanded(child: downloadBtn),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Payments Tab ────────────────────────────────────────────────────────────

class _PaymentsTab extends StatefulWidget {
  final User user;
  final AuthService auth;
  const _PaymentsTab({required this.user, required this.auth});

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  bool _adding = false;

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

  void _showAddDialog() {
    final upiCtrl = TextEditingController();
    final cardNumberCtrl = TextEditingController();
    final cardHolderCtrl = TextEditingController();
    final cardExpiryCtrl = TextEditingController();
    final cardCvvCtrl = TextEditingController();
    String selectedType = 'upi';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('Add Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                ],
                onChanged: (v) => setDialogState(() => selectedType = v ?? 'upi'),
              ),
              const SizedBox(height: 12),
              if (selectedType == 'upi')
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
                      controller: cardNumberCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        border: const OutlineInputBorder(),
                        helperText: _detectCardBrand(cardNumberCtrl.text),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cardHolderCtrl,
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
                            controller: cardExpiryCtrl,
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
                            controller: cardCvvCtrl,
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                String label;
                if (selectedType == 'upi') {
                  final upi = upiCtrl.text.trim();
                  if (upi.isEmpty) return;
                  label = upi;
                } else {
                  final numberError = _validateCardNumber(cardNumberCtrl.text);
                  if (numberError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(numberError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final holderError = _validateCardHolder(cardHolderCtrl.text);
                  if (holderError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(holderError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final expiryError = _validateCardExpiry(cardExpiryCtrl.text);
                  if (expiryError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(expiryError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final cvvError = _validateCardCvv(cardCvvCtrl.text);
                  if (cvvError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(cvvError), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final digits = _digitsOnly(cardNumberCtrl.text);
                  final last4 = digits.substring(digits.length - 4);
                  final brand = _detectCardBrand(digits);
                  label = '$brand ••$last4';
                }

                Navigator.pop(ctx);
                setState(() => _adding = true);
                final err = await widget.auth.addPaymentMethod(
                  type: selectedType,
                  label: label,
                  token: 'tok_${DateTime.now().millisecondsSinceEpoch}',
                );
                if (!mounted) return;
                setState(() => _adding = false);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment method added')), 
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      }),
    ).then((_) {
      upiCtrl.dispose();
      cardNumberCtrl.dispose();
      cardHolderCtrl.dispose();
      cardExpiryCtrl.dispose();
      cardCvvCtrl.dispose();
    });
  }

  Future<void> _remove(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text('Remove this payment method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final err = await widget.auth.removePaymentMethod(index);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'upi':
        return Icons.account_balance_wallet_outlined;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.auth.currentUser ?? widget.user;
    final methods = user.savedPaymentMethods;

    return Stack(
      children: [
        methods.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No saved payment methods',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Payment Method'),
                      onPressed: _showAddDialog,
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: methods.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  if (idx == methods.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment Method'),
                        onPressed: _showAddDialog,
                      ),
                    );
                  }
                  final m = methods[idx];
                  return Card(
                    child: ListTile(
                      leading: Icon(_iconForType(m.type)),
                      title: Text(m.label),
                      subtitle: Text(m.type),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _remove(idx),
                      ),
                    ),
                  );
                },
              ),
        if (_adding)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
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
