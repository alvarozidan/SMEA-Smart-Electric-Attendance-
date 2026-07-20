import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/class_entity.dart';
import '../providers/class_provider.dart';

class ClassFormScreen extends ConsumerStatefulWidget {
  const ClassFormScreen({super.key, this.classItem});

  final ClassEntity? classItem;

  bool get isEditMode => classItem != null;

  @override
  ConsumerState<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends ConsumerState<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _checkInStart;
  String? _checkInDeadline;
  int? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.classItem?.name ?? '');
    _checkInStart = widget.classItem?.checkInStart;
    _checkInDeadline = widget.classItem?.checkInDeadline;
    _selectedTeacherId = widget.classItem?.homeroomTeacherId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _checkInStart : _checkInDeadline;
    final initial = _parseTimeOfDay(current) ?? const TimeOfDay(hour: 7, minute: 0);

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      if (isStart) {
        _checkInStart = formatted;
      } else {
        _checkInDeadline = formatted;
      }
    });
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _mapErrorMessage(Object error) {
    return switch (error) {
      ForbiddenException() => 'Anda tidak punya akses untuk aksi ini',
      NetworkException() => 'Tidak bisa terhubung ke server',
      _ => 'Gagal menyimpan data, silakan coba lagi',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_checkInStart == null || _checkInDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam masuk dan batas hadir wajib diisi')),
      );
      return;
    }

    final controller = ref.read(classFormControllerProvider.notifier);
    final bool success;

    if (widget.isEditMode) {
      success = await controller.updateClass(
        widget.classItem!.id,
        name: _nameController.text.trim(),
        checkInStart: _checkInStart,
        checkInDeadline: _checkInDeadline,
        homeroomTeacherId: _selectedTeacherId,
      );
    } else {
      success = await controller.createClass(
        name: _nameController.text.trim(),
        checkInStart: _checkInStart!,
        checkInDeadline: _checkInDeadline!,
        homeroomTeacherId: _selectedTeacherId,
      );
    }

    if (success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(classFormControllerProvider);
    final teachersAsync = ref.watch(teacherOptionsProvider);
    final isSubmitting = formState.isLoading;

    ref.listen(classFormControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? 'Edit Kelas' : 'Tambah Kelas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelas (contoh: 7A)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Nama kelas wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _TimePickerField(
                label: 'Jam Mulai Presensi',
                value: _checkInStart,
                onTap: () => _pickTime(isStart: true),
              ),
              const SizedBox(height: 16),
              _TimePickerField(
                label: 'Batas Hadir Tepat Waktu',
                value: _checkInDeadline,
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 16),
              teachersAsync.when(
                data: (teachers) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'Wali Kelas (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Belum ditentukan')),
                      ...teachers.map(
                        (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedTeacherId = value),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Text('Gagal memuat daftar guru'),
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
                    : Text(widget.isEditMode ? 'Simpan Perubahan' : 'Tambah Kelas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({required this.label, required this.value, required this.onTap});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(value ?? 'Pilih jam'),
      ),
    );
  }
}