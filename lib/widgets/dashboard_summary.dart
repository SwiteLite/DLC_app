import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/food_stats.dart';
import '../theme/food_connect_theme.dart';

class DashboardSummary extends StatelessWidget {
  const DashboardSummary({super.key, required this.stats});

  final FoodStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Actifs',
              value: '${stats.activeCount}',
              color: FcColors.emerald,
              icon: Icons.inventory_2_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Urgents',
              value: '${stats.urgentCount}',
              color: FcColors.coral,
              icon: Icons.warning_amber_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Cette semaine',
              value: '${stats.expiringThisWeekCount}',
              color: FcColors.salmon,
              icon: Icons.calendar_today_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Color.lerp(color, isDark ? FcColorsDark.surface : Colors.white, 0.82)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? FcColorsDark.ink : FcColors.ink,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? FcColorsDark.inkMuted : FcColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
