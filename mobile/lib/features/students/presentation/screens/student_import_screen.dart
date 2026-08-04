import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/student_import_result_entity.dart';
import '../providers/students_provider.dart';

class StudentImportScreen extends ConsumerStatefulWidget {
  const StudentImportScreen({super.key});

  @override
  ConsumerState<StudentImportScreen> createState() => _StudentImportScreenState();
}

class _StudentImportScreenState extends ConsumerState<StudentImportScreen> {
  String? _pickedFileName;
  String? _pickedFilePath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _pickedFileName = result.files.single.name;
      _pickedFilePath = result.files.single.path;
    });
  }

  Future<void> _startImport() async {
    if (_pickedFilePath == null) return;
    await ref.read(studentImportControllerProvider.notifier).importFile(_pickedFilePath!);
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(studentImportControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Data Siswa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload file .xlsx dengan kolom: nis, name, class_name. '
              'Nama kelas harus persis sama dengan data kelas yang sudah ada di sistem.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(_pickedFileName ?? 'Pilih File Excel (.xlsx)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _pickedFilePath == null || importState.isLoading ? null : _startImport,
              child: importState.isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mulai Import'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: importState.when(
                data: (result) => result == null ? const SizedBox.shrink() : _ImportResultView(result: result),
                loading: () => const SizedBox.shrink(),
                error: (error, _) =>
                    Center(child: Text('Import gagal: $error', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportResultView extends StatelessWidget {
  const _ImportResultView({required this.result});
  final StudentImportResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total: ${result.totalRows} baris • Berhasil: ${result.successCount} • Gagal: ${result.failedCount}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (result.failed.isNotEmpty)
          Expanded(
            child: ListView.separated(
              itemCount: result.failed.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = result.failed[index];
                return ListTile(
                  dense: true,
                  leading: Text('#${row.row}'),
                  title: Text(row.name ?? row.nis ?? '(baris kosong)'),
                  subtitle: Text(row.reason, style: const TextStyle(color: Colors.red)),
                );
              },
            ),
          ),
      ],
    );
  }
}