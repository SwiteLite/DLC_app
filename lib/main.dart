import 'package:app_flutter/dlc_scanner_page.dart';
import 'package:app_flutter/food_provider.dart';
import 'package:app_flutter/open_food_facts_service.dart';
import 'package:app_flutter/product_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => FoodProvider(),
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

  Future<void> _applyExpirationDate(
    DateTime date, {
    required bool autoAdd,
  }) async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);
    foodProvider.dateController.text = DateFormat('dd/MM/yyyy').format(date);

    if (!autoAdd) return;
    if (foodProvider.textController.text.trim().isEmpty) return;

    foodProvider.addFood(
      foodProvider.textController.text,
      foodProvider.dateController.text,
    );
    foodProvider.textController.clear();
    foodProvider.dateController.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _chooseDlc({bool autoAdd = false}) async {
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
                subtitle: const Text('Lire la date sur l\'emballage'),
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
    await _applyExpirationDate(date, autoAdd: autoAdd);
  }

  Future<void> _scanProduct() async {
    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    final result = await Navigator.of(context).push<ProductLookupResult>(
      MaterialPageRoute(builder: (_) => const ProductScannerPage()),
    );

    if (!mounted || result == null) return;

    foodProvider.textController.text = result.displayName;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.found
              ? 'Produit trouvé : ${result.displayName}'
              : 'Produit non trouvé, saisissez le nom manuellement.',
        ),
      ),
    );

    if (!mounted) return;

    final date = await _scanDlcDate();
    if (!mounted || date == null) return;
    await _applyExpirationDate(date, autoAdd: true);
  }

  String _expirationLabel(DateTime expirationDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    final days = expiryOnly.difference(todayOnly).inDays;
    final dateText = DateFormat('dd/MM/yyyy').format(expirationDate);

    if (days < 0) {
      return 'Expiré depuis ${-days} jour${-days > 1 ? 's' : ''}, le : $dateText';
    }
    if (days == 0) return 'Expire aujourd\'hui ($dateText)';
    if (days == 1) return 'Expire demain ($dateText)';
    return 'Expire dans $days jours, le : $dateText';
  }

  Color _expirationColor(DateTime expirationDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    final days = expiryOnly.difference(todayOnly).inDays;

    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
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
            tooltip: 'Scanner un produit',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                if (foodProvider.foodsList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun aliment pour l\'instant.\nScannez un produit puis sa DLC.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: foodProvider.foodsList.length,
                  itemBuilder: (context, index) {
                    final food = foodProvider.foodsList[index];

                    return ListTile(
                      tileColor: Colors.grey[200],
                      title: Text(
                        food.name,
                        style: const TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        _expirationLabel(food.expirationDate),
                        style: TextStyle(
                          color: _expirationColor(food.expirationDate),
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black),
                        onPressed: () => foodProvider.removeFood(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
                  onPressed: () {
                    foodProvider.addFood(
                      foodProvider.textController.text,
                      foodProvider.dateController.text,
                    );
                    foodProvider.textController.clear();
                    foodProvider.dateController.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
