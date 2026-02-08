import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/treatment_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    // Corrigido para o nome correto do ícone no seu projeto
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleTreatmentNotifications(TreatmentModel treatment) async {
    try {
      // Cancela notificações antigas deste tratamento
      for (int i = 0; i < 50; i++) {
        await _notifications.cancel(treatment.id + i);
      }

      int notificationId = treatment.id;
      final now = DateTime.now();

      for (var session in treatment.sessions) {
        if (session.status != 'Pendente') continue;

        final timeParts = session.time.split(':');
        final sessionDateTime = DateTime(
          session.date.year,
          session.date.month,
          session.date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        final scheduleDate = sessionDateTime.subtract(const Duration(hours: 1));

        if (scheduleDate.isAfter(now)) {
          await _notifications.zonedSchedule(
            notificationId++,
            'Lembrete de Fisioterapia',
            'Sua sessão de "${treatment.nome}" começa em 1 hora às ${session.time}.',
            tz.TZDateTime.from(scheduleDate, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'minha_fisio_reminders',
                'Lembretes de Sessão',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            // Alterado para inexact para evitar erros de permissão de sistema
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      print("Erro ao agendar notificações: $e");
      // Não relança o erro para não travar o salvamento do tratamento
    }
  }
}