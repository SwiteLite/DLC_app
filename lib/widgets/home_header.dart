import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../food_provider.dart';
import '../theme/food_connect_theme.dart';
import 'round_icon_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.provider,
    required this.onScanProduct,
    required this.onToggleTheme,
    required this.isDark,
  });

  final FoodProvider provider;
  final VoidCallback onScanProduct;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final count = provider.visibleFoods.length;
    final subtitle = provider.showHistory
        ? 'Historique · $count aliment${count > 1 ? 's' : ''}'
        : 'Gardez vos DLC sous le pouce · $count';
    final ink = isDark ? FcColorsDark.ink : FcColors.ink;
    final muted = isDark ? FcColorsDark.inkMuted : FcColors.inkMuted;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A3D2E),
                  FcColorsDark.canvas,
                  const Color(0xFF2A2830),
                ]
              : const [
                  Color(0xFFD8F8E5),
                  Color(0xFFF3FBF6),
                  Color(0xFFFFF6E0),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [FcColors.emerald, FcColors.lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: FcColors.emerald.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: FcColors.ink,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'FoodConnect',
                          style: GoogleFonts.nunito(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: ink,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              RoundIconButton(
                tooltip: isDark ? 'Mode clair' : 'Mode sombre',
                icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onPressed: onToggleTheme,
              ),
              const SizedBox(width: 6),
              RoundIconButton(
                tooltip: provider.showHistory ? 'Voir actifs' : 'Historique',
                icon: provider.showHistory
                    ? Icons.inventory_2_rounded
                    : Icons.history_rounded,
                onPressed: () =>
                    provider.setShowHistory(!provider.showHistory),
              ),
              const SizedBox(width: 6),
              RoundIconButton(
                tooltip: 'Scanner un produit',
                icon: Icons.qr_code_scanner_rounded,
                accent: true,
                onPressed: onScanProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
