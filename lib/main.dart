import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'controllers/collection_controller.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = CollectionController();
  runApp(KlasorumApp(controller: controller));
}

class KlasorumApp extends StatelessWidget {
  final CollectionController controller;

  const KlasorumApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klasörüm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller),
    );
  }
}
