import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';
import 'student_form_screen.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  String _query = '';

  List<StudentEntity> _filter(List<StudentEntity> students) {
    if (_query.trim().isEmpty) return students;
    final q = _query.toLowerCase();
    return students.where((s) {
      return s.name.toLowerCase().contains(q) || s.nis.toLowerCase().contains(q);
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

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siswa'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIS...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
                filled: true,
              ),
              onChanged: (value) => setState(() => _query = value),
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