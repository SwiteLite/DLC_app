import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/app_database.dart';
import 'food_provider.dart';
import 'notification_service.dart';
import 'pages/home_page.dart';
import 'pages/splash_page.dart';
import 'theme/food_connect_theme.dart';
import 'theme/theme_mode_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await NotificationService.instance.init();
  await AppDatabase.migrateLegacyDatabaseFileIfNeeded();

  final database = AppDatabase();
  await database.migrateFromSharedPreferencesIfNeeded();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FoodProvider(database)),
        ChangeNotifierProvider(create: (_) => ThemeModeNotifier(prefs)),
      ],
      child: const FoodConnectApp(),
    ),
  );
}

class FoodConnectApp extends StatefulWidget {
  const FoodConnectApp({super.key});

  @override
  State<FoodConnectApp> createState() => _FoodConnectAppState();
}

class _FoodConnectAppState extends State<FoodConnectApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeModeNotifier>();

    return MaterialApp(
      title: 'FoodConnect',
      theme: FoodConnectTheme.light(),
      darkTheme: FoodConnectTheme.dark(),
      themeMode: themeNotifier.mode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
      ],
      home: _showSplash
          ? SplashPage(
              onFinished: () => setState(() => _showSplash = false),
            )
          : const HomePage(),
    );
  }
}
