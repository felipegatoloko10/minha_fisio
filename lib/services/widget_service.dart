import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/treatment_model.dart';

class WidgetService {
  static const String _groupId = 'group.minha_fisio';
  static const String _androidWidgetName = 'HomeWidgetProvider';

  static Future<void> updateNextSessionWidget(List<TreatmentModel> treatments) async {
    TreatmentModel? nextTreatment;
    SessionModel? nextSession;
    DateTime now = DateTime.now();

    for (var t in treatments) {
      for (var s in t.sessions) {
        if (s.status == 'Pendente') {
          final timeParts = s.time.split(':');
          final sessionDate = DateTime(
            s.date.year,
            s.date.month,
            s.date.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          if (sessionDate.isAfter(now)) {
            if (nextSession == null || sessionDate.isBefore(DateTime(
              nextSession.date.year,
              nextSession.date.month,
              nextSession.date.day,
              int.parse(nextSession.time.split(':')[0]),
              int.parse(nextSession.time.split(':')[1]),
            ))) {
              nextSession = s;
              nextTreatment = t;
            }
          }
        }
      }
    }

    if (nextTreatment != null && nextSession != null) {
      await HomeWidget.saveWidgetData<String>(
        'widget_treatment',
        nextTreatment.nome,
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_treatment_id',
        nextTreatment.id.toString(),
      );
      await HomeWidget.saveWidgetData<String>(
        'widget_date_time',
        '📅 ${DateFormat('dd/MM').format(nextSession.date)} às ${nextSession.time}',
      );
    } else {
      await HomeWidget.saveWidgetData<String>('widget_treatment', 'Tudo em dia!');
      await HomeWidget.saveWidgetData<String>('widget_treatment_id', '');
      await HomeWidget.saveWidgetData<String>('widget_date_time', 'Nenhuma sessão pendente ✨');
    }

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
