import 'package:flutter/material.dart';
import 'package:quit_drinking/constants/app_colors.dart';

/// A reusable circular app logo built from the brand image (Logo-02), which
/// already contains the wordmark — so no separate name text
/// is drawn beside it.
class AppLogo extends StatelessWidget {
  /// Logo diameter in logical pixels.
  final double size;

  const AppLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    // Decode at the rendered size (× device pixel ratio) to limit memory.
    final cacheWidth =
        (size * MediaQuery.of(context).devicePixelRatio).round();

    return ClipOval(
      child: Image.asset(
        'assets/Logo-02.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa_rounded,
              size: size * 0.5,
              color: AppColors.white,
            ),
          );
        },
      ),
    );
  }
}
