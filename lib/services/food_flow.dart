import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../dlc_scanner_page.dart';
import '../food_confirm_page.dart';
import '../food_provider.dart';
import '../open_food_facts_service.dart';
import '../product_scanner_page.dart';

class FoodFlow {
  FoodFlow._();

  static Future<DateTime?> pickDateManually(
    BuildContext context, {
    DateTime? initialDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      helpText: 'Choisir la DLC',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
  }

  static Future<DateTime?> scanDlcDate(BuildContext context) {
    return Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => const DlcScannerPage()),
    );
  }

  static Future<void> openConfirmAndAdd(
    BuildContext context,
    FoodDraft draft,
  ) async {
    final confirmed = await Navigator.of(context).push<FoodDraft>(
      MaterialPageRoute(builder: (_) => FoodConfirmPage(draft: draft)),
    );
    if (!context.mounted || confirmed == null) return;

    final provider = context.read<FoodProvider>();
    final ok = await provider.addFood(
      name: confirmed.name,
      expirationDate: confirmed.expirationDate,
      location: confirmed.location,
      imageUrl: confirmed.imageUrl,
      barcode: confirmed.barcode,
    );
    if (!context.mounted) return;

    if (!ok && provider.lastError != null) {
      _showError(context, provider.lastError!);
      return;
    }

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${confirmed.name} ajouté — rappels planifiés.')),
    );
  }

  static Future<void> chooseDlcAndFill({
    required BuildContext context,
    required TextEditingController dateController,
    TextEditingController? nameController,
    bool autoAdd = false,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Comment ajouter la DLC ?',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.document_scanner_rounded),
                  title: const Text('Scanner la DLC'),
                  subtitle: const Text('Lecture automatique de la date'),
                  onTap: () => Navigator.pop(context, 'scan'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Choisir manuellement'),
                  subtitle: const Text('Sélectionner dans le calendrier'),
                  onTap: () => Navigator.pop(context, 'manual'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || choice == null) return;

    final date = choice == 'scan'
        ? await scanDlcDate(context)
        : await pickDateManually(context);

    if (!context.mounted || date == null) return;

    dateController.text = DateFormat('dd/MM/yyyy').format(date);

    if (!autoAdd) return;
    final name = nameController?.text.trim() ?? '';
    if (name.isEmpty) return;

    await openConfirmAndAdd(
      context,
      FoodDraft(name: name, expirationDate: date),
    );
  }

  static Future<void> scanProduct(BuildContext context) async {
    final result = await Navigator.of(context).push<ProductLookupResult>(
      MaterialPageRoute(builder: (_) => const ProductScannerPage()),
    );

    if (!context.mounted || result == null) return;
    await _handleProductResult(context, result);
  }

  static Future<void> _handleProductResult(
    BuildContext context,
    ProductLookupResult result,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.displayName,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Comment définir la DLC ?',
                  style: GoogleFonts.nunito(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.document_scanner_rounded),
                  title: const Text('Scanner la DLC'),
                  onTap: () => Navigator.pop(context, 'scan'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text('Choisir au calendrier'),
                  onTap: () => Navigator.pop(context, 'manual'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: const Text('Plus tard'),
                  subtitle: const Text('Définir la date à l\'étape suivante'),
                  onTap: () => Navigator.pop(context, 'later'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted || choice == null) return;

    final draftBase = FoodDraft(
      name: result.displayName,
      imageUrl: result.imageUrl,
      barcode: result.barcode,
      expirationDate: DateTime.now(),
    );

    switch (choice) {
      case 'scan':
        final date = await scanDlcDate(context);
        if (!context.mounted || date == null) return;
        await openConfirmAndAdd(
          context,
          FoodDraft(
            name: draftBase.name,
            expirationDate: date,
            imageUrl: draftBase.imageUrl,
            barcode: draftBase.barcode,
          ),
        );
      case 'manual':
        final date = await pickDateManually(context);
        if (!context.mounted || date == null) return;
        await openConfirmAndAdd(
          context,
          FoodDraft(
            name: draftBase.name,
            expirationDate: date,
            imageUrl: draftBase.imageUrl,
            barcode: draftBase.barcode,
          ),
        );
      case 'later':
        await openConfirmAndAdd(context, draftBase);
    }
  }

  static Future<void> manualAdd({
    required BuildContext context,
    required String name,
    required String dateText,
  }) async {
    if (name.trim().isEmpty || dateText.trim().isEmpty) {
      _showError(context, 'Renseignez le nom et la DLC.');
      return;
    }

    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateText);
      await openConfirmAndAdd(
        context,
        FoodDraft(name: name.trim(), expirationDate: date),
      );
    } catch (_) {
      _showError(context, 'Format de date invalide (jj/mm/aaaa).');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
