import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/notification_service.dart';

class DebugNotificationPage extends StatefulWidget {
  const DebugNotificationPage({super.key});

  @override
  State<DebugNotificationPage> createState() => _DebugNotificationPageState();
}

class _DebugNotificationPageState extends State<DebugNotificationPage> {
  String _log = "";
  List<PendingNotificationRequest> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _refreshPending();
  }

  void _logMsg(String msg) {
    setState(() => _log += "${DateTime.now().toString().split('.')[0]}: $msg\n");
  }

  void _refreshPending() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final pending = await plugin.pendingNotificationRequests();
    setState(() {
      _pendingNotifications = pending;
    });
    _logMsg("Pendentes: ${pending.length}");
  }

  void _checkPermissions() async {
    final android = FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      bool? notifications = await android.requestNotificationsPermission();
      bool? exact = await android.requestExactAlarmsPermission();
      _logMsg("Permissão Notificação: $notifications");
      _logMsg("Permissão Alarme Exato: $exact");
    }
  }

  void _testNotification() async {
    _logMsg("Agendando teste para daqui a 1 minuto...");
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(const Duration(minutes: 1));

    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.zonedSchedule(
        99999,
        'Teste de Debug',
        'Se você está vendo isso, o agendamento funciona!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'debug_channel',
            'Canal de Debug',
             importance: Importance.max,
             priority: Priority.high,
             fullScreenIntent: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      _logMsg("Agendado com sucesso para ${scheduledDate.toString()}");
      _refreshPending();
    } catch (e) {
      _logMsg("ERRO ao agendar: $e");
    }
  }

  void _showTimeInfo() {
    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    _logMsg("System Time: $now");
    _logMsg("TZ Time: $tzNow");
    _logMsg("TZ Local: ${tz.local.name}");
    _logMsg("Is TZ valid? ${now.difference(tzNow).inMinutes.abs() < 5 ? 'SIM' : 'NÃO (Diferença detectada!)'}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug Notificações")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _checkPermissions, child: const Text("Permissões")),
              ElevatedButton(onPressed: _showTimeInfo, child: const Text("Tempo")),
              ElevatedButton(onPressed: _testNotification, child: const Text("Testar 1min")),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Text(_log, style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
          const Divider(),
          const Text("Notificações Pendentes:", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _pendingNotifications.length,
              itemBuilder: (ctx, i) {
                final p = _pendingNotifications[i];
                return ListTile(
                  title: Text("${p.id}: ${p.title}"),
                  subtitle: Text(p.body ?? "Sem corpo"),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
