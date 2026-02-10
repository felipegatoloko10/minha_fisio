import 'package:flutter/material.dart';

class TrophyModel {
  final double threshold;
  final String message;
  final IconData icon;
  final double size;

  TrophyModel({
    required this.threshold,
    required this.message,
    required this.icon,
    required this.size,
  });
}

final List<TrophyModel> trophies = [
  TrophyModel(
    threshold: 0.10,
    message: "O primeiro passo é o mais importante! Continue firme.",
    icon: Icons.emoji_events_outlined,
    size: 30,
  ),
  TrophyModel(
    threshold: 0.25,
    message: "Você está criando um hábito saudável. Parabéns!",
    icon: Icons.workspace_premium,
    size: 40,
  ),
  TrophyModel(
    threshold: 0.50,
    message: "Metade do caminho! Sua dedicação é inspiradora.",
    icon: Icons.military_tech,
    size: 50,
  ),
  TrophyModel(
    threshold: 0.75,
    message: "A cura está cada vez mais próxima. Não desista!",
    icon: Icons.stars,
    size: 60,
  ),
  TrophyModel(
    threshold: 1.00,
    message: "Objetivo alcançado! Você é um vencedor!",
    icon: Icons.emoji_events,
    size: 70,
  ),
];
