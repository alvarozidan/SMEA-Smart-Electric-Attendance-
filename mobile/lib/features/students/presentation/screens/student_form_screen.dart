import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../classes/presentation/providers/class_provider.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/students_provider.dart';

/// null = mode tambah, terisi = mode edit.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.student});

  final StudentEntity? student;

  bool get isEditMode => student != null;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nisController;
  late final TextEditingController _nameController;
  int? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _nisController = TextEditingController(text: widget.student?.nis ?? '');
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _selectedClassId = widget.student?.classId;
  }

  @override
  void dispose() {
    _nisController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(Object error) {
    return switch (error) {
      ConflictException(:final message) => message,
      ForbiddenException() => 'Anda tidak punya akses untuk aksi ini',
      NetworkException() => 'Tidak bisa terhubung ke server',
      _ => 'Gagal menyimpan data, silakan coba lagi',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(studentFormControllerProvider.notifier);
    final bool success;

    if (widget.isEditMode) {
      success = await controller.updateStudent(
        widget.student!.id,
        nis: _nisController.text.trim(),
        name: _nameController.text.trim(),
        classId: _selectedClassId,
      );
    } else {
      success = await controller.createStudent(
        nis: _nisController.text.trim(),
        name: _nameController.text.trim(),
        classId: _selectedClassId,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(studentFormControllerProvider);
    final classesAsync = ref.watch(classesListProvider);
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final isGuru = currentUser?.isGuru ?? false;
    final isSubmitting = formState.isLoading;

    ref.listen(studentFormControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Siswa' : 'Tambah Siswa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nisController,
                decoration: const InputDecoration(
                  labelText: 'NIS',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'NIS wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Nama wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              classesAsync.when(
                data: (classes) {
                  if (isGuru && classes.length == 1) {
                    _selectedClassId ??= classes.first.id;
                    return InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(classes.first.name),
                    );
                  }

                  if (classes.isEmpty) {
                    return const Text('Belum ada kelas tersedia');
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Kelas',
                      border: OutlineInputBorder(),
                    ),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedClassId = value),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Text('Gagal memuat daftar kelas'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditMode ? 'Simpan Perubahan' : 'Tambah Siswa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}