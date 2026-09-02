import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../food.dart';
import '../theme/food_connect_theme.dart';

class EditFoodResult {
  const EditFoodResult({
    required this.action,
    required this.name,
    required this.expirationDate,
    required this.location,
  });

  final String action;
  final String name;
  final DateTime expirationDate;
  final FoodLocation location;
}

class EditFoodSheet extends StatefulWidget {
  const EditFoodSheet({super.key, required this.food});

  final Food food;

  @override
  State<EditFoodSheet> createState() => _EditFoodSheetState();
}

class _EditFoodSheetState extends State<EditFoodSheet> {
  late final TextEditingController _nameController;
  late DateTime _expiration;
  late FoodLocation _location;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.food.name);
    _expiration = widget.food.expirationDate;
    _location = widget.food.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pop(String action) {
    final name = _nameController.text.trim();
    Navigator.of(context).pop(
      EditFoodResult(
        action: action,
        name: name.isEmpty ? widget.food.name : name,
        expirationDate: _expiration,
        location: _location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? FcColorsDark.inkMuted : FcColors.inkMuted;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier l\'aliment',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 16),
              Text(
                'Lieu de stockage',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FoodLocation.values.map((location) {
                  return ChoiceChip(
                    avatar: Icon(location.icon, size: 18),
                    label: Text(location.label),
                    selected: _location == location,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _location = location),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'DLC',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_expiration),
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_rounded),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiration,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && mounted) {
                      setState(() => _expiration = picked);
                    }
                  },
                ),
              ),
              if (widget.food.status == FoodStatus.active) ...[
                _ActionTile(
                  icon: Icons.restaurant_rounded,
                  label: 'Marquer comme consommé',
                  color: FcColors.emerald,
                  onTap: () => _pop('eaten'),
                ),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Marquer comme jeté',
                  color: FcColors.salmon,
                  onTap: () => _pop('discarded'),
                ),
              ] else
                _ActionTile(
                  icon: Icons.undo_rounded,
                  label: 'Remettre en actif',
                  color: FcColors.jasmine,
                  onTap: () => _pop('active'),
                ),
              _ActionTile(
                icon: Icons.delete_forever_rounded,
                label: 'Supprimer définitivement',
                color: FcColors.coral,
                onTap: () => _pop('delete'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _pop('save'),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? FcColorsDark.ink : FcColors.ink;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Color.lerp(
          color,
          isDark ? FcColorsDark.surface : Colors.white,
          0.82,
        ),
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusSm),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
