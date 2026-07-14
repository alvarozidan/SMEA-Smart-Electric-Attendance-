import 'package:flutter/material.dart';

import '../../domain/entities/attendance_status_counts.dart';

class StatusSummaryGrid extends StatelessWidget {
  const StatusSummaryGrid({super.key, required this.counts, required this.notYetRecorded});

  final AttendanceStatusCounts counts;
  final int notYetRecorded;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatusItem('Hadir', counts.hadir, Colors.green, Icons.check_circle),
      _StatusItem('Terlambat', counts.terlambat, Colors.orange, Icons.schedule),
      _StatusItem('Tidak Hadir', counts.tidakHadir, Colors.red, Icons.cancel),
      _StatusItem('Izin', counts.izin, Colors.blue, Icons.assignment_outlined),
      _StatusItem('Sakit', counts.sakit, Colors.purple, Icons.local_hospital_outlined),
      _StatusItem('Belum Tercatat', notYetRecorded, Colors.grey, Icons.help_outline),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 92,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          color: item.color.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: item.color.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, color: item.color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item.value}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusItem {
  const _StatusItem(this.label, this.value, this.color, this.icon);
  final String label;
  final int value;
  final Color color;
  final IconData icon;
}