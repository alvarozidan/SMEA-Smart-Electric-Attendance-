import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../devices/domain/entities/device_entity.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../providers/rfid_provider.dart';

/// [student] wajib -- entry point-nya selalu dari student_list_screen,
/// jadi konteks siswa sudah pasti ada, tidak perlu dropdown pilih siswa
/// lagi di sini (mengurangi kemungkinan Admin salah pilih siswa).
class RfidBindScreen extends ConsumerStatefulWidget {
  const RfidBindScreen({super.key, required this.student, required this.type});

  final StudentEntity student;
  /// 'rfid' | 'fingerprint'
  final String type;

  @override
  ConsumerState<RfidBindScreen> createState() => _RfidBindScreenState();
}

class _RfidBindScreenState extends ConsumerState<RfidBindScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  int? _selectedDeviceId;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(Object error) {
    return switch (error) {
      ConflictException(:final message) => message,
      ForbiddenException() => 'Anda tidak punya akses untuk aksi ini',
      NetworkException() => 'Tidak bisa terhubung ke server',
      _ => 'Gagal mendaftarkan kredensial',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih device terlebih dahulu')),
      );
      return;
    }

    final success = await ref.read(rfidActionControllerProvider.notifier).register(
          studentId: widget.student.id,
          deviceId: _selectedDeviceId!,
          type: widget.type,
          value: _valueController.text.trim(),
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kredensial berhasil didaftarkan')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(rfidActionControllerProvider);
    final devicesAsync = ref.watch(devicesListProvider);
    final isSubmitting = formState.isLoading;
    final isFingerprint = widget.type == 'fingerprint';

    ref.listen(rfidActionControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isFingerprint ? 'Daftarkan Fingerprint' : 'Daftarkan RFID'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 8),
                      Text('${widget.student.name} (${widget.student.nis})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              devicesAsync.when(
                data: (devices) {
                  // Cuma tampilkan device yang online DAN mode registrasi
                  // aktif -- sesuai business rule #6 & #7. Kalau tidak ada
                  // device yang eligible, kasih tau eksplisit alih-alih
                  // dropdown kosong yang membingungkan.
                  final eligible = devices
                      .where((d) => d.status == DeviceStatus.online && d.registrationMode)
                      .toList();

                  if (eligible.isEmpty) {
                    return const Card(
                      color: Colors.amber,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Tidak ada device yang siap (harus online & mode registrasi aktif). '
                          'Aktifkan mode registrasi di halaman Perangkat terlebih dahulu.',
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedDeviceId,
                    decoration: const InputDecoration(
                      labelText: 'Device',
                      border: OutlineInputBorder(),
                    ),
                    items: eligible
                        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.deviceCode)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDeviceId = value),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Text('Gagal memuat daftar device'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                keyboardType: isFingerprint ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  labelText: isFingerprint ? 'Index Fingerprint' : 'RFID UID',
                  hintText: isFingerprint
                      ? 'Lihat index di layar OLED device'
                      : 'Lihat UID di layar OLED device',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Daftarkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}