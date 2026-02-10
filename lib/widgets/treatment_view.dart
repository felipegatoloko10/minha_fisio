import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../models/treatment_model.dart';
import '../services/notification_service.dart';
import '../services/phrase_service.dart';

class TreatmentView extends StatefulWidget {
  final TreatmentModel treatment;
  final Function(TreatmentModel) onChanged;
  const TreatmentView({super.key, required this.treatment, required this.onChanged});

  @override
  State<TreatmentView> createState() => _TreatmentViewState();
}

class _TreatmentViewState extends State<TreatmentView> {
  late TreatmentModel _t;
  DateTime _focusedDay = DateTime.now();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _t = widget.treatment;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TreatmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _t = widget.treatment;
  }

  String _getEndDate() {
    if (_t.sessions.isEmpty) return "N/A";
    List<DateTime> dates = _t.sessions.map((s) => s.date).toList();
    dates.sort();
    return DateFormat('dd/MM/yyyy').format(dates.last);
  }

  String _getNextSession() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    List<SessionModel> pending = _t.sessions.where((s) {
      return s.status == 'Pendente' && (s.date.isAfter(today) || (s.date.year == today.year && s.date.month == today.month && s.date.day == today.day));
    }).toList();

    if (pending.isEmpty) return "Nenhuma sessão pendente";
    
    pending.sort((a, b) => a.date.compareTo(b.date));
    var next = pending.first;
    return "Próxima sessão: ${DateFormat('dd/MM').format(next.date)} às ${next.time}";
  }

  void _showStatusPicker(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    int index = _t.sessions.indexWhere((s) => DateFormat('yyyy-MM-dd').format(s.date) == dateStr);
    if (index == -1) return;
    final session = _t.sessions[index];

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
              _statusTile(Icons.check_circle, Colors.blue, "Realizada", index),
              _statusTile(Icons.cancel, Colors.red, "Cancelada", index),
              _statusTile(Icons.update, Colors.purple, "Remarcada", index),
              _statusTile(Icons.hourglass_empty, Colors.orange, "Pendente", index),
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
    String oldStatus = _t.sessions[index].status;
    if (oldStatus == status) { Navigator.pop(context); return; }
    
    if (status == "Remarcada") {
      Navigator.pop(context); 
      DateTime? newDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'DATA DA REMARCAÇÃO',
      );
      if (newDate != null) {
        String newDateStr = DateFormat('yyyy-MM-dd').format(newDate);
        int existingIdx = _t.sessions.indexWhere((s) => DateFormat('yyyy-MM-dd').format(s.date) == newDateStr);
        
        if (existingIdx != -1) {
          if (!mounted) return;
          bool? editTime = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Aviso"),
              content: const Text("Esse dia já faz parte do tratamento. Deseja editar a hora do tratamento nesse dia?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("NÃO")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("SIM")),
              ],
            )
          );
          
          if (editTime == true) {
            TimeOfDay? newTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
            if (newTime != null) {
              setState(() {
                _t.sessions[existingIdx].time = '${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}';
                _t.sessions[existingIdx].status = 'Pendente';
                _t.sessions[index].status = 'Pendente'; 
              });
              await NotificationService.scheduleTreatmentNotifications(_t, isStatusUpdate: true);
              widget.onChanged(_t);
            }
          }
        } else {
          TimeOfDay? newTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 14, minute: 0));
          if (newTime != null) {
            setState(() {
              _t.sessions[index].status = 'Remarcada';
              _t.sessions.add(SessionModel(
                date: newDate,
                status: 'Pendente',
                time: '${newTime.hour}:${newTime.minute.toString().padLeft(2, '0')}'
              ));
            });
            await NotificationService.scheduleTreatmentNotifications(_t, isStatusUpdate: true);
            widget.onChanged(_t);
          }
        }
      }
      return;
    }

    int oldDoneCount = _t.sessions.where((s) => s.status == 'Realizada').length;
    double oldProgress = _t.total > 0 ? oldDoneCount / _t.total : 0;

    // Fecha o modal de opções ANTES de qualquer outra interação visual
    Navigator.pop(context);

    setState(() { _t.sessions[index].status = status; });
    
    int newDoneCount = _t.sessions.where((s) => s.status == 'Realizada').length;
    double newProgress = _t.total > 0 ? newDoneCount / _t.total : 0;

    _checkNewMilestone(oldProgress, newProgress);

    if (status == "Cancelada" && oldStatus != "Cancelada") { 
      _addSessionAtEnd(); 
    }
    else if (oldStatus == "Cancelada" && (status == "Pendente" || status == "Realizada")) { 
      _removeLastSession(); 
    }
    
    await NotificationService.scheduleTreatmentNotifications(_t, isStatusUpdate: true);
    
    widget.onChanged(_t);
  }

  void _checkNewMilestone(double oldP, double newP) {
    final milestones = [0.10, 0.25, 0.50, 0.75, 1.00];
    for (var m in milestones) {
      if (oldP < m && newP >= m) {
        _confettiController.play();
        _showMilestoneDialog(m);
        break;
      }
    }
  }

  void _showMilestoneDialog(double pct) {
    String msg = PhraseService.getRandomMilestonePhrase(pct);
    String label = _getMilestoneLabel(pct);
    IconData icon = _getMilestoneIcon(pct);

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

  String _getMilestoneLabel(double pct) {
    if (pct <= 0.10) return "Passo 1";
    if (pct <= 0.25) return "Não desista";
    if (pct <= 0.50) return "Você vai conseguir";
    if (pct <= 0.75) return "Já está quase no fim";
    return "Você conseguiu!";
  }

  IconData _getMilestoneIcon(double pct) {
    if (pct <= 0.10) return Icons.emoji_events_outlined;
    if (pct <= 0.25) return Icons.workspace_premium;
    if (pct <= 0.50) return Icons.military_tech;
    if (pct <= 0.75) return Icons.stars;
    return Icons.emoji_events;
  }

  void _addSessionAtEnd() {
    List<DateTime> dates = _t.sessions.map((s) => s.date).toList();
    dates.sort();
    DateTime lastDate = dates.last;
    if (_t.daysIndices.isEmpty) return;
    DateTime nextDate = lastDate.add(const Duration(days: 1));
    while (!_t.daysIndices.contains(nextDate.weekday)) { nextDate = nextDate.add(const Duration(days: 1)); }
    _t.sessions.add(SessionModel(
      date: nextDate,
      status: 'Pendente',
      time: _t.sessions.first.time
    ));
  }

  void _removeLastSession() {
    if (_t.sessions.length > _t.total) {
      _t.sessions.sort((a, b) => a.date.compareTo(b.date));
      _t.sessions.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    int done = _t.sessions.where((s) => s.status == 'Realizada').length;
    double progress = _t.total > 0 ? (done / _t.total).clamp(0.0, 1.0) : 0;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Profissional: ${_t.profissional}', style: TextStyle(fontSize: 14, color: isDark ? Colors.blue.shade200 : Colors.blueGrey)),
                      const SizedBox(height: 12),
                      LinearPercentIndicator(
                        animation: true, 
                        lineHeight: 15, 
                        percent: progress, 
                        center: Text("${(progress * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), 
                        progressColor: Colors.blue.shade700, 
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.white, 
                        barRadius: const Radius.circular(10)
                      ),
                      const SizedBox(height: 8),
                      Text('$done de ${_t.total} sessões realizadas', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              TableCalendar(
                locale: 'pt_BR',
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                calendarFormat: CalendarFormat.month,
                onDaySelected: (s, f) { setState(() => _focusedDay = f); _showStatusPicker(s); },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
                  selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  prioritizedBuilder: (context, day, focusedDay) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(day);
                    final sessionsOnDay = _t.sessions.where((s) => DateFormat('yyyy-MM-dd').format(s.date) == dateStr).toList();
                    bool isToday = day.year == today.year && day.month == today.month && day.day == today.day;

                    if (sessionsOnDay.isNotEmpty) {
                      final status = sessionsOnDay.first.status;
                      Color color = Colors.orange.shade400;
                      if (status == 'Realizada') color = Colors.blue.shade600;
                      if (status == 'Cancelada') color = Colors.red.shade600;
                      if (status == 'Remarcada') color = Colors.purple.shade600;
                      
                      return Container(
                        margin: const EdgeInsets.all(4), 
                        alignment: Alignment.center, 
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isToday ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null), 
                        child: Text(day.day.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      );
                    } else if (isToday) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white70 : Colors.black54, width: 1)),
                        child: Text(day.day.toString(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                      );
                    }
                    return null;
                  },
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
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
              _buildTrophies(progress),
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

  Widget _buildTrophies(double progress) {
    final milestones = [0.10, 0.25, 0.50, 0.75, 1.00];

    List<Widget> earned = [];
    for (var m in milestones) {
      if (progress >= m) {
        earned.add(
          GestureDetector(
            onTap: () => _showMilestoneDialog(m),
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double val, child) {
                return Transform.scale(
                  scale: val,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getMilestoneIcon(m), color: Colors.amber.shade700, size: 36 + (milestones.indexOf(m) * 4).toDouble()),
                      ),
                      const SizedBox(height: 4),
                      Text(_getMilestoneLabel(m), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                );
              },
            ),
          )
        );
      }
    }

    if (earned.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text("SUA GALERIA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.5)),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: earned,
        ),
      ],
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
}