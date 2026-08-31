import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/visita.dart';

/// Distintivo de color segun la temperatura comercial del lead.
class ScoreChip extends StatelessWidget {
  const ScoreChip({required this.temperatura, this.score, super.key});

  final TemperaturaLead temperatura;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final color = switch (temperatura) {
      TemperaturaLead.caliente => AppTheme.caliente,
      TemperaturaLead.tibio => AppTheme.tibio,
      TemperaturaLead.frio => AppTheme.frio,
    };
    final icono = switch (temperatura) {
      TemperaturaLead.caliente => Icons.local_fire_department,
      TemperaturaLead.tibio => Icons.trending_up,
      TemperaturaLead.frio => Icons.ac_unit,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            score == null
                ? temperatura.etiqueta
                : '${temperatura.etiqueta} - $score',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
