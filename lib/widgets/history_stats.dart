import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/food_stats.dart';
import '../theme/food_connect_theme.dart';

class HistoryStats extends StatelessWidget {
  const HistoryStats({super.key, required this.stats});

  final FoodStats stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? FcColorsDark.ink : FcColors.ink;
    final muted = isDark ? FcColorsDark.inkMuted : FcColors.inkMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _HistoryCard(
              label: 'Consommés',
              value: stats.eatenCount,
              color: FcColors.emerald,
              ink: ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HistoryCard(
              label: 'Jetés',
              value: stats.discardedCount,
              color: FcColors.salmon,
              ink: ink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HistoryCard(
              label: 'Total historique',
              value: stats.historyTotal,
              color: FcColors.jasmine,
              ink: ink,
              subtitleStyle: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.ink,
    this.subtitleStyle,
  });

  final String label;
  final int value;
  final Color color;
  final Color ink;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.lerp(
          color,
          Theme.of(context).brightness == Brightness.dark
              ? FcColorsDark.surface
              : Colors.white,
          0.85,
        ),
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: ink,
            ),
          ),
          Text(
            label,
            style: subtitleStyle ??
                GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ink.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}
