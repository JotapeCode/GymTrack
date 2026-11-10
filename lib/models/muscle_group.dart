import 'package:flutter/material.dart';

enum MuscleGroup {
  peito('Peito', Icons.fitness_center, Color(0xFF22C55E)),
  costas('Costas', Icons.rowing, Color(0xFF38BDF8)),
  biceps('Bíceps', Icons.sports_gymnastics, Color(0xFFF59E0B)),
  triceps('Tríceps', Icons.sports_martial_arts, Color(0xFFA78BFA)),
  ombros('Ombros', Icons.accessibility_new, Color(0xFFF472B6)),
  pernas('Pernas', Icons.directions_run, Color(0xFFFB923C)),
  abdomen('Abdômen', Icons.self_improvement, Color(0xFF2DD4BF));

  const MuscleGroup(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static MuscleGroup fromName(String name) => MuscleGroup.values.firstWhere(
    (g) => g.name == name,
    orElse: () => MuscleGroup.peito,
  );
}
