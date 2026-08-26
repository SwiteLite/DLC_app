import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database/app_database.dart';
import 'food.dart';
import 'notification_service.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider(this._db) {
    _loadFoodsList();
  }

  final AppDatabase _db;

  List<Food> _foodsList = [];
  bool _showHistory = false;
  String _searchQuery = '';
  FoodUrgencyFilter _urgencyFilter = FoodUrgencyFilter.all;
  FoodLocation? _locationFilter;
  bool _loading = true;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Food> get foodsList => _foodsList;
  bool get isLoading => _loading;

  List<Food> get visibleFoods {
    return _foodsList.where((food) {
      final inHistoryMode = _showHistory
          ? food.status != FoodStatus.active
          : food.status == FoodStatus.active;
      if (!inHistoryMode) return false;

      if (_locationFilter != null && food.location != _locationFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = food.name.toLowerCase().contains(query);
        final matchesLocation =
            food.location.label.toLowerCase().contains(query);
        if (!matchesName && !matchesLocation) return false;
      }

      if (!_showHistory) {
        final days = food.daysUntilExpiration();
        switch (_urgencyFilter) {
          case FoodUrgencyFilter.all:
            break;
          case FoodUrgencyFilter.urgent:
            if (days < 0 || days > 3) return false;
          case FoodUrgencyFilter.ok:
            if (days <= 3) return false;
          case FoodUrgencyFilter.expired:
            if (days >= 0) return false;
        }
      }

      return true;
    }).toList();
  }

  bool get showHistory => _showHistory;
  String get searchQuery => _searchQuery;
  FoodUrgencyFilter get urgencyFilter => _urgencyFilter;
  FoodLocation? get locationFilter => _locationFilter;

  TextEditingController get textController => _textController;
  TextEditingController get dateController => _dateController;
  TextEditingController get searchController => _searchController;

  void setShowHistory(bool value) {
    if (_showHistory == value) return;
    _showHistory = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    final trimmed = value.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    notifyListeners();
  }

  void setUrgencyFilter(FoodUrgencyFilter value) {
    if (_urgencyFilter == value) return;
    _urgencyFilter = value;
    notifyListeners();
  }

  void setLocationFilter(FoodLocation? value) {
    if (_locationFilter == value) return;
    _locationFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _searchController.clear();
    _urgencyFilter = FoodUrgencyFilter.all;
    _locationFilter = null;
    notifyListeners();
  }

  Future<void> _loadFoodsList() async {
    _loading = true;
    notifyListeners();

    _foodsList = await _db.getAllFoods();
    _sortFoodsList();
    _loading = false;
    notifyListeners();

    await NotificationService.instance.rescheduleAll(
      _foodsList.where((f) => f.status == FoodStatus.active),
    );
  }

  Future<void> addFood({
    required String name,
    required DateTime expirationDate,
    FoodLocation location = FoodLocation.unspecified,
    String? imageUrl,
    String? barcode,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final food = Food(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      expirationDate: expirationDate,
      dateAdded: DateTime.now(),
      location: location,
      imageUrl: imageUrl,
      barcode: barcode,
    );

    await _db.upsertFood(food);
    _foodsList.add(food);
    _sortFoodsList();
    await NotificationService.instance.syncFoodReminders(food);
    notifyListeners();
  }

  Future<void> addFoodFromText(String name, String dateText) async {
    if (name.trim().isEmpty || dateText.isEmpty) return;
    final expirationDate = DateFormat('dd/MM/yyyy').parse(dateText);
    await addFood(name: name, expirationDate: expirationDate);
  }

  Future<void> updateFood(Food updated) async {
    final index = _foodsList.indexWhere((food) => food.id == updated.id);
    if (index < 0) return;

    await _db.upsertFood(updated);
    _foodsList[index] = updated;
    _sortFoodsList();
    await NotificationService.instance.syncFoodReminders(updated);
    notifyListeners();
  }

  Future<void> markStatus(String id, FoodStatus status) async {
    final index = _foodsList.indexWhere((food) => food.id == id);
    if (index < 0) return;

    final updated = _foodsList[index].copyWith(status: status);
    await _db.upsertFood(updated);
    _foodsList[index] = updated;
    await NotificationService.instance.syncFoodReminders(updated);
    notifyListeners();
  }

  Future<void> removeFoodById(String id) async {
    await _db.deleteFood(id);
    _foodsList.removeWhere((food) => food.id == id);
    await NotificationService.instance.cancelFoodReminders(id);
    notifyListeners();
  }

  void removeFood(int index) {
    if (index < 0 || index >= _foodsList.length) return;
    final food = _foodsList[index];
    removeFoodById(food.id);
  }

  void _sortFoodsList() {
    _foodsList.sort((a, b) {
      final statusCompare = a.status.index.compareTo(b.status.index);
      if (statusCompare != 0) return statusCompare;
      return a.expirationDate.compareTo(b.expirationDate);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
