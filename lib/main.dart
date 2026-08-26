import 'package:app_flutter/database/app_database.dart';
import 'package:app_flutter/dlc_scanner_page.dart';
import 'package:app_flutter/food.dart';
import 'package:app_flutter/food_confirm_page.dart';
import 'package:app_flutter/food_provider.dart';
import 'package:app_flutter/notification_service.dart';
import 'package:app_flutter/open_food_facts_service.dart';
import 'package:app_flutter/product_scanner_page.dart';
import 'package:app_flutter/theme/food_connect_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  final database = AppDatabase();
  await database.migrateFromSharedPreferencesIfNeeded();

  runApp(
    ChangeNotifierProvider(
      create: (context) => FoodProvider(database),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodConnect',
      theme: FoodConnectTheme.light(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
      ],
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<DateTime?> _pickDateManually({DateTime? initialDate}) async {
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

  Future<DateTime?> _scanDlcDate() async {
    return Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => const DlcScannerPage()),
    );
  }

  Future<void> _openConfirmAndAdd(FoodDraft draft) async {
    final confirmed = await Navigator.of(context).push<FoodDraft>(
      MaterialPageRoute(builder: (_) => FoodConfirmPage(draft: draft)),
    );
    if (!mounted || confirmed == null) return;

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    await foodProvider.addFood(
      name: confirmed.name,
      expirationDate: confirmed.expirationDate,
      location: confirmed.location,
      imageUrl: confirmed.imageUrl,
      barcode: confirmed.barcode,
    );
    foodProvider.textController.clear();
    foodProvider.dateController.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${confirmed.name} ajouté — rappels planifiés.')),
    );
  }

  Future<void> _chooseDlc({bool autoAdd = false}) async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

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

    if (!mounted || choice == null) return;

    final DateTime? date = choice == 'scan'
        ? await _scanDlcDate()
        : await _pickDateManually();

    if (!mounted || date == null) return;

    foodProvider.dateController.text = DateFormat('dd/MM/yyyy').format(date);

    if (!autoAdd) return;
    if (foodProvider.textController.text.trim().isEmpty) return;

    await _openConfirmAndAdd(
      FoodDraft(
        name: foodProvider.textController.text.trim(),
        expirationDate: date,
      ),
    );
  }

  Future<void> _scanProduct() async {
    final result = await Navigator.of(context).push<ProductLookupResult>(
      MaterialPageRoute(builder: (_) => const ProductScannerPage()),
    );

    if (!mounted || result == null) return;

    final date = await _scanDlcDate();
    if (!mounted || date == null) return;

    await _openConfirmAndAdd(
      FoodDraft(
        name: result.displayName,
        expirationDate: date,
        imageUrl: result.imageUrl,
        barcode: result.barcode,
      ),
    );
  }

  Future<void> _manualAdd() async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    final name = foodProvider.textController.text.trim();
    final dateText = foodProvider.dateController.text.trim();

    if (name.isEmpty || dateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renseignez le nom et la DLC.')),
      );
      return;
    }

    final date = DateFormat('dd/MM/yyyy').parse(dateText);
    await _openConfirmAndAdd(FoodDraft(name: name, expirationDate: date));
  }

  Future<void> _editFood(Food food) async {
    final result = await showModalBottomSheet<_EditFoodResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditFoodSheet(food: food),
    );

    if (!mounted || result == null) return;

    final provider = Provider.of<FoodProvider>(context, listen: false);

    switch (result.action) {
      case 'save':
        await provider.updateFood(
          food.copyWith(
            name: result.name,
            expirationDate: result.expirationDate,
            location: result.location,
          ),
        );
      case 'eaten':
        await provider.markStatus(food.id, FoodStatus.eaten);
      case 'discarded':
        await provider.markStatus(food.id, FoodStatus.discarded);
      case 'active':
        await provider.markStatus(food.id, FoodStatus.active);
      case 'delete':
        await provider.removeFoodById(food.id);
    }
  }

  String _expirationLabel(Food food) {
    final locationPrefix = food.location == FoodLocation.unspecified
        ? ''
        : '${food.location.label} · ';

    if (food.status != FoodStatus.active) {
      return '$locationPrefix${food.status.label} — DLC ${DateFormat('dd/MM/yyyy').format(food.expirationDate)}';
    }

    final days = food.daysUntilExpiration();
    final dateText = DateFormat('dd/MM/yyyy').format(food.expirationDate);

    if (days < 0) {
      return '$locationPrefix'
          'Expiré depuis ${-days} jour${-days > 1 ? 's' : ''}, le : $dateText';
    }
    if (days == 0) return '$locationPrefix' 'Expire aujourd\'hui ($dateText)';
    if (days == 1) return '$locationPrefix' 'Expire demain ($dateText)';
    return '$locationPrefix' 'Expire dans $days jours, le : $dateText';
  }

  Widget _buildHeader(FoodProvider foodProvider) {
    final count = foodProvider.visibleFoods.length;
    final subtitle = foodProvider.showHistory
        ? 'Historique · $count aliment${count > 1 ? 's' : ''}'
        : 'Gardez vos DLC sous le pouce · $count';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
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
                            color: FcColors.ink,
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
                        color: FcColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                tooltip: foodProvider.showHistory ? 'Voir actifs' : 'Historique',
                icon: foodProvider.showHistory
                    ? Icons.inventory_2_rounded
                    : Icons.history_rounded,
                onPressed: () =>
                    foodProvider.setShowHistory(!foodProvider.showHistory),
              ),
              const SizedBox(width: 6),
              _RoundIconButton(
                tooltip: 'Scanner un produit',
                icon: Icons.qr_code_scanner_rounded,
                accent: true,
                onPressed: _scanProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(FoodProvider foodProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: foodProvider.searchController,
            onChanged: foodProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Rechercher un aliment…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: foodProvider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        foodProvider.searchController.clear();
                        foodProvider.setSearchQuery('');
                      },
                    ),
              isDense: true,
            ),
          ),
          if (!foodProvider.showHistory) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FoodUrgencyFilter.values.map((filter) {
                  final selected = foodProvider.urgencyFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: selected,
                      showCheckmark: false,
                      onSelected: (_) => foodProvider.setUrgencyFilter(filter),
                      selectedColor: switch (filter) {
                        FoodUrgencyFilter.urgent => FcColors.salmon,
                        FoodUrgencyFilter.expired => FcColors.coral,
                        FoodUrgencyFilter.ok => FcColors.lightGreen,
                        FoodUrgencyFilter.all => FcColors.emerald,
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tous lieux'),
                    selected: foodProvider.locationFilter == null,
                    showCheckmark: false,
                    onSelected: (_) => foodProvider.setLocationFilter(null),
                  ),
                ),
                ...FoodLocation.values
                    .where((l) => l != FoodLocation.unspecified)
                    .map((location) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(location.icon, size: 16),
                      label: Text(location.label),
                      selected: foodProvider.locationFilter == location,
                      showCheckmark: false,
                      onSelected: (_) => foodProvider.setLocationFilter(
                        foodProvider.locationFilter == location
                            ? null
                            : location,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    final days = food.daysUntilExpiration();
    final active = food.status == FoodStatus.active;
    final accent = FoodConnectTheme.urgencyColor(days, active: active);
    final soft = FoodConnectTheme.urgencySoft(days, active: active);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: FcColors.surface,
        elevation: 0,
        shadowColor: FcColors.ink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
        child: InkWell(
          onTap: () => _editFood(food),
          borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
              border: Border.all(color: FcColors.outline.withValues(alpha: 0.55)),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [soft, FcColors.surface],
                stops: const [0, 0.28],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  _FoodAvatar(food: food, accent: accent),
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
                            color: FcColors.ink,
                            decoration: active
                                ? null
                                : TextDecoration.lineThrough,
                            decorationColor: FcColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _expirationLabel(food),
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
                    color: FcColors.inkMuted.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(FoodProvider foodProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FcColors.lightGreen, FcColors.jasmine],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                foodProvider.showHistory
                    ? Icons.history_rounded
                    : Icons.ramen_dining_rounded,
                size: 42,
                color: FcColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              foodProvider.showHistory
                  ? 'Historique vide'
                  : 'Votre frigo respire',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              foodProvider.showHistory
                  ? 'Les aliments consommés ou jetés apparaîtront ici.'
                  : 'Scannez un produit ou ajoutez un aliment pour commencer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: FcColors.inkMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBar(FoodProvider foodProvider) {
    return Container(
      decoration: BoxDecoration(
        color: FcColors.surface.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FoodConnectTheme.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: FcColors.ink.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(color: FcColors.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Row(
            children: [
              _RoundIconButton(
                tooltip: 'Scanner produit',
                icon: Icons.qr_code_scanner_rounded,
                accent: true,
                onPressed: _scanProduct,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: foodProvider.textController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nom de l\'aliment',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: foodProvider.dateController,
                  decoration: const InputDecoration(
                    hintText: 'DLC',
                    isDense: true,
                    suffixIcon: Icon(Icons.document_scanner_rounded, size: 18),
                  ),
                  readOnly: true,
                  onTap: () => _chooseDlc(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: FcColors.emerald,
                borderRadius: BorderRadius.circular(FoodConnectTheme.radiusSm),
                child: InkWell(
                  onTap: _manualAdd,
                  borderRadius:
                      BorderRadius.circular(FoodConnectTheme.radiusSm),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add_rounded, color: FcColors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(foodProvider),
          _buildFilters(foodProvider),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                final foods = foodProvider.visibleFoods;
                if (foods.isEmpty) {
                  return _buildEmptyState(foodProvider);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8, top: 2),
                  itemCount: foods.length,
                  itemBuilder: (context, index) =>
                      _buildFoodCard(foods[index]),
                );
              },
            ),
          ),
          if (!foodProvider.showHistory) _buildAddBar(foodProvider),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
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
    final button = Material(
      color: accent ? FcColors.emerald : FcColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: FcColors.ink),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _FoodAvatar extends StatelessWidget {
  const _FoodAvatar({required this.food, required this.accent});

  final Food food;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    if (food.imageUrl != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          food.imageUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(radius),
        ),
      );
    }

    return _fallback(radius);
  }

  Widget _fallback(BorderRadius radius) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Color.lerp(accent, Colors.white, 0.55),
        borderRadius: radius,
      ),
      child: Icon(food.location.icon, color: FcColors.ink, size: 24),
    );
  }
}

class _EditFoodResult {
  final String action;
  final String name;
  final DateTime expirationDate;
  final FoodLocation location;

  const _EditFoodResult({
    required this.action,
    required this.name,
    required this.expirationDate,
    required this.location,
  });
}

class _EditFoodSheet extends StatefulWidget {
  const _EditFoodSheet({required this.food});

  final Food food;

  @override
  State<_EditFoodSheet> createState() => _EditFoodSheetState();
}

class _EditFoodSheetState extends State<_EditFoodSheet> {
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
      _EditFoodResult(
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
                decoration: const InputDecoration(
                  labelText: 'Nom',
                ),
              ),
              const SizedBox(height: 16),
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
                    color: FcColors.inkMuted,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Color.lerp(color, Colors.white, 0.82),
        borderRadius: BorderRadius.circular(FoodConnectTheme.radiusSm),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: FcColors.ink,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
