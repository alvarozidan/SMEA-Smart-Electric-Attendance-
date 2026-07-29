import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/loan_entity.dart';
import '../providers/library_provider.dart';

class LibraryReturnScreen extends ConsumerStatefulWidget {
  const LibraryReturnScreen({super.key});

  @override
  ConsumerState<LibraryReturnScreen> createState() => _LibraryReturnScreenState();
}

class _LibraryReturnScreenState extends ConsumerState<LibraryReturnScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final _dateFormat = DateFormat('d MMM yyyy');

  String? _scannedBarcode;
  bool _isScanning = true;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() {
      _scannedBarcode = value;
      _isScanning = false;
    });
  }

  void _rescan() {
    setState(() {
      _scannedBarcode = null;
      _isScanning = true;
    });
  }

  String _mapErrorMessage(Object error) {
    return switch (error) {
      BadRequestException(:final message) => message,
      ConflictException(:final message) => message,
      NotFoundException(:final message) => message,
      ForbiddenException() => 'Anda tidak punya akses untuk aksi ini',
      NetworkException() => 'Tidak bisa terhubung ke server',
      _ => 'Gagal memproses transaksi',
    };
  }

  Future<void> _returnBook(String barcode) async {
    final result = await ref.read(libraryTransactionControllerProvider.notifier).returnBook(barcode);
    if (result != null && mounted) {
      final overdueText = result.overdueDays > 0 ? ', terlambat ${result.overdueDays} hari' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buku dikembalikan$overdueText')),
      );
      _rescan();
    }
  }

  Future<void> _extendBook(String barcode) async {
    final result = await ref.read(libraryTransactionControllerProvider.notifier).extendLoan(barcode);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diperpanjang sampai ${_dateFormat.format(result.dueDate)}')),
      );
      _rescan();
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
      appBar: AppBar(title: const Text('Pengembalian / Perpanjangan')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _isScanning
                ? MobileScanner(controller: _cameraController, onDetect: _onBarcodeDetected)
                : const Center(child: Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: _scannedBarcode == null
                ? const Center(child: Text('Arahkan kamera ke barcode buku'))
                : _buildLoanDetail(_scannedBarcode!, isSubmitting),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetail(String barcode, bool isSubmitting) {
    final loansAsync = ref.watch(activeLoansProvider);

    return loansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat data pinjaman aktif'),
            TextButton(onPressed: _rescan, child: const Text('Scan Ulang')),
          ],
        ),
      ),
      data: (loans) {
        final matches = loans.where((l) => l.bookBarcode == barcode);
        final loan = matches.isEmpty ? null : matches.first;

        if (loan == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text('Barcode "$barcode" tidak ada transaksi peminjaman aktif'),
                const SizedBox(height: 12),
                TextButton(onPressed: _rescan, child: const Text('Scan Ulang')),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: loan.isOverdue ? Colors.red.withValues(alpha: 0.08) : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.bookTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${loan.studentName} (${loan.studentNis})'),
                      const SizedBox(height: 8),
                      Text('Tenggat: ${_dateFormat.format(loan.dueDate)}'),
                      if (loan.isOverdue)
                        Text(
                          'Terlambat ${loan.overdueDaysLive} hari',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      Text('Sudah diperpanjang: ${loan.extensionCount}x'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isSubmitting ? null : () => _returnBook(barcode),
                icon: const Icon(Icons.assignment_return_outlined),
                label: const Text('Kembalikan'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: (!loan.canExtend || isSubmitting) ? null : () => _extendBook(barcode),
                icon: const Icon(Icons.update),
                label: Text(_extendDisabledReason(loan) ?? 'Perpanjang (+7 hari)'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _rescan, child: const Text('Scan Buku Lain')),
            ],
          ),
        );
      },
    );
  }

  String? _extendDisabledReason(LoanEntity loan) {
    if (loan.isOverdue) return 'Tidak bisa diperpanjang (sudah telat)';
    if (loan.extensionCount >= 1) return 'Sudah pernah diperpanjang';
    if (!loan.canExtend) return 'Buku pelajaran tidak bisa diperpanjang';
    return null;
  }
}