import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/app_database.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../services/theme_service.dart';
import '../repositories/treatment_repository.dart';
import '../repositories/auth_repository.dart';
import '../controllers/treatment_controller.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Simula tempo mínimo para não piscar
    final startTime = DateTime.now();

    try {
      // 1. Inicialização de Serviços Básicos (Paralelo)
      await Future.wait([
        NotificationService.init(),
        // Tenta configurar widget, mas não trava se falhar
        HomeWidget.setAppGroupId('group.minha_fisio').catchError((e) { print("Widget Error: $e"); return null; }),
      ]);

      // 2. Infraestrutura Crítica
      final appDatabase = AppDatabase();
      final db = await appDatabase.database;
      final prefs = await SharedPreferences.getInstance();

      // 3. Repositories
      final treatmentRepository = TreatmentRepository(db);
      final authRepository = AuthRepository(db, prefs);

      // 4. Inicialização de Dados (Background)
      try {
        final treatments = await treatmentRepository.getTreatments();
        await WidgetService.updateNextSessionWidget(treatments);
        await NotificationService.rescheduleAll(treatments);
      } catch (e) {
        print("Erro ao carregar dados iniciais: $e");
      }

      // Garante tempo mínimo de splash de 1.5s
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime.inMilliseconds < 1500) {
        await Future.delayed(Duration(milliseconds: 1500 - elapsedTime.inMilliseconds));
      }

      if (!mounted) return;

      // Monta a árvore de dependências e navega
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(prefs),
              ),
              Provider<ITreatmentRepository>.value(
                value: treatmentRepository,
              ),
              Provider<IAuthRepository>.value(
                value: authRepository,
              ),
              ChangeNotifierProvider<TreatmentController>(
                create: (_) => TreatmentController(treatmentRepository),
              ),
              ChangeNotifierProvider<AuthController>(
                create: (_) => AuthController(authRepository),
              ),
            ],
            child: const MinhaFisioApp(),
          ),
        ),
      );

    } catch (e, stack) {
      print("ERRO FATAL NA INICIALIZAÇÃO: $e");
      print(stack);
      // Mostrar tela de erro
      if (mounted) {
         showDialog(context: context, builder: (_) => AlertDialog(title: Text("Erro"), content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0), // Cor da marca
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/logo.png', height: 120),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class MinhaFisioApp extends StatelessWidget {
  const MinhaFisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Minha Fisio',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800, brightness: Brightness.light),
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue.shade800, 
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
            ),
            cardTheme: const CardTheme(
              color: Color(0xFF1E1E1E),
            ),
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
      },
    );
  }
}
