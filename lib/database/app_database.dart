import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../food.dart';

part 'app_database.g.dart';

const _dbName = 'food_connect';
const _legacyDbName = 'dlc_app';

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
  static const _dbRenamedFlag = 'food_connect_db_renamed_v1';

  static QueryExecutor _openConnection() {
    return driftDatabase(name: _dbName);
  }

  /// Copies the legacy `dlc_app` database file to `food_connect` once.
  static Future<void> migrateLegacyDatabaseFileIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dbRenamedFlag) == true) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final legacyPath = p.join(dir.path, '$_legacyDbName.sqlite');
      final newPath = p.join(dir.path, '$_dbName.sqlite');
      final legacyFile = File(legacyPath);
      final newFile = File(newPath);

      if (await legacyFile.exists() && !await newFile.exists()) {
        await legacyFile.copy(newPath);
      }
    } catch (_) {
      // Non-blocking: a fresh database will be created if migration fails.
    }

    await prefs.setBool(_dbRenamedFlag, true);
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

  Future<List<Food>> getFilteredFoods({
    required bool showHistory,
    String searchQuery = '',
    FoodUrgencyFilter urgencyFilter = FoodUrgencyFilter.all,
    FoodLocation? locationFilter,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final urgentLimit = today.add(const Duration(days: 3));

    final query = select(foods);

    if (showHistory) {
      query.where((t) => t.status.isNotIn([FoodStatus.active.name]));
    } else {
      query.where((t) => t.status.equals(FoodStatus.active.name));

      switch (urgencyFilter) {
        case FoodUrgencyFilter.all:
          break;
        case FoodUrgencyFilter.expired:
          query.where((t) => t.expirationDate.isSmallerThanValue(today));
        case FoodUrgencyFilter.urgent:
          query
            ..where((t) => t.expirationDate.isBiggerOrEqualValue(today))
            ..where((t) => t.expirationDate.isSmallerOrEqualValue(urgentLimit));
        case FoodUrgencyFilter.ok:
          query.where((t) => t.expirationDate.isBiggerThanValue(urgentLimit));
      }
    }

    if (locationFilter != null) {
      query.where((t) => t.location.equals(locationFilter.name));
    }

    final trimmedSearch = searchQuery.trim().toLowerCase();
    if (trimmedSearch.isNotEmpty) {
      query.where(
        (t) => t.name.lower().like('%$trimmedSearch%'),
      );
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.status),
      (t) => OrderingTerm.asc(t.expirationDate),
    ]);

    final rows = await query.get();
    var results = rows.map(toDomain).toList();

    if (trimmedSearch.isNotEmpty) {
      results = results.where((food) {
        final matchesName =
            food.name.toLowerCase().contains(trimmedSearch);
        final matchesLocation =
            food.location.label.toLowerCase().contains(trimmedSearch);
        return matchesName || matchesLocation;
      }).toList();
    }

    // Stats helper: week filter is computed in provider from full list.
    if (!showHistory && urgencyFilter == FoodUrgencyFilter.all) {
      // no-op; week stats use getAllFoods in provider
    }

    return results;
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
  }
}

/// In-memory database for tests.
AppDatabase createTestDatabase() => AppDatabase(NativeDatabase.memory());
