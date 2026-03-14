// confirmation_screen.dart — Post-booking success screen.
//
// Shows booking summary, trip details, and payment status, and provides
// invoice export as PDF (web download or native save dialog fallback).

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/booking.dart';
import '../models/car.dart';
import '../widgets/car_image.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  // Builds a human-readable payment summary from stored payment fields.
  String _paymentMethodSummary(Booking booking) {
    final type = (booking.paymentMethodType ?? '').trim().toLowerCase();
    final label = (booking.paymentMethodLabel ?? '').trim();
    if (type.isEmpty && label.isEmpty) return 'Not specified';

    final typeTitle = switch (type) {
      'upi' => 'UPI',
      'card' => 'Card',
      _ => type.isEmpty ? 'Payment' : type.toUpperCase(),
    };

    if (label.isEmpty) return typeTitle;
    if (typeTitle.toLowerCase() == label.toLowerCase()) return typeTitle;
    return '$typeTitle - $label';
  }

  // Plain-text invoice content used for clipboard fallback when file save fails.
  String _invoiceText(Booking booking, Car car) {
    final dateFmt = DateFormat('dd MMM yyyy');
    final createdAt = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    return [
      'BRUMM - INVOICE',
      'Generated: $createdAt',
      'Invoice ID: INV-${booking.id}',
      'Booking ID: ${booking.id}',
      '',
      'Customer Details',
      'Name: ${booking.customerName}',
      'Email: ${booking.customerEmail}',
      'Phone: ${booking.customerPhone}',
      '',
      'Trip Details',
      'Vehicle: ${car.name} (${car.brand})',
      'Category: ${car.category}',
      'Pickup Date: ${dateFmt.format(booking.startDate)} ${booking.startTime}',
      'Return Date: ${dateFmt.format(booking.endDate)} ${booking.endTime}',
      'Pickup Spot: ${(booking.pickupSpot ?? '').isEmpty ? 'Not selected' : booking.pickupSpot}',
      'Drop Spot: ${(booking.dropoffSpot ?? '').isEmpty ? 'Not selected' : booking.dropoffSpot}',
      '',
      'Payment Details',
      'Payment Method: ${_paymentMethodSummary(booking)}',
      'Amount Paid: INR ${booking.totalPrice.toStringAsFixed(0)}',
      'Booking Status: ${booking.status}',
      '',
      'Thank you for choosing Brumm.',
    ].join('\n');
  }

  // Generates a printable PDF invoice and returns file bytes.
  Future<Uint8List> _buildInvoicePdfBytes(Booking booking, Car car) async {
    final doc = pw.Document();
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
          item('Invoice ID', 'INV-${booking.id}'),
          item('Booking ID', booking.id),
          item('Status', booking.status),
          pw.SizedBox(height: 10),
          pw.Text('Customer Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Name', booking.customerName),
          item('Email', booking.customerEmail),
          item('Phone', booking.customerPhone),
          pw.SizedBox(height: 10),
          pw.Text('Trip Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Vehicle', '${car.name} (${car.brand})'),
          item('Category', car.category),
          item('Pickup', '${dateFmt.format(booking.startDate)} ${booking.startTime}'),
          item('Return', '${dateFmt.format(booking.endDate)} ${booking.endTime}'),
          item('Pickup Spot', (booking.pickupSpot ?? '').isEmpty ? 'Not selected' : booking.pickupSpot!),
          item('Drop Spot', (booking.dropoffSpot ?? '').isEmpty ? 'Not selected' : booking.dropoffSpot!),
          pw.SizedBox(height: 10),
          pw.Text('Payment Details', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          item('Payment Method', _paymentMethodSummary(booking)),
          item('Amount Paid', 'INR ${booking.totalPrice.toStringAsFixed(0)}'),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Text('Thank you for choosing Brumm.', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _downloadInvoice(BuildContext context, Booking booking, Car car) async {
    final content = _invoiceText(booking, car);
    final bytes = await _buildInvoicePdfBytes(booking, car);
    final fileName = 'brumm-invoice-${booking.id}.pdf';

    try {
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
          content: Text('Could not save invoice (${e.runtimeType}). Invoice copied to clipboard.'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      await Clipboard.setData(ClipboardData(text: content));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Booking booking = args['booking'] as Booking;
    final Car car = args['car'] as Car;
    final int days = booking.endDate.difference(booking.startDate).inDays + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Booking Confirmed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Brumm ride is all set',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Back to Home',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (_) => false,
                ),
              ),
            ],
          ),

          // ── Booking ID Banner (tap to copy) ───────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: booking.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Booking ID copied to clipboard'),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(12),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          color: Colors.green[700], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking ID',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${booking.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.copy_outlined,
                          size: 18, color: Colors.green[500]),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Vehicle Card ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Vehicle', Icons.directions_car_outlined),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CarImage(
                          imageUrl: car.imageUrl,
                          width: 90,
                          height: 72,
                          borderRadius: BorderRadius.circular(10),
                          iconSize: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${car.brand} \u00b7 ${car.category}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[500]),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 13, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text('${car.seats} seats',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                  const SizedBox(width: 12),
                                  Icon(Icons.settings_outlined,
                                      size: 13, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(car.transmission,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Rental Period ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                        'Rental Period', Icons.date_range_outlined),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _dateTile('Pickup', booking.startDate,
                              Icons.flight_land_outlined),
                        ),
                        Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 18, color: Colors.grey[400]),
                        ),
                        Expanded(
                          child: _dateTile('Return', booking.endDate,
                              Icons.flight_takeoff_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$days day${days > 1 ? 's' : ''} total rental',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow(
                            Icons.my_location_outlined,
                            'Pickup Spot',
                            (booking.pickupSpot ?? '').isNotEmpty ? booking.pickupSpot! : 'Not selected',
                          ),
                          _infoRow(
                            Icons.place_outlined,
                            'Drop Spot',
                            (booking.dropoffSpot ?? '').isNotEmpty ? booking.dropoffSpot! : 'Not selected',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Customer Info ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                        'Customer', Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    _infoRow(Icons.badge_outlined, 'Name',
                        booking.customerName),
                    _infoRow(Icons.email_outlined, 'Email',
                        booking.customerEmail),
                    _infoRow(Icons.phone_outlined, 'Phone',
                        booking.customerPhone),
                  ],
                ),
              ),
            ),
          ),

          // ── Payment Summary ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                        'Payment Summary', Icons.receipt_long_outlined),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount Paid',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[600])),
                        Text(
                          '₹${booking.totalPrice.round()}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: Colors.green[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Payment Confirmed',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF1A1A2E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Paid via ${_paymentMethodSummary(booking)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Action Buttons ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.home_outlined),
                      label: const Text(
                        'Back to Home',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (_) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Download Invoice', style: TextStyle(fontSize: 16)),
                      onPressed: () => _downloadInvoice(context, booking, car),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A2E),
                        side: const BorderSide(color: Color(0xFF1A1A2E), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share Booking Details',
                          style: TextStyle(fontSize: 16)),
                      onPressed: () {
                        final shareText =
                          'Brumm Booking\nID: #${booking.id}\n'
                            'Car: ${car.name}\n'
                            'Pickup: ${DateFormat('MMM dd, yyyy').format(booking.startDate)}\n'
                          'Pickup Spot: ${booking.pickupSpot ?? '--'}\n'
                          'Drop Spot: ${booking.dropoffSpot ?? '--'}\n'
                            'Return: ${DateFormat('MMM dd, yyyy').format(booking.endDate)}\n'
                            'Total: ₹${booking.totalPrice.round()}';
                        Clipboard.setData(ClipboardData(text: shareText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                                'Booking details copied to clipboard'),
                            backgroundColor: Colors.green[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.all(12),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(
                            color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  static Widget _dateTile(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            DateFormat('EEE, MMM dd').format(date),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Text(
            DateFormat('yyyy').format(date),
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}
