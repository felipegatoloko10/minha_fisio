import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/app_database.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'services/theme_service.dart';
import 'repositories/treatment_repository.dart';
import 'controllers/treatment_controller.dart';
import 'repositories/auth_repository.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Variáveis para DI, iniciadas como null para controle de erro
  AppDatabase? appDatabase;
  SharedPreferences? prefs;
  TreatmentRepository? treatmentRepository;
  AuthRepository? authRepository;
  
  try {
    // 1. Inicialização de Serviços Básicos
    await NotificationService.init();
    try {
      await NotificationService.requestPermissions();
    } catch (e) {
      print("Erro ao pedir permissões: $e"); // Não deve travar o app
    }
    
    try {
      await HomeWidget.setAppGroupId('group.minha_fisio');
    } catch (e) {
       print("Erro HomeWidget: $e");
    }
    
    // 2. Infraestrutura (God-Tier DI)
    appDatabase = AppDatabase();
    final db = await appDatabase.database;
    prefs = await SharedPreferences.getInstance();
    
    // 3. Repositories (Injeção de Infra)
    treatmentRepository = TreatmentRepository(db);
    authRepository = AuthRepository(db, prefs);
    
    // 4. Inicialização de Dados
    // Carrega tratamentos para Widget e Notificações com segurança
    try {
      final treatments = await treatmentRepository.getTreatments();
      await WidgetService.updateNextSessionWidget(treatments);
      await NotificationService.rescheduleAll(treatments);
    } catch (e) {
      print("Erro ao carregar dados iniciais: $e");
    }

  } catch (e, stack) {
    print("ERRO FATAL NA INICIALIZAÇÃO: $e");
    print(stack);
    // Em caso de erro fatal no banco ou prefs, o app ainda deve abrir
    // mas talvez mostrando erro ou tentando recuperar.
    // Vamos prosseguir, pois o Provider vai reclamar se repositories forem nulos.
  }

  // Fallback se algo crítico falhou (evita crash do Provider)
  if (prefs == null) prefs = await SharedPreferences.getInstance();
  // Se DB falhou, repositories ficam capengas, melhor crashar controlado ou tela de erro.
  // Se treatmentRepository for null, vamos criar um Dummy ou tentar re-instanciar (arriscado).
  // Se chegou aqui com null, é tela preta na certa se não tratarmos.
  
  if (treatmentRepository == null || authRepository == null) {
      runApp(MaterialApp(home: Scaffold(body: Center(child: Text("Erro crítico ao iniciar banco de dados.\nReinicie o app.")))));
      return;
  }

  runApp(
    MultiProvider(
      providers: [
        // Services/Shared
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs!),
        ),
        
        // Repositories (Injected as Values)
        Provider<ITreatmentRepository>.value(
          value: treatmentRepository,
        ),
        Provider<IAuthRepository>.value(
          value: authRepository,
        ),
        
        // Controllers (Dependent on Repositories)
        ChangeNotifierProvider<TreatmentController>(
          create: (_) => TreatmentController(treatmentRepository!),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(authRepository!),
        ),
      ],
      child: const MinhaFisioApp(),
    ),
  );
}

class MinhaFisioApp extends StatelessWidget {
  const MinhaFisioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer é mais seguro que Provider.of(context) fora de árvore child
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