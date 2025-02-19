import 'package:app_flutter/food.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final List<Food> foodsList = [
    Food(name: 'Poulet', expirationDate: DateTime.now(), dateAdded: DateTime.now().add(Duration(days: 7))),
    Food(name: 'Patate', expirationDate: DateTime.now(), dateAdded: DateTime.now().add(Duration(days: 3))),
    Food(name: 'Merguez', expirationDate: DateTime.now(), dateAdded: DateTime.now().add(Duration(days: 5))),
  ];

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
      }
    });
    
    FocusScope.of(context).unfocus();
  }

   void _removeFood(int index) {
    setState(() {
      foodsList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
                  return ListTile(
                    title: Text(foodsList[index].name),
                    subtitle: Text('Expire dans ${foodsList[index].expirationDate.difference(DateTime.now()).inDays} jours, le : ${DateFormat('dd/MM/yyyy').format(foodsList[index].expirationDate)}'),
                    leading: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: (){
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
