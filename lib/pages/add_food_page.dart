import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../food_confirm_page.dart';
import '../services/food_flow.dart';
import '../theme/food_connect_theme.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _manualAdd() async {
    await FoodFlow.manualAdd(
      context: context,
      name: _nameController.text,
      dateText: _dateController.text,
    );
    if (!mounted) return;
    _nameController.clear();
    _dateController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? FcColorsDark.inkMuted : FcColors.inkMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un aliment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choisissez comment ajouter',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scanner un produit',
            subtitle: 'Code-barres + Open Food Facts',
            color: FcColors.emerald,
            onTap: () => FoodFlow.scanProduct(context),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.document_scanner_rounded,
            title: 'Scanner une DLC',
            subtitle: 'Lecture OCR de la date',
            color: FcColors.jasmine,
            onTap: () async {
              final date = await FoodFlow.scanDlcDate(context);
              if (!context.mounted || date == null) return;
              await FoodFlow.openConfirmAndAdd(
                context,
                FoodDraft(
                  name: _nameController.text.trim().isEmpty
                      ? 'Nouvel aliment'
                      : _nameController.text.trim(),
                  expirationDate: date,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Ou saisie manuelle',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'aliment',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'DLC',
              suffixIcon: Icon(Icons.calendar_month_rounded),
            ),
            onTap: () => FoodFlow.chooseDlcAndFill(
              context: context,
              dateController: _dateController,
              nameController: _nameController,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _manualAdd,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Color.lerp(
        color,
        isDark ? FcColorsDark.surface : Colors.white,
        0.78,
      ),
      borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? FcColorsDark.inkMuted
                            : FcColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
