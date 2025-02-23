import 'package:app_flutter/food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DLD APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
       localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('fr', ''), // Français
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

  List<Food> foodsList = [];

  @override
  void initState() {
    super.initState();
    _loadFoodsList();
  }

  Future<void> _loadFoodsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? foodsJson = prefs.getString('foodsList');
    if (foodsJson != null) {
      List<dynamic> foodsMap = jsonDecode(foodsJson);
      setState(() {
        foodsList = foodsMap.map((item) => Food.fromJson(item)).toList();
        _sortFoodsList();
      });
    }
  }

  Future<void> _saveFoodsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String foodsJson = jsonEncode(foodsList.map((item) => item.toJson()).toList());
    await prefs.setString('foodsList', foodsJson);
  }

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _addFood(){
    setState(() {
      String newItem = _textController.text;
      String dateText = _dateController.text;
      if (newItem.isNotEmpty && dateText.isNotEmpty) {
        // Ajoutez le texte à la liste
        DateTime expirationDate = DateFormat('dd/MM/yyyy').parse(dateText);
        foodsList.add(Food(name: newItem, expirationDate: expirationDate, dateAdded: DateTime.now()));
        // Réinitialisez le champ de texte
        _textController.clear();
        _dateController.clear();
        _saveFoodsList();
        _sortFoodsList();
      }
    });
    
    FocusScope.of(context).unfocus();
  }

  void _removeFood(int index) {
    setState(() {
      foodsList.removeAt(index);
      _saveFoodsList();
      _sortFoodsList();
    });
  }

  void _sortFoodsList() {
    setState(() {
      foodsList.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: foodsList.length,
                itemBuilder: (context, index) {
                  int daysToExpire = foodsList[index].expirationDate.difference(DateTime.now()).inDays;
                  Color subtitleColor; 

                  if (daysToExpire <= 3) {
                    subtitleColor = Colors.red; // Couleur rouge si la date d'expiration est proche (3 jours ou moins)
                  } else if (daysToExpire <= 7) {
                    subtitleColor = Colors.orange; // Couleur orange si la date d'expiration est dans une semaine ou moins
                  } else {
                    subtitleColor = Colors.green; // Couleur verte si la date d'expiration est plus éloignée
                  }

                  return ListTile(
                    tileColor: Colors.grey[200],// Couleur de fond alternée
                    title: Text(
                      foodsList[index].name,
                      style: TextStyle(color: Colors.black), // Couleur du texte
                    ),
                    subtitle: Text(
                      'Expire dans $daysToExpire jours, le : ${DateFormat('dd/MM/yyyy').format(foodsList[index].expirationDate)}',
                      style: TextStyle(color: subtitleColor), // Couleur du sous-texte
                    ),
                    leading: IconButton(
                      icon: Icon(Icons.delete, color: Colors.black), // Couleur de l'icône
                      onPressed: () {
                        _removeFood(index);
                        print('Suppression de l\'élément à l\'index $index');
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Nom de l\'aliment',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.0), 
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          hintText: 'DLC',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    SizedBox(width: 16.0), // Espace entre le texte et le bouton
                    FloatingActionButton(
                      onPressed: _addFood,
                      tooltip: 'Add',
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Nettoyez le contrôleur lorsque le widget est détruit
    _textController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
