// car_card.dart — Reusable card widget for rendering a car in lists/grids.
//
// Presents a compact visual summary: image, availability, rating, fuel icon,
// brand/seat info, daily price, and category badge. Tapping the card triggers
// the provided onTap callback (typically opens details screen).

import 'package:flutter/material.dart';
import '../models/car.dart';
import 'car_image.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const CarCard({
    super.key,
    required this.car,
    required this.onTap,
  });

  // Returns a distinct color pair per category
  static (Color bg, Color text) _categoryColor(String category) {
    switch (category.toLowerCase()) {
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
    // Category colors are computed once per build and reused in badge UI.
    final (catBg, catText) = _categoryColor(car.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EBF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Car Image ──────────────────────────────────
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CarImage(
                      imageUrl: car.imageUrl,
                      fit: BoxFit.cover,
                      iconSize: 48,
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                            stops: const [0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Availability badge (top-left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _AvailabilityBadge(isAvailable: car.isAvailable),
                    ),

                    // Rating badge (bottom-right)
                    Positioned(
                      bottom: 7,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            car.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Fuel icon (bottom-left)
                    Positioned(
                      bottom: 7,
                      left: 8,
                      child: Icon(
                        car.fuelType == 'Electric'
                            ? Icons.electric_bolt
                            : Icons.local_gas_station,
                        color: car.fuelType == 'Electric'
                            ? Colors.greenAccent
                            : Colors.white70,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Car Details ────────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        car.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Brand + seats
                      Row(
                        children: [
                          Text(
                            car.brand,
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                          Text(
                            '  •  ',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                          Icon(Icons.people_alt_outlined,
                              size: 11, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            '${car.seats}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Price + category badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: '/day',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: catBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              car.category,
                              style: TextStyle(
                                color: catText,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Booked',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
