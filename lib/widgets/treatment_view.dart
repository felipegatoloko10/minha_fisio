import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/treatment_model.dart';
import '../controllers/treatment_controller.dart';
import '../services/phrase_service.dart';
import '../services/notification_service.dart'; // Ainda necessário para agendamento direto se não movido totalmente pro controller
import '../utils/app_constants.dart';
import 'treatment/treatment_header.dart';
import 'treatment/treatment_calendar.dart';
import 'treatment/treatment_trophies.dart';

class TreatmentView extends StatefulWidget {
  final TreatmentModel treatment;
  // Mantemos o callback para compatibilidade ou ações extras, mas a lógica pesada vai pro controller
  final Function(TreatmentModel)? onChanged; 

  const TreatmentView({super.key, required this.treatment, this.onChanged});

  @override
  State<TreatmentView> createState() => _TreatmentViewState();
}

class _TreatmentViewState extends State<TreatmentView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getEndDate() {
    if (widget.treatment.sessions.isEmpty) return "N/A";
    List<DateTime> dates = widget.treatment.sessions.map((s) => s.date).toList();
    dates.sort();
    return DateFormat('dd/MM/yyyy').format(dates.last);
  }

  String _getNextSession() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    List<SessionModel> pending = widget.treatment.sessions.where((s) {
      return s.status == AppConstants.statusPendente && (s.date.isAfter(today) || (s.date.year == today.year && s.date.month == today.month && s.date.day == today.day));
    }).toList();

    if (pending.isEmpty) return "Nenhuma sessão pendente";
    
    pending.sort((a, b) => a.date.compareTo(b.date));
    var next = pending.first;
    return "Próxima sessão: ${DateFormat('dd/MM').format(next.date)} às ${next.time}";
  }

  void _showStatusPicker(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    int index = widget.treatment.sessions.indexWhere((s) => DateFormat('yyyy-MM-dd').format(s.date) == dateStr);
    if (index == -1) return;
    final session = widget.treatment.sessions[index];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sessão de ${DateFormat('dd/MM').format(day)} às ${session.time}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _statusTile(Icons.check_circle, Colors.blue, AppConstants.statusRealizada, index),
              _statusTile(Icons.cancel, Colors.red, AppConstants.statusCancelada, index),
              _statusTile(Icons.update, Colors.purple, AppConstants.statusRemarcada, index),
              _statusTile(Icons.hourglass_empty, Colors.orange, AppConstants.statusPendente, index),
            ],
          ),
        );
      }
    );
  }

  Widget _statusTile(IconData icon, Color color, String status, int index) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status),
      onTap: () => _updateStatus(index, status),
    );
  }

  void _updateStatus(int index, String status) async {
    final treatment = widget.treatment;
    String oldStatus = treatment.sessions[index].status;
    if (oldStatus == status) { Navigator.pop(context); return; }
    
    // Calcula progresso ANTES da mudança para comparar depois
    int doneOld = treatment.sessions.where((s) => s.status == AppConstants.statusRealizada).length;
    double progressOld = treatment.total > 0 ? doneOld / treatment.total : 0;

    final controller = context.read<TreatmentController>();

    if (status == AppConstants.statusRemarcada) {
      Navigator.pop(context); 
      DateTime? newDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'DATA DA REMARCAÇÃO',
      );
      if (newDate != null) {
        if (!mounted) return;
        TimeOfDay? newTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
        if (newTime != null) {
           await controller.updateSessionStatus(
             treatment.id, 
             index, 
             AppConstants.statusRemarcada, 
             newDate: newDate, 
             newTime: '${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}'
           );
        }
      }
      return;
    }

    // Fecha modal
    Navigator.pop(context);

    // Atualiza status via controller
    await controller.updateSessionStatus(treatment.id, index, status);

    // Verifica conquistas
    // Precisamos do tratamento ATUALIZADO para saber o novo progresso. 
    // Como o controller notifica listeners e nós somos filhos de um Consumer/TabBarView que reconstrói, 
    // teoricamente já teríamos os dados novos SE o pai rebuildasse.
    // Mas aqui estamos num método async. Vamos calcular baseado no que esperamos ou pegar do controller.
    
    // Pequeno delay para garantir que o estado propagou (idealmente usaríamos um listener de stream ou similar)
    // Mas para simplificar: vamos recalcular com base no objeto local que será atualizado.
    
    int doneNew = treatment.sessions.where((s) => s.status == AppConstants.statusRealizada).length; // Isso ainda pega do antigo se a referência não mudou? 
    // O controller atualiza a lista de tratamentos, mas o widget.treatment é final.
    // O TabBarView no DashboardPage passa o tratamento da lista do controller. Quando o controller notifica, o Dashboard rebuilbda e passa o novo objeto.
    // Porém, dentro deste método, `widget.treatment` ainda é o antigo.
    
    // CORREÇÃO: Vamos confiar que o usuário ganhou o troféu se o status for Realizada e o progresso bater os marcos.
    // Melhor: vamos emitir o confete baseado no progresso calculado localmente SIMULADO, já que sabemos que vai atualizar.
    if (status == AppConstants.statusRealizada) {
       double progressNew = treatment.total > 0 ? (doneOld + 1) / treatment.total : 0;
       _checkNewMilestone(progressOld, progressNew);
    }
  }

  void _checkNewMilestone(double oldP, double newP) {
    final milestones = [
      AppConstants.milestoneBronze, 
      AppConstants.milestoneSilver, 
      AppConstants.milestoneGold, 
      AppConstants.milestonePlatinum, 
      AppConstants.milestoneDiamond
    ];
    for (var m in milestones) {
      if (oldP < m && newP >= m) {
        _confettiController.play();
        _showMilestoneDialog(m);
        break;
      }
    }
  }

  void _showMilestoneDialog(double pct) {
    String msg = PhraseService.getRandomMilestonePhrase(pct); // Serviço de frases pode ser mantido estático ou injetado, é stateless.
    
    // Tratamento Trophies tem métodos auxiliares públicos? Não, são privados ou internos.
    // Vamos duplicar a lógica de label/icon aqui ou tornar estática em algum lugar?
    // Vamos mover para AppConstants ou Utils. Por enquanto, hardcoded aqui pra não quebrar.
    
    String label = "Conquista Desbloqueada!";
    IconData icon = Icons.star;
    
    if (pct <= 0.10) { label = "Passo 1"; icon = Icons.emoji_events_outlined; }
    else if (pct <= 0.25) { label = "Não desista"; icon = Icons.workspace_premium; }
    else if (pct <= 0.50) { label = "Você vai conseguir"; icon = Icons.military_tech; }
    else if (pct <= 0.75) { label = "Já está quase no fim"; icon = Icons.stars; }
    else { label = "Você conseguiu!"; icon = Icons.emoji_events; }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: Colors.amber.shade700, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(msg, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            child: const Text("OBRIGADO!")
          )
        ],
      ),
    );
  }

  Widget _legendaItem(Color c, String t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), 
      const SizedBox(width: 6), 
      Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))
    ]
  );

  @override
  Widget build(BuildContext context) {
    int done = widget.treatment.sessions.where((s) => s.status == AppConstants.statusRealizada).length;
    double progress = widget.treatment.total > 0 ? (done / widget.treatment.total).clamp(0.0, 1.0) : 0;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              TreatmentHeader(treatment: widget.treatment),
              TreatmentCalendar(
                treatment: widget.treatment, 
                onDaySelected: (day) => _showStatusPicker(day)
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(_getNextSession(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Text("Término previsto: ${_getEndDate()}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _legendaItem(Colors.orange, "Pendente"), 
                    _legendaItem(Colors.blue, "Realizada"), 
                    _legendaItem(Colors.red, "Cancelada"), 
                    _legendaItem(Colors.purple, "Remarcada")
                  ]
                ),
              ),
              const SizedBox(height: 24),
              TreatmentTrophies(
                progress: progress, 
                onMilestoneTap: (m) => _showMilestoneDialog(m)
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Colors.amber, Colors.orange, Colors.blue, Colors.pink],
        ),
      ],
    );
  }
}