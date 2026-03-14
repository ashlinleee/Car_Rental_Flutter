// car_details_screen.dart — Detailed view for a selected car.
//
// Displays full vehicle info (specs, pricing, features, policies, FAQs, reviews)
// and forwards the user into booking with preselected trip context when available.

import 'package:flutter/material.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../services/price_calculator.dart';
import '../widgets/car_image.dart';

class CarDetailsScreen extends StatelessWidget {
  const CarDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accept either a raw Car or a map containing Car + search context.
    final args = ModalRoute.of(context)?.settings.arguments;
    Car? car;
    String? selectedState;
    String? selectedPlace;
    String? pickupSpot;
    String? dropoffSpot;
    DateTime? pickupDate;
    TimeOfDay? pickupTime;
    DateTime? dropoffDate;
    TimeOfDay? dropoffTime;

    if (args is Car) {
      car = args;
    } else if (args is Map<String, dynamic>) {
      car = args['car'] as Car?;
      selectedState = args['selectedState'] as String?;
      selectedPlace = args['selectedPlace'] as String?;
      pickupSpot = args['pickupSpot'] as String?;
      dropoffSpot = args['dropoffSpot'] as String?;
      pickupDate = args['pickupDate'] as DateTime?;
      pickupTime = args['pickupTime'] as TimeOfDay?;
      dropoffDate = args['dropoffDate'] as DateTime?;
      dropoffTime = args['dropoffTime'] as TimeOfDay?;
    }

    if (car == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CarImage(
                    imageUrl: car.imageUrl,
                    fit: BoxFit.cover,
                    iconSize: 80,
                  ),
                  // Dark gradient so the back button is legible
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x88000000), Colors.transparent, Color(0xCC000000)],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Availability badge
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: _AvailBadge(isAvailable: car.isAvailable),
                  ),
                  // Rating badge
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            car.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              car.brand,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₹${car.pricePerDay.round()}',
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                ),
                                TextSpan(
                                  text: '/day',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${PriceCalculator.hourlyRate(car).round()}/hr',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Category chip
                  _CategoryChip(category: car.category),

                  const SizedBox(height: 20),

                  // ── Quick specs grid ──────────────────────
                  _sectionTitle('Vehicle Specs'),
                  const SizedBox(height: 12),
                  _buildSpecsGrid(car),

                  const SizedBox(height: 24),

                  // ── Pricing info ──────────────────────────
                  _sectionTitle('Pricing Info'),
                  const SizedBox(height: 12),
                  _buildPricingCard(car),

                  const SizedBox(height: 24),

                  // ── Book Now button ───────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: car.isAvailable
                          ? () => Navigator.pushNamed(
                                context,
                                '/booking',
                                arguments: {
                                  'car': car,
                                  'selectedState': selectedState,
                                  'selectedPlace': selectedPlace,
                                  'pickupSpot': pickupSpot,
                                  'dropoffSpot': dropoffSpot,
                                  'pickupDate': pickupDate,
                                  'pickupTime': pickupTime,
                                  'dropoffDate': dropoffDate,
                                  'dropoffTime': dropoffTime,
                                },
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(car.isAvailable
                              ? Icons.calendar_month_outlined
                              : Icons.block_outlined),
                          const SizedBox(width: 10),
                          Text(
                            car.isAvailable ? 'Book This Car' : 'Not Available',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Features ──────────────────────────────
                  if (car.features.isNotEmpty) ...[
                    _sectionTitle('Features'),
                    const SizedBox(height: 12),
                    _buildFeaturesSection(car),
                    const SizedBox(height: 24),
                  ],

                  // ── Inclusions / Exclusions ───────────────
                  _sectionTitle('Inclusions & Exclusions'),
                  const SizedBox(height: 12),
                  _buildInclusionsExclusions(),

                  const SizedBox(height: 24),

                  // ── Cancellation ──────────────────────────
                  _sectionTitle('Cancellation Policy'),
                  const SizedBox(height: 12),
                  _buildCancellationSection(),

                  const SizedBox(height: 24),

                  // ── Ratings ───────────────────────────────
                  _sectionTitle('Ratings'),
                  const SizedBox(height: 12),
                  _buildRatingsSection(car),

                  const SizedBox(height: 24),

                  // ── Reviews ───────────────────────────────
                  _sectionTitle('Reviews'),
                  const SizedBox(height: 12),
                  _buildReviewsSection(),

                  const SizedBox(height: 24),

                  // ── Similar Cars ──────────────────────────
                  _sectionTitle('Similar Cars'),
                  const SizedBox(height: 12),
                  _buildSimilarCarsSection(context, car, selectedState, selectedPlace),

                  const SizedBox(height: 24),

                  // ── FAQs ──────────────────────────────────
                  _sectionTitle('FAQs'),
                  const SizedBox(height: 12),
                  _buildFAQs(),

                  const SizedBox(height: 24),

                  // ── Important Points ──────────────────────
                  _sectionTitle('Important Points to Remember'),
                  const SizedBox(height: 12),
                  _buildImportantPoints(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildSpecsGrid(Car car) {
    final specs = [
      (Icons.people_alt_outlined, 'Seats', '${car.seats} seats'),
      (Icons.settings_outlined, 'Transmission', car.transmission),
      (Icons.local_gas_station_outlined, 'Fuel', car.fuelType),
      (Icons.category_outlined, 'Category', car.category),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      children: specs.map((s) => _SpecTile(icon: s.$1, label: s.$2, value: s.$3)).toList(),
    );
  }

  Widget _buildPricingCard(Car car) {
    final hourlyRate = PriceCalculator.hourlyRate(car);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _pricingRow(
            Icons.calendar_today_outlined,
            const Color(0xFFE3F0FF),
            const Color(0xFF2E7D32),
            'Daily rate',
            '₹${car.pricePerDay.round()}/day',
            isFirst: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEF2F7)),
          _pricingRow(
            Icons.schedule_outlined,
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
            'Hourly rate',
            '₹${hourlyRate.round()}/hr',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEF2F7)),
          _pricingRow(
            Icons.health_and_safety_outlined,
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100),
            'Insurance',
            '₹500/day  ·  ₹21/hr',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _pricingRow(
    IconData icon,
    Color iconBg,
    Color iconColor,
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 13, 16, isLast ? 16 : 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  // ── Features ─────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection(Car car) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: car.features
          .map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F0FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 6),
                    Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ── Ratings ──────────────────────────────────────────────────────────────
  Widget _buildRatingsSection(Car car) {
    const distribution = [
      ('5', 0.65),
      ('4', 0.22),
      ('3', 0.08),
      ('2', 0.03),
      ('1', 0.02),
    ];
    const reviewCount = 128;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                car.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < car.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$reviewCount reviews',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: distribution.map((d) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(d.$1,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF555555))),
                      const SizedBox(width: 3),
                      const Icon(Icons.star_rounded,
                          size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: d.$2,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFEEF2F7),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${(d.$2 * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF888888)),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reviews ──────────────────────────────────────────────────────────────
  Widget _buildReviewsSection() {
    const reviews = [
      (
        name: 'Arjun Sharma',
        rating: 5,
        date: '12 Feb 2026',
        comment:
            'Excellent car in perfect condition! Very smooth drive and the pickup was hassle-free. Highly recommend.',
        initials: 'AS',
        color: Color(0xFF2E7D32),
      ),
      (
        name: 'Priya Mehta',
        rating: 4,
        date: '28 Jan 2026',
        comment:
            'Good experience overall. The car was very clean and well-maintained. AC worked perfectly throughout the trip.',
        initials: 'PM',
        color: Color(0xFF2E7D32),
      ),
      (
        name: 'Rahul Verma',
        rating: 5,
        date: '5 Jan 2026',
        comment:
            'Amazing ride quality! The booking process was super easy and the drop-off was quick. Will definitely book again.',
        initials: 'RV',
        color: Color(0xFF6A1B9A),
      ),
    ];

    return Column(
      children: reviews
          .map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6EBF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: r.color,
                          child: Text(
                            r.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(r.date,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r.comment,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF444444),
                          height: 1.5),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ── Similar Cars ─────────────────────────────────────────────────────────
  Widget _buildSimilarCarsSection(
    BuildContext context,
    Car currentCar,
    String? selectedState,
    String? selectedPlace,
  ) {
    final locationState =
        ((selectedState ?? '').trim().isNotEmpty ? selectedState! : (currentCar.state ?? '')).trim();
    final locationPlace =
        ((selectedPlace ?? '').trim().isNotEmpty ? selectedPlace! : (currentCar.place ?? '')).trim();

    bool isSameLocation(Car car) {
      final carState = (car.state ?? '').trim().toLowerCase();
      final carPlace = (car.place ?? '').trim().toLowerCase();
      return carState == locationState.toLowerCase() &&
          carPlace == locationPlace.toLowerCase();
    }

    return FutureBuilder<List<Car>>(
      future: ApiService.getCars(
        category: currentCar.category,
      ),
      builder: (context, snapshot) {
        final allCars = snapshot.data ?? const <Car>[];
        final similar = allCars.where((c) => c.id != currentCar.id).toList(growable: false);
        final localSimilar = similar.where(isSameLocation).take(6).toList(growable: false);
        final fallbackSimilar = similar.where((c) => !isSameLocation(c)).take(6).toList(growable: false);
        final showingFallback = localSimilar.isEmpty;
        final displayCars = showingFallback ? fallbackSimilar : localSimilar;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (displayCars.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6EBF2)),
            ),
            child: const Text(
              'No similar cars available right now.',
              style: TextStyle(fontSize: 13, color: Color(0xFF616161)),
            ),
          );
        }

        return SizedBox(
          height: 185,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayCars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final car = displayCars[i];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (showingFallback) {
                    final placeLabel = locationPlace.isNotEmpty ? locationPlace : 'your selected location';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${car.name} is not available in $placeLabel.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pushReplacementNamed(
                    context,
                    '/car_details',
                    arguments: {
                      'car': car,
                      'selectedState': locationState,
                      'selectedPlace': locationPlace,
                    },
                  );
                },
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6EBF2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(14)),
                        child: SizedBox(
                          height: 95,
                          width: double.infinity,
                          child: CarImage(
                            imageUrl: car.imageUrl,
                            fit: BoxFit.cover,
                            iconSize: 32,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              car.brand,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '₹${car.pricePerDay.round()}/day',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                if (showingFallback) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'Other location',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Color(0xFF90A4AE),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Inclusions & Exclusions ───────────────────────────────────────────────
  Widget _buildInclusionsExclusions() {
    const inclusions = [
      'Vehicle insurance coverage',
      '24/7 roadside assistance',
      'Basic vehicle maintenance',
      'Driver assistance on request',
      'Free GPS navigation',
    ];
    const exclusions = [
      'Fuel charges',
      'Toll & parking fees',
      'Inter-state permit fees',
      'Personal belongings',
      'Traffic fines',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _incExcColumn('Inclusions', inclusions, true)),
        const SizedBox(width: 12),
        Expanded(child: _incExcColumn('Exclusions', exclusions, false)),
      ],
    );
  }

  Widget _incExcColumn(String title, List<String> items, bool isInclusion) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isInclusion
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInclusion
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFEF9A9A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isInclusion
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 16,
                color: isInclusion
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isInclusion
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isInclusion
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      size: 14,
                      color: isInclusion
                          ? const Color(0xFF43A047)
                          : const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Cancellation Policy ───────────────────────────────────────────────────
  Widget _buildCancellationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCDD2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cancel_outlined,
                color: Color(0xFFC62828), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cancellation Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFC62828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cancellation is not available for any bookings. Once confirmed, the booking cannot be cancelled or modified.',
                  style: TextStyle(
                      fontSize: 13, color: Colors.red[800], height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAQs ─────────────────────────────────────────────────────────────────
  Widget _buildFAQs() {
    const faqs = [
      (
        q: 'What documents do I need to carry?',
        a: 'You need your original Driving License and a valid government-issued ID (Aadhaar, Passport, or Voter ID). DigiLocker copies are also accepted.',
      ),
      (
        q: 'Is fuel included in the rental price?',
        a: 'No, fuel is not included. You receive the car at a certain fuel level and must return it the same. Shortfalls attract a ₹500 service charge plus actual fuel cost.',
      ),
      (
        q: 'Can I drive outside the state?',
        a: 'Inter-state travel is allowed, but inter-state permit fees must be paid by you. Please notify us in advance if you plan to cross state borders.',
      ),
      (
        q: 'What happens in case of a breakdown?',
        a: 'We provide 24/7 roadside assistance. In case of a breakdown, contact our support and we will arrange a replacement vehicle or on-site repair as soon as possible.',
      ),
      (
        q: 'Is there a security deposit?',
        a: 'Yes, a refundable security deposit is collected at handover. The amount varies by vehicle category and is returned within 5–7 working days after the trip, subject to no damages.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: faqs.asMap().entries.map((entry) {
            final i = entry.key;
            final faq = entry.value;
            return Column(
              children: [
                Theme(
                  data: ThemeData().copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    leading: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F0FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'Q',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      faq.q,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    iconColor: const Color(0xFF2E7D32),
                    collapsedIconColor: Colors.grey,
                    children: [
                      Text(
                        faq.a,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < faqs.length - 1)
                  const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFEEF2F7)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Important Points to Remember ─────────────────────────────────────────
  Widget _buildImportantPoints() {
    final points = [
      const _ImportantPoint(
        icon: Icons.edit_note_outlined,
        title: 'CHANGE IN PRICING PLAN',
        body:
            'The pricing plan (6 kms/hr, without fuel) cannot be changed after the booking is made.',
      ),
      const _ImportantPoint(
        icon: Icons.local_gas_station_outlined,
        title: 'FUEL',
        body:
            'In case you are returning the car at a lower fuel level than what was received, we will charge a flat ₹500 refuelling service charge + actual fuel cost to get the tank to the same level as what was received.',
      ),
      const _ImportantPoint(
        icon: Icons.toll_outlined,
        title: 'TOLLS, PARKING, INTER-STATE TAXES',
        body: 'To be paid by you.',
      ),
      const _ImportantPoint(
        icon: Icons.badge_outlined,
        title: 'ID VERIFICATION',
        body:
            'Please keep your original or DigiLocker of Driving License handy. While delivering the car to you, our executive will verify your original or DigiLocker of Driving License and ID proof (same as the ones whose details were provided while making the booking). This verification is mandatory. In the unfortunate case where you cannot show these documents, we will not be able to handover the car to you, and it will be treated as a late cancellation (100% of the fare would be payable). Driving license printed on A4 sheet of paper (original or otherwise) will not be considered as a valid document. We may ask for additional documents for verification in some cases, e.g., local ID or proof of travel.',
      ),
      const _ImportantPoint(
        icon: Icons.checklist_outlined,
        title: 'PRE-HANDOVER INSPECTION',
        body:
            'Please inspect the car (including the fuel gauge and odometer) thoroughly before approving the checklist.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
      ),
      child: Column(
        children: points.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Number badge
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(p.icon, size: 16, color: const Color(0xFF2E7D32)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF1A237E),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.body,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D4037),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < points.length - 1)
                const Divider(height: 1, indent: 54, endIndent: 16, color: Color(0xFFFFE082)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _ImportantPoint {
  final IconData icon;
  final String title;
  final String body;
  const _ImportantPoint({required this.icon, required this.title, required this.body});
}

class _AvailBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.85)
            : Colors.red.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isAvailable ? 'Available' : 'Not Available',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  static (Color bg, Color text) _color(String c) {
    switch (c.toLowerCase()) {
      case 'luxury':
        return (const Color(0xFFFFF8E1), const Color(0xFFF57F17));
      case 'sports':
        return (const Color(0xFFFFEBEE), const Color(0xFFC62828));
      case 'electric':
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'suv':
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'sedan':
        return (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A));
      default:
        return (const Color(0xFFF5F5F5), const Color(0xFF424242));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text) = _color(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SpecTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
