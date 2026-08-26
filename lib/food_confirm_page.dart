import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dlc_scanner_page.dart';
import 'food.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmer l\'ajout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.draft.imageUrl != null &&
              widget.draft.imageUrl!.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.draft.imageUrl!,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    size: 64,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom du produit',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Lieu de stockage'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FoodLocation.values.map((location) {
              return ChoiceChip(
                avatar: Icon(location.icon, size: 18),
                label: Text(location.label),
                selected: _location == location,
                onSelected: (_) => setState(() => _location = location),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date limite (DLC)'),
            subtitle: Text(
              dateLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Scanner la DLC',
                  onPressed: _scanDlc,
                  icon: const Icon(Icons.document_scanner),
                ),
                IconButton(
                  tooltip: 'Choisir une date',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
          ),
          if (widget.draft.barcode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Code : ${widget.draft.barcode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check),
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
