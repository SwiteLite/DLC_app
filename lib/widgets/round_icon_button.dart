import 'package:flutter/material.dart';

import '../theme/food_connect_theme.dart';

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = accent
        ? FcColors.emerald
        : (isDark ? FcColorsDark.surface : FcColors.surface);
    final fg = isDark ? FcColorsDark.ink : FcColors.ink;

    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
