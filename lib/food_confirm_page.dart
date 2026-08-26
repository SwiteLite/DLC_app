import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'dlc_scanner_page.dart';
import 'food.dart';
import 'theme/food_connect_theme.dart';

class FoodDraft {
  final String name;
  final DateTime expirationDate;
  final FoodLocation location;
  final String? imageUrl;
  final String? barcode;

  const FoodDraft({
    required this.name,
    required this.expirationDate,
    this.location = FoodLocation.unspecified,
    this.imageUrl,
    this.barcode,
  });
}

class FoodConfirmPage extends StatefulWidget {
  const FoodConfirmPage({super.key, required this.draft});

  final FoodDraft draft;

  @override
  State<FoodConfirmPage> createState() => _FoodConfirmPageState();
}

class _FoodConfirmPageState extends State<FoodConfirmPage> {
  late final TextEditingController _nameController;
  late DateTime _expirationDate;
  late FoodLocation _location;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name);
    _expirationDate = widget.draft.expirationDate;
    _location = widget.draft.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Modifier la DLC',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  Future<void> _scanDlc() async {
    final scanned = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => const DlcScannerPage()),
    );
    if (scanned != null && mounted) {
      setState(() => _expirationDate = scanned);
    }
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez un nom d\'aliment.')),
      );
      return;
    }

    Navigator.of(context).pop(
      FoodDraft(
        name: name,
        expirationDate: _expirationDate,
        location: _location,
        imageUrl: widget.draft.imageUrl,
        barcode: widget.draft.barcode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd/MM/yyyy').format(_expirationDate);
    final days = _expirationDate
        .difference(DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ))
        .inDays;
    final urgency = FoodConnectTheme.urgencyColor(days);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmer l\'ajout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (widget.draft.imageUrl != null &&
              widget.draft.imageUrl!.isNotEmpty) ...[
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: FcColors.emerald.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(FoodConnectTheme.radiusMd),
                  child: Image.network(
                    widget.draft.imageUrl!,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      width: 120,
                      color: FcColors.surfaceSoft,
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        size: 48,
                        color: FcColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom du produit',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lieu de stockage',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: FcColors.inkMuted,
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FoodConnectTheme.urgencySoft(days),
              borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
              border: Border.all(color: urgency.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date limite (DLC)',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: FcColors.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: urgency,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Scanner la DLC',
                  onPressed: _scanDlc,
                  icon: const Icon(Icons.document_scanner_rounded),
                ),
                IconButton(
                  tooltip: 'Choisir une date',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
              ],
            ),
          ),
          if (widget.draft.barcode != null) ...[
            const SizedBox(height: 12),
            Text(
              'Code : ${widget.draft.barcode}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FcColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Ajouter à ma liste'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
