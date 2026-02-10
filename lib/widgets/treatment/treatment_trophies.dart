import 'package:flutter/material.dart';
import '../../services/phrase_service.dart';
import '../../utils/app_constants.dart';

class TreatmentTrophies extends StatelessWidget {
  final double progress;
  final Function(double) onMilestoneTap;

  const TreatmentTrophies({super.key, required this.progress, required this.onMilestoneTap});

  @override
  Widget build(BuildContext context) {
    final milestones = [
      AppConstants.milestoneBronze, 
      AppConstants.milestoneSilver, 
      AppConstants.milestoneGold, 
      AppConstants.milestonePlatinum, 
      AppConstants.milestoneDiamond
    ];

    List<Widget> earned = [];
    for (var m in milestones) {
      if (progress >= m) {
        earned.add(
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double val, child) {
              return Transform.scale(
                scale: val,
                child: _buildTrophyItem(m),
              );
            },
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: earned.map((w) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0), 
              child: w,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrophyItem(double m) {
    return GestureDetector(
      onTap: () => onMilestoneTap(m),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getMilestoneIcon(m), color: Colors.amber.shade700, size: 32),
          ),
          const SizedBox(height: 4),
          Text(_getMilestoneLabel(m), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }

  String _getMilestoneLabel(double pct) {
    if (pct <= AppConstants.milestoneBronze) return "Passo 1";
    if (pct <= AppConstants.milestoneSilver) return "Não desista";
    if (pct <= AppConstants.milestoneGold) return "Você vai conseguir";
    if (pct <= AppConstants.milestonePlatinum) return "Já está quase no fim";
    return "Você conseguiu!";
  }

  IconData _getMilestoneIcon(double pct) {
    if (pct <= AppConstants.milestoneBronze) return Icons.emoji_events_outlined;
    if (pct <= AppConstants.milestoneSilver) return Icons.workspace_premium;
    if (pct <= AppConstants.milestoneGold) return Icons.military_tech;
    if (pct <= AppConstants.milestonePlatinum) return Icons.stars;
    return Icons.emoji_events;
  }
}
