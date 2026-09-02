import 'package:flutter/material.dart';

import '../food.dart';
import '../theme/food_connect_theme.dart';

class FoodAvatar extends StatelessWidget {
  const FoodAvatar({super.key, required this.food, required this.accent});

  final Food food;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? FcColorsDark.ink : FcColors.ink;

    if (food.imageUrl != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          food.imageUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(radius, ink, isDark),
        ),
      );
    }

    return _fallback(radius, ink, isDark);
  }

  Widget _fallback(BorderRadius radius, Color ink, bool isDark) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, isDark ? 0.35 : 0.55),
        borderRadius: radius,
      ),
      child: Icon(food.location.icon, color: ink, size: 24),
    );
  }
}
