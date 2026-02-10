import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/treatment_model.dart';
import 'storage_service.dart';
import 'phrase_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Limite de segurança para não estourar o limite de 500 alarmes do Android
  static const int _maxScheduledNotifications = 40; 

  static Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission(); // Importante para alarmes exatos
    }
  }

  // Método central que gerencia TODAS as notificações do app
  // Deve ser chamado sempre que um tratamento é criado, editado ou excluído,
  // e também na inicialização do app.
  static Future<void> rescheduleAll() async {
    // 1. Cancela TUDO para garantir estado limpo
    await _notifications.cancelAll();

    // 2. Reagenda as frases diárias (prioridade fixa)
    await _scheduleDailyPhrases();

    // 3. Reagenda os tratamentos (prioridade dinâmica)
    await _scheduleTreatmentNotifications();
  }

  static Future<void> _scheduleDailyPhrases() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_carinho',
      'Mensagens de Carinho',
      channelDescription: 'Mensagens aleatórias para alegrar seu dia',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final now = tz.TZDateTime.now(tz.local);
    final random = Random();

    // Agenda para os próximos 15 dias
    for (int i = 0; i < 15; i++) {
      final scheduleDay = now.add(Duration(days: i));
      final hour = 7 + random.nextInt(5); 
      final minute = random.nextInt(60);

      var scheduleDate = tz.TZDateTime(
        tz.local,
        scheduleDay.year,
        scheduleDay.month,
        scheduleDay.day,
        hour,
        minute,
      );

      if (scheduleDate.isBefore(now)) continue;

      final phrase = PhraseService.getDailyPhrase(scheduleDate.day);

      try {
        await _notifications.zonedSchedule(
          2000 + i,
          'Um carinho para você ✨',
          phrase,
          scheduleDate,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // Inexato para economizar bateria
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        print('Erro ao agendar frase: $e');
      }
    }
  }

  static Future<void> _scheduleTreatmentNotifications() async {
    final treatments = await StorageService.getTreatments();
    final now = tz.TZDateTime.now(tz.local);
    
    // Lista plana de todos os eventos futuros de todos os tratamentos
    List<Map<String, dynamic>> allEvents = [];

    for (var treatment in treatments) {
      for (var session in treatment.sessions) {
        if (session.status != 'Pendente') continue;

        final timeParts = session.time.split(':');
        final sessionDateTime = tz.TZDateTime(
          tz.local,
          session.date.year,
          session.date.month,
          session.date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        // Evento 1: Lembrete (1h antes)
        var reminderDate = sessionDateTime.subtract(const Duration(hours: 1));
        if (reminderDate.isAfter(now)) {
          allEvents.add({
            'time': reminderDate,
            'type': 'reminder',
            'treatment': treatment,
            'session': session,
            'sessionDate': sessionDateTime,
          });
        }

        // Evento 2: Pós-sessão (40min depois)
        var postDate = sessionDateTime.add(const Duration(minutes: 40));
        if (postDate.isAfter(now)) {
          allEvents.add({
            'time': postDate,
            'type': 'post',
            'treatment': treatment,
            'session': session,
            'sessionDate': sessionDateTime,
          });
        }
      }
    }

    // Ordena por data (os mais próximos primeiro)
    allEvents.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

    // Limita aos próximos X eventos
    int count = 0;
    for (var event in allEvents) {
      if (count >= _maxScheduledNotifications) break;

      final treatment = event['treatment'] as TreatmentModel;
      final session = event['session']; // SessionModel
      final type = event['type'] as String;
      final scheduleDate = event['time'] as tz.TZDateTime;
      
      const androidDetails = AndroidNotificationDetails(
        'minha_fisio_reminders',
        'Lembretes de Sessão',
        channelDescription: 'Canal de lembretes importantes',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('done', 'Realizada', showsUserInterface: false),
          AndroidNotificationAction('cancel', 'Cancelada', showsUserInterface: false),
        ],
      );

      try {
        final payload = '${treatment.id}|${session.date.toIso8601String().split('T')[0]}|${session.time}';
        final id = treatment.id.hashCode + (count * 10) + (type == 'reminder' ? 1 : 2); // ID único determinístico

        await _notifications.zonedSchedule(
          id,
          type == 'reminder' ? 'Lembrete: ${treatment.nome}' : 'Sessão Finalizada?',
          type == 'reminder' 
              ? 'Sua sessão começa em breve às ${session.time}.' 
              : 'Como foi a sessão de ${treatment.nome}? Marque seu progresso!',
          scheduleDate,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        count++;
      } catch (e) {
        print('Erro ao agendar notificação: $e');
      }
    }
  }

  // Mantido para compatibilidade, mas agora chama o rescheduleAll
  static Future<void> scheduleDailyPhrases() async {
    // No-op ou redireciona, mas como é chamado no main, melhor não fazer nada se o rescheduleAll for chamado lá
  }
  
  // Mantido para compatibilidade imediata, mas idealmente deve ser removido ou redirecionar
  static Future<void> scheduleTreatmentNotifications(TreatmentModel treatment, {bool isStatusUpdate = false}) async {
    if (!isStatusUpdate) {
      await showTreatmentCreated(treatment);
    }
    await rescheduleAll();
  }

  static Future<void> showTreatmentCreated(TreatmentModel treatment) async {
    const androidDetails = AndroidNotificationDetails(
      'treatment_status',
      'Status do Tratamento',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _notifications.show(
      treatment.id.hashCode,
      '🎉 Tratamento Criado!',
      'Um novo tratamento de ${treatment.total} sessões com ${treatment.profissional} foi configurado.',
      const NotificationDetails(android: androidDetails),
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    _handleAction(response);
  }

  static void _onNotificationResponse(NotificationResponse response) {
    _handleAction(response);
  }

  static void _handleAction(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.length < 3) return;

    final action = response.actionId;
    final treatmentId = int.parse(parts[0]);
    final dateStr = parts[1];
    final timeStr = parts[2];

    if (action == 'done' || action == 'cancel') {
      final treatments = await StorageService.getTreatments();
      final tIdx = treatments.indexWhere((t) => t.id == treatmentId);
      if (tIdx != -1) {
        final t = treatments[tIdx];
        final sIdx = t.sessions.indexWhere((s) => 
          s.date.toIso8601String().split('T')[0] == dateStr && s.time == timeStr);
        
        if (sIdx != -1) {
          t.sessions[sIdx].status = action == 'done' ? 'Realizada' : 'Cancelada';
          await StorageService.updateTreatment(t);
          // Atualiza widget e notificações após mudança de status
          await rescheduleAll();
        }
      }
    }
  }
}