import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import 'student_form_screen.dart';
import '../../../rfid/presentation/screens/rfid_bind_screen.dart';
import '../../../rfid/presentation/providers/rfid_provider.dart';
import '../../../classes/presentation/providers/class_provider.dart';
import 'student_import_screen.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _query = '';
  int? _selectedClassId;

  List<StudentEntity> _filter(List<StudentEntity> students) {
    final query = _query.trim().toLowerCase();

    return students.where((student) {
      final matchesQuery = query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.nis.toLowerCase().contains(query);

      final matchesClass = _selectedClassId == null || student.classId == _selectedClassId;

      return matchesQuery && matchesClass;
    }).toList();
  }

  Future<void> _confirmDelete(StudentEntity student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text(
          'Hapus ${student.name}? Data absensi historis tetap tersimpan, '
          'tapi RFID/sidik jari yang terpasang akan otomatis dilepas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(studentFormControllerProvider.notifier)
        .deleteStudent(student.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Siswa berhasil dihapus' : 'Gagal menghapus siswa')),
    );
  }

  Future<void> _openCredentialSheet(
    BuildContext context,
    WidgetRef ref,
    StudentEntity student,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Kredensial: ${student.name}', style: Theme.of(sheetContext).textTheme.titleMedium),
              ),
              ListTile(
                leading: Icon(Icons.credit_card, color: student.hasRfid ? Colors.green : Colors.grey),
                title: Text(student.hasRfid ? 'RFID: ${student.rfidUid}' : 'RFID belum terpasang'),
                trailing: student.hasRfid
                    ? TextButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          await _confirmUnbindRfid(context, ref, student);
                        },
                        child: const Text('Lepas'),
                      )
                    : TextButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RfidBindScreen(student: student, type: 'rfid'),
                            ),
                          );
                        },
                        child: const Text('Daftarkan'),
                      ),
              ),
              ListTile(
                leading: Icon(Icons.fingerprint, color: student.hasFingerprint ? Colors.green : Colors.grey),
                title: Text(
                  student.hasFingerprint ? 'Fingerprint terpasang' : 'Fingerprint belum terpasang',
                ),
                // Backend belum ada endpoint unbind fingerprint (lihat
                // kontrak awal) -- jadi kalau sudah terpasang, tidak ada
                // aksi yang bisa ditawarkan, cukup informasi status saja.
                trailing: student.hasFingerprint
                    ? null
                    : TextButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RfidBindScreen(student: student, type: 'fingerprint'),
                            ),
                          );
                        },
                        child: const Text('Daftarkan'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmUnbindRfid(
    BuildContext context,
    WidgetRef ref,
    StudentEntity student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lepas RFID'),
        content: Text('Lepas RFID milik ${student.name}? Siswa perlu didaftarkan ulang kalau ingin dipakai lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Lepas')),
        ],
      ),
    );

    if (confirmed != true || student.rfidUid == null || !mounted) return;

    final success = await ref.read(rfidActionControllerProvider.notifier).unbindRfid(student.rfidUid!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'RFID berhasil dilepas' : 'Gagal melepas RFID')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);
    final classesAsync = ref.watch(classesListProvider);

    final filteredStudentCount = studentsAsync.valueOrNull == null ? null : _filter(studentsAsync.valueOrNull!).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import dari Excel',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentImportScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Cari nama atau NIS...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 8),
                classesAsync.when(
                  data: (classes) => DropdownButtonFormField<int?>(
                    value: _selectedClassId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Filter kelas",
                      border: OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Semua kelas"),
                      ),
                      ...classes.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                          setState(() => _selectedClassId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 6),
                if (filteredStudentCount != null)
                Align (
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Jumlah siswa: $filteredStudentCount",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StudentFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studentsListProvider);
          await ref.read(studentsListProvider.future);
        },
        child: studentsAsync.when(
          data: (students) {
            final filtered = _filter(students);

            if (filtered.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Tidak ada siswa ditemukan')),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final student = filtered[index];
               return Card(
                  child: ListTile(
                    title: Text(student.name),
                    subtitle: Text(
                      'NIS: ${student.nis}${student.className != null ? ' • ${student.className}' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.credit_card,
                            color: student.hasRfid ? Colors.green : Colors.grey,
                          ),
                          tooltip: student.hasRfid ? 'RFID terpasang' : 'RFID belum terpasang',
                          onPressed: () => _openCredentialSheet(context, ref, student),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentFormScreen(student: student),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(student),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                const Text('Gagal memuat data siswa'),
                TextButton(
                  onPressed: () => ref.invalidate(studentsListProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}