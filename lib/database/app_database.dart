import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../food.dart';

part 'app_database.g.dart';

@DataClassName('FoodRow')
class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get expirationDate => dateTime()();
  DateTimeColumn get dateAdded => dateTime()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get location =>
      text().withDefault(const Constant('unspecified'))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get barcode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Foods])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static const _prefsKey = 'foodsList';
  static const _migratedFlag = 'drift_migrated_v1';

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'dlc_app');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );

  Food toDomain(FoodRow row) {
    return Food(
      id: row.id,
      name: row.name,
      expirationDate: row.expirationDate,
      dateAdded: row.dateAdded,
      status: FoodStatus.fromName(row.status),
      location: FoodLocation.fromName(row.location),
      imageUrl: row.imageUrl,
      barcode: row.barcode,
    );
  }

  FoodsCompanion toCompanion(Food food) {
    return FoodsCompanion.insert(
      id: food.id,
      name: food.name,
      expirationDate: food.expirationDate,
      dateAdded: food.dateAdded,
      status: Value(food.status.name),
      location: Value(food.location.name),
      imageUrl: Value(food.imageUrl),
      barcode: Value(food.barcode),
    );
  }

  Future<List<Food>> getAllFoods() async {
    final rows = await (select(foods)
          ..orderBy([
            (t) => OrderingTerm(expression: t.status),
            (t) => OrderingTerm.asc(t.expirationDate),
          ]))
        .get();
    return rows.map(toDomain).toList();
  }

  Future<void> upsertFood(Food food) async {
    await into(foods).insertOnConflictUpdate(toCompanion(food));
  }

  Future<void> deleteFood(String id) async {
    await (delete(foods)..where((t) => t.id.equals(id))).go();
  }

  /// One-shot import of the old SharedPreferences JSON list.
  Future<void> migrateFromSharedPreferencesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedFlag) == true) return;

    final foodsJson = prefs.getString(_prefsKey);
    if (foodsJson != null && foodsJson.isNotEmpty) {
      final decoded = jsonDecode(foodsJson) as List<dynamic>;
      final foodsToInsert = decoded
          .map((item) => Food.fromJson(item as Map<String, dynamic>))
          .toList();

      await batch((batch) {
        batch.insertAll(
          foods,
          foodsToInsert.map(toCompanion).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    }

    await prefs.setBool(_migratedFlag, true);
    // Keep the old JSON as backup; can be removed later once migration is trusted.
  }
}
