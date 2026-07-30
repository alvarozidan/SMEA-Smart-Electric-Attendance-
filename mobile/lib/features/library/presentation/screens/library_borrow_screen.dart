import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/error/app_exception.dart';
import '../../../devices/domain/entities/device_entity.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../../domain/entities/loan_entity.dart';
import '../providers/library_provider.dart';

class LibraryBorrowScreen extends ConsumerStatefulWidget {
  const LibraryBorrowScreen({super.key});

  @override
  ConsumerState<LibraryBorrowScreen> createState() => _LibraryBorrowScreenState();
}

enum _BorrowStep { scanBooks, waitRfid }

class _LibraryBorrowScreenState extends ConsumerState<LibraryBorrowScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final List<String> _scannedBarcodes = [];

  _BorrowStep _step = _BorrowStep.scanBooks;
  int? _selectedDeviceId;
  String? _detectedRfidUid;

  Timer? _pollTimer;
  final DateTime _sessionStart = DateTime.now();
  DateTime? _lastAppliedScanTime;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    if (_scannedBarcodes.contains(value)) return;

    setState(() => _scannedBarcodes.add(value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buku ditambahkan: $value'), duration: const Duration(seconds: 1)),
    );
  }

  void _removeBarcode(String value) {
    setState(() => _scannedBarcodes.remove(value));
  }

  void _goToRfidStep() {
    if (_scannedBarcodes.isEmpty) return;
    setState(() => _step = _BorrowStep.waitRfid);
  }

  void _backToScanStep() {
    _pollTimer?.cancel();
    setState(() {
      _step = _BorrowStep.scanBooks;
      _detectedRfidUid = null;
    });
  }

  void _startListening(int deviceId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollLastScan(deviceId));
  }

  Future<void> _pollLastScan(int deviceId) async {
    if (!mounted) return;

    final LibraryScanResult? result;
    try {
      result = await ref.read(libraryRepositoryProvider).getLastScan(deviceId);
    } catch (_) {
      return;
    }

    if (result == null || !mounted) return;

    final isNew = result.scannedAt.isAfter(_sessionStart) &&
        (_lastAppliedScanTime == null || result.scannedAt.isAfter(_lastAppliedScanTime!));
    if (!isNew) return;

    _pollTimer?.cancel();
    setState(() {
      _detectedRfidUid = result!.rfidUid;
      _lastAppliedScanTime = result.scannedAt;
    });
  }

  String _mapErrorMessage(Object error) {
    return switch (resolveAppException(error)) {
      BadRequestException(:final message) => message,
      ConflictException(:final message) => message,
      NotFoundException(:final message) => message,
      ForbiddenException() => 'Anda tidak punya akses untuk aksi ini',
      UnauthorizedException() => 'Sesi berakhir, silakan login ulang',
      NetworkException() => 'Tidak bisa terhubung ke server',
      _ => 'Peminjaman gagal',
    };
  }

  Future<void> _submit() async {
    if (_detectedRfidUid == null) return;

    final results = await ref.read(libraryTransactionControllerProvider.notifier).borrow(
          rfidUid: _detectedRfidUid!,
          bookBarcodes: _scannedBarcodes,
        );

    if (results != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${results.length} buku berhasil dipinjamkan')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(libraryTransactionControllerProvider);
    final isSubmitting = formState.isLoading;

    ref.listen(libraryTransactionControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Peminjaman Buku')),
      body: _step == _BorrowStep.scanBooks ? _buildScanBooksStep() : _buildWaitRfidStep(isSubmitting),
    );
  }

  Widget _buildScanBooksStep() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: MobileScanner(controller: _cameraController, onDetect: _onBarcodeDetected),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Buku dipindai (${_scannedBarcodes.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: _scannedBarcodes.isEmpty
                    ? const Center(child: Text('Arahkan kamera ke barcode buku'))
                    : ListView.builder(
                        itemCount: _scannedBarcodes.length,
                        itemBuilder: (context, index) {
                          final barcode = _scannedBarcodes[index];
                          return ListTile(
                            leading: const Icon(Icons.menu_book_outlined),
                            title: Text(barcode),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeBarcode(barcode),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _scannedBarcodes.isEmpty ? null : _goToRfidStep,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Lanjut: Tap Kartu RFID Siswa'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitRfidStep(bool isSubmitting) {
    final devicesAsync = ref.watch(devicesListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_scannedBarcodes.length} buku siap dipinjamkan',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(_scannedBarcodes.join(', ')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          devicesAsync.when(
            data: (devices) {
              final eligible = devices
                  .where((d) => d.deviceType == DeviceType.perpustakaan && d.status == DeviceStatus.online)
                  .toList();

              if (eligible.isEmpty) {
                return const Card(
                  color: Colors.amber,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Tidak ada device perpustakaan yang online. '
                      'Pastikan ESP32 sudah diset device_type = PERPUSTAKAAN dan terhubung.',
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<int>(
                initialValue: _selectedDeviceId,
                decoration: const InputDecoration(labelText: 'Device Perpustakaan', border: OutlineInputBorder()),
                items: eligible.map((d) => DropdownMenuItem(value: d.id, child: Text(d.deviceCode))).toList(),
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
          if (_selectedDeviceId != null)
            Card(
              color: _detectedRfidUid != null
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              child: ListTile(
                leading: _detectedRfidUid != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                title: Text(_detectedRfidUid != null
                    ? 'Kartu terdeteksi: $_detectedRfidUid'
                    : 'Menunggu siswa tap kartu RFID...'),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_detectedRfidUid == null || isSubmitting) ? null : _submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Pinjamkan Buku'),
          ),
          TextButton(onPressed: _backToScanStep, child: const Text('Kembali, scan ulang buku')),
        ],
      ),
    );
  }
}