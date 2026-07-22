import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../devices/domain/entities/device_entity.dart';
import '../../../devices/domain/entities/scan_result.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../providers/rfid_provider.dart';

class RfidBindScreen extends ConsumerStatefulWidget {
  const RfidBindScreen({super.key, required this.student, required this.type});

  final StudentEntity student;
  final String type;

  @override
  ConsumerState<RfidBindScreen> createState() => _RfidBindScreenState();
}

class _RfidBindScreenState extends ConsumerState<RfidBindScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  int? _selectedDeviceId;

  Timer? _pollTimer;
  final DateTime _sessionStart = DateTime.now();
  DateTime? _lastAppliedScanTime;
  bool _isWaitingForTap = false;

  bool get _isRfid => widget.type == 'rfid';

  @override
  void dispose() {
    _pollTimer?.cancel();
    _valueController.dispose();
    super.dispose();
  }

  void _startListening(int deviceId) {
    if (!_isRfid) return;

    _pollTimer?.cancel();
    setState(() => _isWaitingForTap = true);

    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollLastScan(deviceId));
  }

  void _stopListening() {
    _pollTimer?.cancel();
    setState(() => _isWaitingForTap = false);
  }

  Future<void> _pollLastScan(int deviceId) async {
    if (!mounted) return;

    final ScanResult? result;
    try {
      result = await ref.read(devicesRepositoryProvider).getLastScan(deviceId);
    } catch (_) {
      return; 
    }

    if (result == null || !mounted) return;

    final isNew = result.scannedAt.isAfter(_sessionStart) &&
        (_lastAppliedScanTime == null || result.scannedAt.isAfter(_lastAppliedScanTime!));

    if (!isNew) return;

    setState(() {
      _valueController.text = result!.value;
      _lastAppliedScanTime = result.scannedAt;
      _isWaitingForTap = false;
    });
    _pollTimer?.cancel();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kartu terdeteksi!'), duration: Duration(seconds: 2)),
      );
    }
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

    ref.listen(rfidActionControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRfid ? 'Daftarkan RFID' : 'Daftarkan Fingerprint'),
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
                    onChanged: (value) {
                      setState(() => _selectedDeviceId = value);
                      if (value != null) _startListening(value);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Text('Gagal memuat daftar device'),
              ),
              const SizedBox(height: 16),
              if (_isRfid && _selectedDeviceId != null) ...[
                _ListeningIndicator(
                  isWaiting: _isWaitingForTap,
                  hasValue: _valueController.text.isNotEmpty,
                  onRescan: () {
                    _valueController.clear();
                    _startListening(_selectedDeviceId!);
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _valueController,
                readOnly: false, 
                keyboardType: _isRfid ? TextInputType.text : TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isRfid ? 'RFID UID' : 'Index Fingerprint',
                  hintText: _isRfid ? 'Otomatis terisi saat kartu di-tap, atau isi manual' : 'Isi manual',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_pollTimer?.isActive ?? false) _stopListening();
                },
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

class _ListeningIndicator extends StatelessWidget {
  const _ListeningIndicator({required this.isWaiting, required this.hasValue, required this.onRescan});

  final bool isWaiting;
  final bool hasValue;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    if (hasValue) {
      return Card(
        color: Colors.green.withValues(alpha: 0.1),
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: const Text('Kartu terdeteksi'),
          trailing: TextButton(onPressed: onRescan, child: const Text('Scan Ulang')),
        ),
      );
    }

    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: const ListTile(
        leading: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Menunggu kartu di-tap ke device...'),
      ),
    );
  }
}