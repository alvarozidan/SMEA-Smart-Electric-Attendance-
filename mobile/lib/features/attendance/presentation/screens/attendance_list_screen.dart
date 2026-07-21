import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../classes/presentation/providers/class_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_status.dart';
import '../providers/attendance_provider.dart';

class AttendanceListScreen extends ConsumerWidget {
  const AttendanceListScreen({super.key});

  Color _statusColor(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.hadir => Colors.green,
      AttendanceStatus.terlambat => Colors.orange,
      AttendanceStatus.tidakHadir => Colors.red,
      AttendanceStatus.izin => Colors.blue,
      AttendanceStatus.sakit => Colors.purple,
    };
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final currentFilter = ref.read(attendanceFilterProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentFilter.date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    ref.read(attendanceFilterProvider.notifier).state = currentFilter.copyWith(date: picked);
  }

  Future<void> _openStatusSheet(
    BuildContext context,
    WidgetRef ref,
    AttendanceRecord record,
  ) async {
    final selected = await showModalBottomSheet<AttendanceStatus>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ubah status: ${record.studentName}', style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final status in AttendanceStatus.values)
                ListTile(
                  leading: Icon(Icons.circle, color: _statusColor(status), size: 14),
                  title: Text(status.label),
                  trailing: record.status == status ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(status),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == record.status || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Perubahan'),
        content: Text(
          'Ubah status ${record.studentName} dari "${record.status.label}" '
          'menjadi "${selected.label}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ubah')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref.read(attendanceActionControllerProvider.notifier).updateStatus(record.id, selected);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Status berhasil diubah' : 'Gagal mengubah status')),
    );
  }

  Future<void> _openReportSheet(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(attendanceFilterProvider);
    DateTime start = filter.date;
    DateTime end = filter.date;
    String format = 'excel';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Export Laporan', style: Theme.of(sheetContext).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'excel', label: Text('Excel')),
                      ButtonSegment(value: 'pdf', label: Text('PDF')),
                    ],
                    selected: {format},
                    onSelectionChanged: (value) => setSheetState(() => format = value.first),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dari tanggal'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(start)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: start,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setSheetState(() => start = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sampai tanggal'),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(end)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: end,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setSheetState(() => end = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setSheetState(() => isSubmitting = true);

                            final success = await ref.read(reportControllerProvider.notifier).downloadAndOpen(
                                  format: format,
                                  startDate: start,
                                  endDate: end,
                                  classId: filter.classId,
                                );

                            if (!sheetContext.mounted) return;

                            setSheetState(() => isSubmitting = false);

                            if (success) {
                              Navigator.of(sheetContext).pop();
                            } else {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text('Gagal membuat laporan')),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Download & Buka'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceListProvider);
    final filter = ref.watch(attendanceFilterProvider);
    final classesAsync = ref.watch(classesListProvider);
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final isGuru = currentUser?.isGuru ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _openReportSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, ref),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd MMM yyyy').format(filter.date)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: classesAsync.when(
                    data: (classes) {
      
                      if (isGuru && classes.length <= 1) {
                        return const SizedBox.shrink();
                      }
                      return DropdownButtonFormField<int?>(
                        initialValue: filter.classId,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          labelText: 'Kelas',
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                          ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (value) {
                          ref.read(attendanceFilterProvider.notifier).state =
                              filter.copyWith(classId: value, clearClassId: value == null);
                        },
                      );
                    },
                    loading: () => const SizedBox(height: 48),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(attendanceListProvider);
                await ref.read(attendanceListProvider.future);
              },
              child: attendanceAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Belum ada data presensi untuk tanggal ini')),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Card(
                        child: ListTile(
                          title: Text(record.studentName),
                          subtitle: Text(
                            '${record.className} • '
                            '${record.checkInTime != null ? DateFormat('HH:mm').format(record.checkInTime!) : 'Belum tap'}',
                          ),
                          trailing: Chip(
                            label: Text(record.status.label, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: _statusColor(record.status),
                            padding: EdgeInsets.zero,
                          ),
                          onTap: () => _openStatusSheet(context, ref, record),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) {
                  final message = error is ForbiddenException
                      ? 'Anda tidak punya akses ke data ini'
                      : 'Gagal memuat data presensi';
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(message),
                        TextButton(
                          onPressed: () => ref.invalidate(attendanceListProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}