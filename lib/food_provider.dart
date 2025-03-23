import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'food.dart'; // Assure-toi que le modèle Food est bien importé

class FoodProvider extends ChangeNotifier {
  List<Food> _foodsList = [];

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  List<Food> get foodsList => _foodsList;

  TextEditingController get textController => _textController;
  TextEditingController get dateController => _dateController;

  FoodProvider() {
    _loadFoodsList();
  }

  Future<void> _loadFoodsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? foodsJson = prefs.getString('foodsList');
    if (foodsJson != null) {
      List<dynamic> foodsMap = jsonDecode(foodsJson);
      _foodsList = foodsMap.map((item) => Food.fromJson(item)).toList();
      _sortFoodsList();
      notifyListeners();
    }
  }

  Future<void> _saveFoodsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String foodsJson = jsonEncode(_foodsList.map((item) => item.toJson()).toList());
    await prefs.setString('foodsList', foodsJson);
  }

  void addFood(String name, String dateText) {
    if (name.isNotEmpty && dateText.isNotEmpty) {
      DateTime expirationDate = DateFormat('dd/MM/yyyy').parse(dateText);
      _foodsList.add(Food(name: name, expirationDate: expirationDate, dateAdded: DateTime.now()));
      _sortFoodsList();
      _saveFoodsList();
      notifyListeners();
    }
  }

  void removeFood(int index) {
    _foodsList.removeAt(index);
    _saveFoodsList();
    notifyListeners();
  }

  void _sortFoodsList() {
    _foodsList.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
  }
}
