import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/treatment_model.dart';

class CreateTreatmentPage extends StatefulWidget {
  final TreatmentModel? treatmentToEdit;
  const CreateTreatmentPage({super.key, this.treatmentToEdit});

  @override
  State<CreateTreatmentPage> createState() => _CreateTreatmentPageState();
}

class _CreateTreatmentPageState extends State<CreateTreatmentPage> {
  final _qtdController = TextEditingController();
  final _nomeController = TextEditingController();
  final _profController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  DateTime _startDate = DateTime.now();
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.treatmentToEdit != null) {
      _nomeController.text = widget.treatmentToEdit!.nome;
      _profController.text = widget.treatmentToEdit!.profissional;
      _qtdController.text = widget.treatmentToEdit!.total.toString();
      _startDate = widget.treatmentToEdit!.startDate;
      final firstTimeParts = widget.treatmentToEdit!.sessions.first.time.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(firstTimeParts[0]), minute: int.parse(firstTimeParts[1]));
      for (int d in widget.treatmentToEdit!.daysIndices) {
        _selectedDays[d - 1] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.treatmentToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Tratamento' : 'Novo Tratamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nome do Tratamento:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _nomeController, decoration: const InputDecoration(hintText: "Ex: Fisioterapia Ombro")),
            const SizedBox(height: 16),
            const Text('Nome do Profissional:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _profController, decoration: const InputDecoration(hintText: "Ex: Dr. Silva")),
            const SizedBox(height: 16),
            const Text('Total de sessões:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _qtdController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Ex: 10")),
            const SizedBox(height: 24),
            
            const Text('Data de Início do Tratamento:', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
              trailing: const Icon(Icons.calendar_today, color: Colors.blue),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  helpText: 'SELECIONE A DATA DE INÍCIO',
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 16),

            const Text('Dias da semana:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(spacing: 8, children: List.generate(7, (i) => FilterChip(
              label: Text(_dayNames[i]), 
              selected: _selectedDays[i], 
              selectedColor: Colors.blue.shade100,
              onSelected: (v) => setState(() => _selectedDays[i] = v)
            ))),
            const SizedBox(height: 24),
            const Text('Horário das Sessões:', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedTime.format(context)), 
              trailing: const Icon(Icons.access_time, color: Colors.blue), 
              onTap: () async { 
                final t = await showTimePicker(context: context, initialTime: _selectedTime); 
                if (t != null) setState(() => _selectedTime = t); 
              }
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_nomeController.text.isEmpty || _qtdController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha o nome e a quantidade de sessões")));
                  return;
                }
                
                if (!_selectedDays.contains(true)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione pelo menos um dia da semana")));
                  return;
                }

                setState(() => _isLoading = true);

                try {
                  int qtd = int.parse(_qtdController.text);
                  List<int> targetDays = [];
                  for (int i = 0; i < 7; i++) { if (_selectedDays[i]) targetDays.add(i + 1); }

                  late TreatmentModel treatment;

                  if (isEditing) {
                    DateTime now = DateTime.now();
                    DateTime today = DateTime(now.year, now.month, now.day);
                    List<SessionModel> keptSessions = widget.treatmentToEdit!.sessions.where((s) => s.date.isBefore(today)).toList();
                    List<SessionModel> newSessions = [];
                    int sessionsRemaining = qtd - keptSessions.length;
                    
                    if (sessionsRemaining > 0) {
                      DateTime current = _startDate.isAfter(today) ? _startDate : today;
                      int count = 0;
                      while (count < sessionsRemaining) {
                        if (targetDays.contains(current.weekday)) {
                          if (!keptSessions.any((s) => s.date.year == current.year && s.date.month == current.month && s.date.day == current.day)) {
                            newSessions.add(SessionModel(
                              date: current,
                              time: '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            ));
                            count++;
                          }
                        }
                        current = current.add(const Duration(days: 1));
                      }
                    }

                    treatment = TreatmentModel(
                      id: widget.treatmentToEdit!.id,
                      nome: _nomeController.text,
                      profissional: _profController.text,
                      total: qtd,
                      startDate: _startDate,
                      daysIndices: targetDays,
                      sessions: [...keptSessions, ...newSessions],
                    );
                    await StorageService.updateTreatment(treatment);
                  } else {
                    List<SessionModel> sessions = [];
                    DateTime current = _startDate;
                    int count = 0;
                    while (count < qtd) {
                      if (targetDays.contains(current.weekday)) {
                        sessions.add(SessionModel(
                          date: current,
                          time: '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ));
                        count++;
                      }
                      current = current.add(const Duration(days: 1));
                    }
                    treatment = TreatmentModel(
                      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      nome: _nomeController.text,
                      profissional: _profController.text,
                      total: qtd,
                      startDate: _startDate,
                      daysIndices: targetDays,
                      sessions: sessions,
                    );
                    await StorageService.addTreatment(treatment);
                  }

                  // Notificações em background sem travar a UI
                  NotificationService.scheduleTreatmentNotifications(treatment);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? "Alterações salvas!" : "Tratamento criado com sucesso!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Fecha a tela primeiro
                } catch (e) {
                  print("Erro ao salvar: $e");
                  setState(() => _isLoading = false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao salvar tratamento no banco de dados"), backgroundColor: Colors.red));
                }
              }, 
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ), 
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text(isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR TRATAMENTO', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ),
    );
  }
}
