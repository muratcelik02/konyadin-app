import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'controllers/collection_controller.dart';
import 'report/report_store.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = CollectionController();
  final reportStore = ReportStore();
  runApp(KlasorumApp(controller: controller, reportStore: reportStore));
}

class KlasorumApp extends StatelessWidget {
  final CollectionController controller;
  final ReportStore reportStore;

  const KlasorumApp({super.key, required this.controller, required this.reportStore});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klasörüm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller, reportStore: reportStore),
    );
  }
}
