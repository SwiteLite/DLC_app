import 'package:flutter_test/flutter_test.dart';

import 'package:food_connect/database/app_database.dart';
import 'package:food_connect/food.dart';
import 'package:food_connect/food_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FoodProvider provider;

  setUp(() async {
    db = createTestDatabase();
    provider = FoodProvider(db);
    while (provider.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  tearDown(() async {
    await db.close();
  });

  test('removeFood attend la suppression async', () async {
    await provider.addFood(
      name: 'Yaourt',
      expirationDate: DateTime(2026, 12, 31),
    );

    expect(provider.foodsList, hasLength(1));
    final ok = await provider.removeFood(0);
    expect(ok, isTrue);
    expect(provider.foodsList, isEmpty);
  });

  test('stats comptent les aliments actifs urgents', () async {
    final today = DateTime.now();
    await provider.addFood(
      name: 'Lait',
      expirationDate: today.add(const Duration(days: 2)),
    );
    await provider.addFood(
      name: 'Fromage',
      expirationDate: today.add(const Duration(days: 20)),
    );

    // Attendre le chargement initial
    await Future<void>.delayed(Duration.zero);

    expect(provider.stats.activeCount, 2);
    expect(provider.stats.urgentCount, 1);
  });

  test('markStatus met à jour le statut', () async {
    await provider.addFood(
      name: 'Salade',
      expirationDate: DateTime(2026, 6, 1),
    );
    final id = provider.foodsList.first.id;

    final ok = await provider.markStatus(id, FoodStatus.eaten);
    expect(ok, isTrue);
    expect(provider.foodsList.first.status, FoodStatus.eaten);
  });
}
