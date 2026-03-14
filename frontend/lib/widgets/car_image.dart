// car_image.dart — Resilient image widget for car photos.
//
// Features:
//   - Normalizes Unsplash URLs for consistent quality/cropping
//   - Shows progress while network image is loading
//   - Displays a graceful fallback icon/gradient when URL is empty or fails
//   - Optional border radius clipping for card/app-bar usage

import 'package:flutter/material.dart';

class CarImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double iconSize;
  final BorderRadius? borderRadius;

  const CarImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize = 44,
    this.borderRadius,
  });

  String _normalizedImageUrl(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return '';

    // Normalize Unsplash URLs for consistent quality/cropping across screens.
    if (url.contains('images.unsplash.com')) {
      final hasQuery = url.contains('?');
      final separator = hasQuery ? '&' : '?';
      final alreadyHasAuto = url.contains('auto=format');
      return alreadyHasAuto ? url : '$url${separator}auto=format&fit=crop&q=80';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // Normalize once so load/error/fallback logic uses a single source of truth.
    final url = _normalizedImageUrl(imageUrl);

    Widget image;
    if (url.isEmpty) {
      image = _fallback();
    } else {
      image = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final value = total != null && total > 0
              ? progress.cumulativeBytesLoaded / total
              : null;
          return _loading(value);
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _loading(double? value) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9EEF5), Color(0xFFDCE5EF)],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            value: value,
            color: const Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF3F8), Color(0xFFD9E2EC)],
        ),
      ),
      child: Center(
        child: Icon(Icons.directions_car_rounded, size: iconSize, color: const Color(0xFF7B8794)),
      ),
    );
  }
}
