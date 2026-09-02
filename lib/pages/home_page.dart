import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../food.dart';
import '../food_provider.dart';
import '../pages/add_food_page.dart';
import '../services/food_flow.dart';
import '../sheets/edit_food_sheet.dart';
import '../theme/food_connect_theme.dart';
import '../theme/theme_mode_notifier.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/food_card.dart';
import '../widgets/food_filters.dart';
import '../widgets/history_stats.dart';
import '../widgets/home_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _editFood(Food food) async {
    final result = await showModalBottomSheet<EditFoodResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditFoodSheet(food: food),
    );

    if (!mounted || result == null) return;

    final provider = context.read<FoodProvider>();
    var ok = true;

    switch (result.action) {
      case 'save':
        ok = await provider.updateFood(
          food.copyWith(
            name: result.name,
            expirationDate: result.expirationDate,
            location: result.location,
          ),
        );
      case 'eaten':
        ok = await provider.markStatus(food.id, FoodStatus.eaten);
      case 'discarded':
        ok = await provider.markStatus(food.id, FoodStatus.discarded);
      case 'active':
        ok = await provider.markStatus(food.id, FoodStatus.active);
      case 'delete':
        ok = await provider.removeFoodById(food.id);
    }

    if (!mounted || ok) return;
    _showProviderError(provider);
  }

  void _showProviderError(FoodProvider provider) {
    final error = provider.lastError;
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    provider.clearError();
  }

  Future<void> _manualAddFromBar() async {
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
    final provider = context.watch<FoodProvider>();
    final themeNotifier = context.watch<ThemeModeNotifier>();
    final isDark = themeNotifier.isDark;

    return Scaffold(
      body: Column(
        children: [
          HomeHeader(
            provider: provider,
            isDark: isDark,
            onScanProduct: () => FoodFlow.scanProduct(context),
            onToggleTheme: () => themeNotifier.toggle(),
          ),
          if (!provider.showHistory)
            DashboardSummary(stats: provider.stats)
          else
            HistoryStats(stats: provider.stats),
          FoodFilters(
            provider: provider,
            searchController: _searchController,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                if (!provider.showHistory)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton.extended(
                        heroTag: 'list_add_fab',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddFoodPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Ajouter'),
                      ),
                    ),
                  ),
                Expanded(
                  child: provider.isLoading
                      ? const FoodListSkeleton()
                      : provider.visibleFoods.isEmpty
                          ? EmptyState(showHistory: provider.showHistory)
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 8, top: 2),
                              itemCount: provider.visibleFoods.length,
                              itemBuilder: (context, index) {
                                final food = provider.visibleFoods[index];
                                return FoodCard(
                                  food: food,
                                  onTap: () => _editFood(food),
                                  onSwipeEaten:
                                      food.status == FoodStatus.active
                                          ? () => provider.markStatus(
                                                food.id,
                                                FoodStatus.eaten,
                                              )
                                          : null,
                                  onSwipeDiscarded:
                                      food.status == FoodStatus.active
                                          ? () => provider.markStatus(
                                                food.id,
                                                FoodStatus.discarded,
                                              )
                                          : null,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          if (!provider.showHistory)
            _QuickAddBar(
              nameController: _nameController,
              dateController: _dateController,
              onScanProduct: () => FoodFlow.scanProduct(context),
              onChooseDlc: () => FoodFlow.chooseDlcAndFill(
                context: context,
                dateController: _dateController,
                nameController: _nameController,
              ),
              onAdd: _manualAddFromBar,
            ),
        ],
      ),
    );
  }
}

class _QuickAddBar extends StatelessWidget {
  const _QuickAddBar({
    required this.nameController,
    required this.dateController,
    required this.onScanProduct,
    required this.onChooseDlc,
    required this.onAdd,
  });

  final TextEditingController nameController;
  final TextEditingController dateController;
  final VoidCallback onScanProduct;
  final VoidCallback onChooseDlc;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? FcColorsDark.surface : FcColors.surface)
            .withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FoodConnectTheme.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: (isDark ? FcColorsDark.outline : FcColors.outline)
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Scanner produit',
                onPressed: onScanProduct,
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
              Expanded(
                flex: 5,
                child: TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nom',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: onChooseDlc,
                  decoration: const InputDecoration(
                    hintText: 'DLC',
                    isDense: true,
                    suffixIcon: Icon(Icons.document_scanner_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: FcColors.emerald,
                borderRadius: BorderRadius.circular(FoodConnectTheme.radiusSm),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius:
                      BorderRadius.circular(FoodConnectTheme.radiusSm),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.check_rounded, color: FcColors.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
