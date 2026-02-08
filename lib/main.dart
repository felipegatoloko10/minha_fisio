import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/widget_service.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await NotificationService.requestPermissions();
  
  await HomeWidget.setAppGroupId('group.minha_fisio');
  
  // Atualização inicial do widget
  final treatments = await StorageService.getTreatments();
  await WidgetService.updateNextSessionWidget(treatments);
  
  runApp(const MinhaFisioApp());
}

class MinhaFisioApp extends StatelessWidget {
  const MinhaFisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Fisio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const LoginPage(),
    );
  }
}