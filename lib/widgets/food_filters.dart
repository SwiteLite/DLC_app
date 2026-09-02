import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../food.dart';
import '../food_provider.dart';
import '../theme/food_connect_theme.dart';

class FoodFilters extends StatelessWidget {
  const FoodFilters({
    super.key,
    required this.provider,
    required this.searchController,
  });

  final FoodProvider provider;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Rechercher un aliment…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: provider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        searchController.clear();
                        provider.setSearchQuery('');
                      },
                    ),
              isDense: true,
            ),
          ),
          if (!provider.showHistory) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FoodUrgencyFilter.values.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter.label),
                      selected: provider.urgencyFilter == filter,
                      showCheckmark: false,
                      onSelected: (_) => provider.setUrgencyFilter(filter),
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
                    selected: provider.locationFilter == null,
                    showCheckmark: false,
                    onSelected: (_) => provider.setLocationFilter(null),
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
                      selected: provider.locationFilter == location,
                      showCheckmark: false,
                      onSelected: (_) => provider.setLocationFilter(
                        provider.locationFilter == location ? null : location,
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
}

class FoodListSkeleton extends StatelessWidget {
  const FoodListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? FcColorsDark.surfaceSoft : FcColors.surfaceSoft;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(FoodConnectTheme.radiusMd),
            ),
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.showHistory});

  final bool showHistory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? FcColorsDark.inkMuted : FcColors.inkMuted;

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
                showHistory ? Icons.history_rounded : Icons.ramen_dining_rounded,
                size: 42,
                color: FcColors.ink,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              showHistory ? 'Historique vide' : 'Votre frigo respire',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              showHistory
                  ? 'Les aliments consommés ou jetés apparaîtront ici.'
                  : 'Scannez un produit ou ajoutez un aliment pour commencer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: muted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
