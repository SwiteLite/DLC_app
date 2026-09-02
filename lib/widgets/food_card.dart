import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../food.dart';
import '../theme/food_connect_theme.dart';
import '../utils/food_labels.dart';
import 'food_avatar.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.food,
    required this.onTap,
    this.onSwipeEaten,
    this.onSwipeDiscarded,
  });

  final Food food;
  final VoidCallback onTap;
  final VoidCallback? onSwipeEaten;
  final VoidCallback? onSwipeDiscarded;

  @override
  Widget build(BuildContext context) {
    final days = food.daysUntilExpiration();
    final active = food.status == FoodStatus.active;
    final accent = FoodConnectTheme.urgencyColor(days, active: active);
    final soft = FoodConnectTheme.urgencySoft(days, active: active);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? FcColorsDark.surface : FcColors.surface;
    final ink = isDark ? FcColorsDark.ink : FcColors.ink;
    final outline = isDark ? FcColorsDark.outline : FcColors.outline;

    final card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
              border: Border.all(color: outline.withValues(alpha: 0.55)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [soft, surface],
                stops: const [0, 0.28],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  FoodAvatar(food: food, accent: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ink,
                            decoration:
                                active ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          expirationLabel(food),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: (isDark ? FcColorsDark.inkMuted : FcColors.inkMuted)
                        .withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!active || onSwipeEaten == null || onSwipeDiscarded == null) {
      return card;
    }

    return Dismissible(
      key: ValueKey(food.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          onSwipeEaten!();
        } else {
          onSwipeDiscarded!();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 28),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: FcColors.emerald.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
        ),
        child: const Icon(Icons.restaurant_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: FcColors.salmon.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: card,
    );
  }
}
