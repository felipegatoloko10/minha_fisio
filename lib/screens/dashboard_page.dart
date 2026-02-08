import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../models/treatment_model.dart';
import 'login_page.dart';
import 'create_treatment_page.dart';
import '../widgets/treatment_view.dart';

class DashboardPage extends StatefulWidget {
  final dynamic user;
  const DashboardPage({super.key, required this.user});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  List<TreatmentModel> _treatments = [];
  TabController? _tabController;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await StorageService.getTreatments();
    int? currentIndex = _tabController?.index;
    
    setState(() { 
      _treatments = data; 
      _tabController = TabController(
        length: _treatments.length, 
        vsync: this,
        initialIndex: (currentIndex != null && currentIndex < _treatments.length) ? currentIndex : 0
      );
    });
    
    // Atualiza o widget da tela inicial
    await WidgetService.updateNextSessionWidget(_treatments);
  }

  void _deleteCurrentTreatment() async {
    if (_tabController == null) return;
    int idx = _tabController!.index;
    final treatment = _treatments[idx];
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Tratamento"),
        content: Text("Deseja realmente excluir '${treatment.nome}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await StorageService.deleteTreatment(treatment.id);
              Navigator.pop(ctx);
              _loadData();
            }, 
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.user['name'].split(' ')[0]}'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()))),
        ],
        bottom: _treatments.isEmpty 
          ? null 
          : TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: _treatments.map((t) => Tab(text: t.nome)).toList(),
            ),
      ),
      body: _treatments.isEmpty
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
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTreatmentPage())).then((_) => _loadData()),
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
              children: _treatments.map((t) => TreatmentView(
                    treatment: t, 
                    onChanged: (updated) async {
                      await StorageService.updateTreatment(updated);
                      _loadData();
                    },
                  )).toList(),
            ),
      floatingActionButton: _treatments.isEmpty ? null : Column(
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTreatmentPage(treatmentToEdit: _treatments[idx]))).then((_) => _loadData());
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
                  _loadData();
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