import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'database/app_database.dart';
import 'food.dart';
import 'models/food_stats.dart';
import 'notification_service.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider(this._db) {
    _loadFoodsList();
  }

  final AppDatabase _db;

  List<Food> _foodsList = [];
  List<Food> _visibleFoods = [];
  bool _showHistory = false;
  String _searchQuery = '';
  FoodUrgencyFilter _urgencyFilter = FoodUrgencyFilter.all;
  FoodLocation? _locationFilter;
  bool _loading = true;
  String? _lastError;

  List<Food> get foodsList => _foodsList;
  List<Food> get visibleFoods => _visibleFoods;
  bool get isLoading => _loading;
  String? get lastError => _lastError;

  bool get showHistory => _showHistory;
  String get searchQuery => _searchQuery;
  FoodUrgencyFilter get urgencyFilter => _urgencyFilter;
  FoodLocation? get locationFilter => _locationFilter;

  FoodStats get stats {
    final active = _foodsList.where((f) => f.status == FoodStatus.active);
    var urgent = 0;
    var week = 0;
    for (final food in active) {
      final days = food.daysUntilExpiration();
      if (days >= 0 && days <= 3) urgent++;
      if (days >= 0 && days <= 7) week++;
    }
    return FoodStats(
      activeCount: active.length,
      urgentCount: urgent,
      expiringThisWeekCount: week,
      eatenCount:
          _foodsList.where((f) => f.status == FoodStatus.eaten).length,
      discardedCount:
          _foodsList.where((f) => f.status == FoodStatus.discarded).length,
    );
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  void setShowHistory(bool value) {
    if (_showHistory == value) return;
    _showHistory = value;
    _refreshVisibleFoods();
  }

  void setSearchQuery(String value) {
    final trimmed = value.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    _refreshVisibleFoods();
  }

  void setUrgencyFilter(FoodUrgencyFilter value) {
    if (_urgencyFilter == value) return;
    _urgencyFilter = value;
    _refreshVisibleFoods();
  }

  void setLocationFilter(FoodLocation? value) {
    if (_locationFilter == value) return;
    _locationFilter = value;
    _refreshVisibleFoods();
  }

  void clearFilters() {
    _searchQuery = '';
    _urgencyFilter = FoodUrgencyFilter.all;
    _locationFilter = null;
    _refreshVisibleFoods();
  }

  Future<void> _refreshVisibleFoods() async {
    try {
      _visibleFoods = await _db.getFilteredFoods(
        showHistory: _showHistory,
        searchQuery: _searchQuery,
        urgencyFilter: _urgencyFilter,
        locationFilter: _locationFilter,
      );
      _lastError = null;
    } catch (e) {
      _lastError = 'Impossible de filtrer la liste : $e';
    }
    notifyListeners();
  }

  Future<void> _loadFoodsList() async {
    _loading = true;
    notifyListeners();

    try {
      _foodsList = await _db.getAllFoods();
      _sortFoodsList();
      await _refreshVisibleFoods();
      await NotificationService.instance.rescheduleAll(
        _foodsList.where((f) => f.status == FoodStatus.active),
      );
      _lastError = null;
    } catch (e) {
      _lastError = 'Impossible de charger les aliments : $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addFood({
    required String name,
    required DateTime expirationDate,
    FoodLocation location = FoodLocation.unspecified,
    String? imageUrl,
    String? barcode,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return false;

    final food = Food(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      expirationDate: expirationDate,
      dateAdded: DateTime.now(),
      location: location,
      imageUrl: imageUrl,
      barcode: barcode,
    );

    return _mutate(
      action: () async {
        await _db.upsertFood(food);
        _foodsList.add(food);
        _sortFoodsList();
        await NotificationService.instance.syncFoodReminders(food);
        await _refreshVisibleFoods();
      },
      rollback: () {
        _foodsList.removeWhere((f) => f.id == food.id);
      },
      errorMessage: 'Impossible d\'ajouter l\'aliment',
    );
  }

  Future<bool> addFoodFromText(String name, String dateText) async {
    if (name.trim().isEmpty || dateText.isEmpty) return false;
    final expirationDate = DateFormat('dd/MM/yyyy').parse(dateText);
    return addFood(name: name, expirationDate: expirationDate);
  }

  Future<bool> updateFood(Food updated) async {
    final index = _foodsList.indexWhere((food) => food.id == updated.id);
    if (index < 0) return false;

    final previous = _foodsList[index];
    return _mutate(
      action: () async {
        await _db.upsertFood(updated);
        _foodsList[index] = updated;
        _sortFoodsList();
        await NotificationService.instance.syncFoodReminders(updated);
        await _refreshVisibleFoods();
      },
      rollback: () {
        _foodsList[index] = previous;
      },
      errorMessage: 'Impossible de mettre à jour l\'aliment',
    );
  }

  Future<bool> markStatus(String id, FoodStatus status) async {
    final index = _foodsList.indexWhere((food) => food.id == id);
    if (index < 0) return false;

    final previous = _foodsList[index];
    final updated = previous.copyWith(status: status);
    return _mutate(
      action: () async {
        await _db.upsertFood(updated);
        _foodsList[index] = updated;
        await NotificationService.instance.syncFoodReminders(updated);
        await _refreshVisibleFoods();
      },
      rollback: () {
        _foodsList[index] = previous;
      },
      errorMessage: 'Impossible de changer le statut',
    );
  }

  Future<bool> removeFoodById(String id) async {
    final index = _foodsList.indexWhere((food) => food.id == id);
    if (index < 0) return false;

    final removed = _foodsList[index];
    return _mutate(
      action: () async {
        await _db.deleteFood(id);
        _foodsList.removeAt(index);
        await NotificationService.instance.cancelFoodReminders(id);
        await _refreshVisibleFoods();
      },
      rollback: () {
        _foodsList.insert(index, removed);
        _sortFoodsList();
      },
      errorMessage: 'Impossible de supprimer l\'aliment',
    );
  }

  Future<bool> removeFood(int index) async {
    if (index < 0 || index >= _foodsList.length) return false;
    final food = _foodsList[index];
    return removeFoodById(food.id);
  }

  Future<bool> _mutate({
    required Future<void> Function() action,
    required VoidCallback rollback,
    required String errorMessage,
  }) async {
    try {
      _lastError = null;
      await action();
      notifyListeners();
      return true;
    } catch (e) {
      rollback();
      _lastError = '$errorMessage : $e';
      notifyListeners();
      return false;
    }
  }

  void _sortFoodsList() {
    _foodsList.sort((a, b) {
      final statusCompare = a.status.index.compareTo(b.status.index);
      if (statusCompare != 0) return statusCompare;
      return a.expirationDate.compareTo(b.expirationDate);
    });
  }
}
