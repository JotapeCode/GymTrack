import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Gráfico de linha da carga máxima por treino (ordem cronológica).
/// Pontos onde houve aumento de carga ficam destacados em verde.
class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key, required this.workouts, this.height = 220});

  final List<Workout> workouts;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (workouts.length < 2) {
      return SizedBox(
        height: height * 0.6,
        child: Center(
          child: Text(
            'Registre pelo menos 2 treinos para ver o gráfico de evolução.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      );
    }

    final spots = [
      for (final (i, w) in workouts.indexed) FlSpot(i.toDouble(), w.maxWeight),
    ];
    final weights = spots.map((s) => s.y);
    final minY = weights.reduce(math.min);
    final maxY = weights.reduce(math.max);
    final padding = math.max((maxY - minY) * 0.2, 2.0);
    final lower = math.max(0.0, (minY - padding).floorToDouble());
    final upper = (maxY + padding).ceilToDouble();
    final interval = _niceInterval((upper - lower) / 4);
    final labelStep = math.max(1, (workouts.length / 5).ceil());

    bool increasedAt(int i) =>
        i > 0 && workouts[i].maxWeight > workouts[i - 1].maxWeight;

    return Container(
      height: height,
      padding: const EdgeInsets.only(right: 16),
      child: LineChart(
        duration: const Duration(milliseconds: 400),
        LineChartData(
          minX: 0,
          maxX: (workouts.length - 1).toDouble(),
          minY: lower,
          maxY: upper,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.colors.border.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  // Evita rótulos "quebrados" nas extremidades do eixo.
                  final isEdge = value == meta.min || value == meta.max;
                  if (isEdge && value % interval != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Formatters.number(value),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i != value || i < 0 || i >= workouts.length) {
                    return const SizedBox.shrink();
                  }
                  if (i % labelStep != 0 && i != workouts.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      Formatters.shortDate(workouts[i].date),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.colors.cardHighlight,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '${Formatters.weight(s.y)}\n',
                      TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: Formatters.date(workouts[s.x.toInt()].date),
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: context.colors.accent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                getDotPainter: (spot, _, _, index) => FlDotCirclePainter(
                  radius: increasedAt(index) ? 5.5 : 4,
                  color: increasedAt(index)
                      ? context.colors.accent
                      : context.colors.background,
                  strokeWidth: 2.5,
                  strokeColor: context.colors.accent,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.accent.withValues(alpha: 0.30),
                    context.colors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _niceInterval(double raw) {
    if (raw <= 0) return 1;
    for (final step in [1.0, 2.0, 2.5, 5.0, 10.0, 20.0, 25.0, 50.0, 100.0]) {
      if (raw <= step) return step;
    }
    return 200;
  }
}
