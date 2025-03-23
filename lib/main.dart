import 'package:app_flutter/food.dart';
import 'package:app_flutter/food_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => FoodProvider(),
      child: const MyApp(),
    ),
  );
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


  @override
  void initState() {
    super.initState();

  }

  Future<void> _selectDate(BuildContext context) async {

    final foodProvider = Provider.of<FoodProvider>(context, listen: false);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      
      foodProvider.dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      foodProvider.addFood(foodProvider.textController.text, foodProvider.dateController.text);

      
    }
  }


  @override
  Widget build(BuildContext context) {
    final foodProvider = Provider.of<FoodProvider>(context);

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
              child: Consumer<FoodProvider>(  
                builder: (context, foodProvider, child) {  
                  return ListView.builder(
                    itemCount: foodProvider.foodsList.length,
                    itemBuilder: (context, index) {
                      final food = foodProvider.foodsList[index];
                      int daysToExpire = food.expirationDate.difference(DateTime.now()).inDays;
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
                          food.name,
                          style: TextStyle(color: Colors.black), // Couleur du texte
                        ),
                        subtitle: Text(
                          'Expire dans $daysToExpire jours, le : ${DateFormat('dd/MM/yyyy').format(food.expirationDate)}',
                          style: TextStyle(color: subtitleColor), // Couleur du sous-texte
                        ),
                        leading: IconButton(
                          icon: Icon(Icons.delete, color: Colors.black), // Couleur de l'icône
                          onPressed: () {
                            foodProvider.removeFood(index);
                            print('Suppression de l\'élément à l\'index $index');
                          },
                        ),
                      );
                    },
                  );
                }
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
                        controller: foodProvider.textController,
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
                        controller: foodProvider.dateController,
                        decoration: InputDecoration(
                          hintText: 'DLC',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    SizedBox(width: 16.0), // Espace entre le texte et le bouton
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        foodProvider.addFood(foodProvider.textController.text, foodProvider.dateController.text);
                        foodProvider.textController.clear();
                        foodProvider.dateController.clear();
                        FocusScope.of(context).unfocus();
                      },
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
    final foodProvider = Provider.of<FoodProvider>(context);
    // Nettoyez le contrôleur lorsque le widget est détruit
    foodProvider.textController.dispose();
    foodProvider.dateController.dispose();
    super.dispose();
  }
}
