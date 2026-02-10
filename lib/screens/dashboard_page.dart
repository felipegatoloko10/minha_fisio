import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../controllers/treatment_controller.dart';
import '../models/treatment_model.dart';
import 'login_page.dart';
import 'create_treatment_page.dart';
import '../widgets/treatment_view.dart';
import 'debug_notification_page.dart';

class DashboardPage extends StatefulWidget {
  final dynamic user;
  const DashboardPage({super.key, required this.user});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  TabController? _tabController;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    // Carrega os dados via Controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreatmentController>().loadTreatments();
    });

    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  // Monitora mudanças no controller para recriar o TabController se necessário
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<TreatmentController>();
    if (_tabController == null || _tabController!.length != controller.treatments.length) {
      int newIndex = 0;
      if (_tabController != null) {
        newIndex = _tabController!.index;
        if (newIndex >= controller.treatments.length) newIndex = 0;
      }
      _tabController = TabController(
        length: controller.treatments.length, 
        vsync: this,
        initialIndex: newIndex
      );
    }
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri != null && uri.host == 'treatment') {
      final treatmentIdStr = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      if (treatmentIdStr != null && treatmentIdStr.isNotEmpty) {
        int id = int.tryParse(treatmentIdStr) ?? -1;
        // Precisamos garantir que os dados estejam carregados antes de navegar
        Future.delayed(Duration.zero, () {
           _navigateToTreatment(id);
        });
      }
    }
  }

  void _navigateToTreatment(int treatmentId) {
    final controller = context.read<TreatmentController>();
    if (treatmentId == -1 || controller.treatments.isEmpty) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      int index = controller.treatments.indexWhere((t) => t.id == treatmentId);
      if (index != -1 && _tabController != null) {
        _tabController!.animateTo(index);
      }
    });
  }

  void _deleteCurrentTreatment() async {
    if (_tabController == null) return;
    final controller = context.read<TreatmentController>();
    int idx = _tabController!.index;
    if (idx >= controller.treatments.length) return;

    final treatment = controller.treatments[idx];
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Tratamento"),
        content: Text("Deseja realmente excluir '${treatment.nome}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await controller.deleteTreatment(treatment.id);
              Navigator.pop(ctx);
              // Atualiza Widgets e Notificações (Centralizado no Controller seria ideal, mas mantemos helpers aqui por enquanto)
              WidgetService.updateNextSessionWidget(controller.treatments);
            }, 
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return Icons.wb_sunny;
      case ThemeMode.dark: return Icons.nightlight_round;
      case ThemeMode.system: return Icons.brightness_auto;
    }
  }

  void _toggleTheme() {
    final provider = Provider.of<ThemeProvider>(context, listen: false);
    if (provider.themeMode == ThemeMode.system) {
      provider.setThemeMode(ThemeMode.light);
    } else if (provider.themeMode == ThemeMode.light) {
      provider.setThemeMode(ThemeMode.dark);
    } else {
      provider.setThemeMode(ThemeMode.system);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final controller = context.watch<TreatmentController>();
    final treatments = controller.treatments;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.user['name'].split(' ')[0]}'),
        actions: [
          IconButton(
            icon: Icon(_getThemeIcon(themeProvider.themeMode)),
            onPressed: _toggleTheme,
            tooltip: 'Alternar Tema',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugNotificationPage())),
            tooltip: 'Debug Notificações',
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()))),
        ],
        bottom: treatments.isEmpty 
          ? null 
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: treatments.map((t) => Tab(text: t.nome)).toList(),
            ),
      ),
      body: controller.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : treatments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icon/logo.png', height: 180),
                    const SizedBox(height: 24),
                    Text(
                      'Bem-vindo(a)!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Adoramos ter você aqui conosco. Vamos começar sua jornada de recuperação?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTreatmentPage())).then((_) => controller.loadTreatments()),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        "INICIAR NOVO TRATAMENTO",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: treatments.map((t) => TreatmentView(
                    treatment: t, 
                    // No futuro refatorar o TreatmentView para receber o controller
                    onChanged: (updated) async {
                      await controller.updateTreatment(updated);
                      // loadData já é chamado dentro do updateTreatment se notificarmos ouvintes, 
                      // mas para garantir WidgetService atualizado:
                      WidgetService.updateNextSessionWidget(controller.treatments);
                    },
                  )).toList(),
            ),
      floatingActionButton: treatments.isEmpty ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            FloatingActionButton.small(
              heroTag: "delete",
              backgroundColor: Colors.red.shade100,
              onPressed: () {
                setState(() => _isFabExpanded = false);
                _deleteCurrentTreatment();
              },
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.small(
              heroTag: "edit",
              backgroundColor: Colors.blue.shade100,
              onPressed: () {
                setState(() => _isFabExpanded = false);
                int idx = _tabController!.index;
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTreatmentPage(treatmentToEdit: treatments[idx]))).then((_) => controller.loadTreatments());
              },
              child: const Icon(Icons.edit, color: Colors.blue),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: "add",
            backgroundColor: _isFabExpanded ? Colors.blueGrey : Colors.blue.shade800,
            foregroundColor: Colors.white,
            onPressed: () {
              if (_isFabExpanded) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTreatmentPage())).then((_) {
                  setState(() => _isFabExpanded = false);
                  controller.loadTreatments();
                });
              } else {
                setState(() => _isFabExpanded = true);
              }
            },
            child: Icon(_isFabExpanded ? Icons.add_task : Icons.add),
          ),
          if (_isFabExpanded) 
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () => setState(() => _isFabExpanded = false),
                child: const Text("Fechar", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}