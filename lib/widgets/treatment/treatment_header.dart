import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../models/treatment_model.dart';

class TreatmentHeader extends StatelessWidget {
  final TreatmentModel treatment;
  
  const TreatmentHeader({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    int done = treatment.sessions.where((s) => s.status == 'Realizada').length;
    double progress = treatment.total > 0 ? (done / treatment.total).clamp(0.0, 1.0) : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
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
            Text(treatment.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Profissional: ${treatment.profissional}', style: TextStyle(fontSize: 14, color: isDark ? Colors.blue.shade200 : Colors.blueGrey)),
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
            Text('$done de ${treatment.total} sessões realizadas', style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
