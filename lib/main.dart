import 'package:app_flutter/database/app_database.dart';
import 'package:app_flutter/dlc_scanner_page.dart';
import 'package:app_flutter/food.dart';
import 'package:app_flutter/food_confirm_page.dart';
import 'package:app_flutter/food_provider.dart';
import 'package:app_flutter/notification_service.dart';
import 'package:app_flutter/open_food_facts_service.dart';
import 'package:app_flutter/product_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      title: 'DLC APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
      ],
      home: const MyHomePage(title: 'DLC APP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner),
                title: const Text('Scanner la DLC'),
                onTap: () => Navigator.pop(context, 'scan'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Choisir manuellement'),
                onTap: () => Navigator.pop(context, 'manual'),
              ),
            ],
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

  Color _expirationColor(Food food) {
    if (food.status != FoodStatus.active) return Colors.grey;

    final days = food.daysUntilExpiration();

    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  Widget _buildFilters(FoodProvider foodProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          TextField(
            controller: foodProvider.searchController,
            onChanged: foodProvider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Rechercher un aliment…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: foodProvider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        foodProvider.searchController.clear();
                        foodProvider.setSearchQuery('');
                      },
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (!foodProvider.showHistory) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FoodUrgencyFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: foodProvider.urgencyFilter == filter,
                      onSelected: (_) => foodProvider.setUrgencyFilter(filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tous lieux'),
                    selected: foodProvider.locationFilter == null,
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

  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: foodProvider.showHistory ? 'Voir actifs' : 'Historique',
            icon: Icon(
              foodProvider.showHistory ? Icons.inventory_2 : Icons.history,
            ),
            onPressed: () =>
                foodProvider.setShowHistory(!foodProvider.showHistory),
          ),
          IconButton(
            tooltip: 'Scanner un produit',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(foodProvider),
          Expanded(
            child: Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                final foods = foodProvider.visibleFoods;
                if (foods.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        foodProvider.showHistory
                            ? 'Aucun aliment dans l\'historique.'
                            : 'Aucun résultat.\nModifiez les filtres ou ajoutez un aliment.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];

                    return ListTile(
                      tileColor: Colors.grey[200],
                      leading: food.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                food.imageUrl!,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(food.location.icon),
                              ),
                            )
                          : Icon(food.location.icon),
                      title: Text(
                        food.name,
                        style: TextStyle(
                          color: Colors.black,
                          decoration: food.status == FoodStatus.active
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        _expirationLabel(food),
                        style: TextStyle(color: _expirationColor(food)),
                      ),
                      trailing: const Icon(Icons.more_vert),
                      onTap: () => _editFood(food),
                    );
                  },
                );
              },
            ),
          ),
          if (!foodProvider.showHistory)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Scanner produit',
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _scanProduct,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: foodProvider.textController,
                      decoration: const InputDecoration(
                        hintText: 'Nom de l\'aliment',
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.document_scanner, size: 20),
                      ),
                      readOnly: true,
                      onTap: () => _chooseDlc(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _manualAdd,
                  ),
                ],
              ),
            ),
        ],
      ),
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
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomInset + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier l\'aliment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('DLC'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_expiration)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
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
                ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: const Text('Marquer comme consommé'),
                  onTap: () => _pop('eaten'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Marquer comme jeté'),
                  onTap: () => _pop('discarded'),
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('Remettre en actif'),
                  onTap: () => _pop('active'),
                ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Supprimer définitivement'),
                onTap: () => _pop('delete'),
              ),
              const SizedBox(height: 8),
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
