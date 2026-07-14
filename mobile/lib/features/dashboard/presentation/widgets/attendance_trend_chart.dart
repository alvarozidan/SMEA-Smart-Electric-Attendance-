import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/trend_point.dart';

class AttendanceTrendChart extends StatelessWidget {
  const AttendanceTrendChart({super.key, required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context){
    if (points.isEmpty){
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Belum ada data trend')),
      );
    }

    final maxY = points
        .map((p) => p.statusCounts.total)
        .fold<int>(0, (prev, curr) => curr > prev ? curr : prev)
        .toDouble();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 10 : maxY + 2,
          barGroups: List.generate(points.length, (index) {
            final counts = points[index].statusCounts;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: counts.hadir.toDouble(), color: Colors.green, width: 6),
                BarChartRodData(toY: counts.terlambat.toDouble(), color: Colors.orange, width: 6),
                BarChartRodData(toY: counts.tidakHadir.toDouble(), color: Colors.red, width: 6),
                BarChartRodData(toY: counts.izin.toDouble(), color: Colors.blue, width: 6),
                BarChartRodData(toY: counts.sakit.toDouble(), color: Colors.purple, width: 6),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox();
                  final date = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    ),
    const SizedBox(height: 12),
    Wrap(
      spacing: 12,
      runSpacing: 6,
      children: const [
        _LegendDot(color: Colors.green, label: 'Hadir'),
        _LegendDot(color: Colors.orange, label: 'Terlambat'),
        _LegendDot(color: Colors.red, label: 'Tidak Hadir'),
        _LegendDot(color: Colors.blue, label: 'Izin'),
        _LegendDot(color: Colors.purple, label: 'Sakit'),
      ],
    ),
  ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}