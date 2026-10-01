import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand mark: a teal tile with a shopping bag and an amber "neighbour" dot.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: size * 0.52,
            ),
          ),
          Positioned(
            right: -size * 0.06,
            top: -size * 0.06,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: size * 0.04,
                ),
              ),
              child: Icon(Icons.home_rounded,
                  size: size * 0.17, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
