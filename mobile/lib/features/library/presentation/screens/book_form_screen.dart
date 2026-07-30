import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../widgets/barcode_scanner_sheet.dart';
import '../../domain/entities/book_entity.dart';
import '../providers/library_provider.dart';

class BookFormScreen extends ConsumerStatefulWidget {
  const BookFormScreen({super.key, this.book});

  final BookEntity? book;

  bool get isEditMode => book != null;

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _barcodeController;
  late final TextEditingController _titleController;
  late BookCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.book?.barcode ?? '');
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _selectedCategory = widget.book?.category ?? BookCategory.umum;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _mapErrorMessage(Object error) {
    return switch (resolveAppException(error)) {
      BadRequestException(:final message) => message,
      ConflictException(:final message) => message,
      ForbiddenException() => 'Anda tidak punya akses untuk aksi ini',
      UnauthorizedException() => 'Sesi berakhir, silakan login ulang',
      NetworkException() => 'Tidak bisa terhubung ke server',
      _ => 'Gagal menyimpan data buku',
    };
  }

  Future<void> _scanBarcode() async {
    final result = await showBarcodeScanner(context);
    if (result != null && mounted) {
      setState(() => _barcodeController.text = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(bookControllerProvider.notifier);
    final bool success;

    if (widget.isEditMode) {
      success = await controller.updateBook(
        widget.book!.id,
        title: _titleController.text.trim(),
        category: _selectedCategory,
      );
    } else {
      success = await controller.createBook(
        barcode: _barcodeController.text.trim(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditMode ? 'Buku diperbarui' : 'Buku ditambahkan')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(bookControllerProvider);
    final isSubmitting = formState.isLoading;

    ref.listen(bookControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditMode ? 'Edit Buku' : 'Tambah Buku')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _barcodeController,
                readOnly: widget.isEditMode, // barcode tidak bisa diubah setelah dibuat
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  border: const OutlineInputBorder(),
                  helperText: widget.isEditMode ? 'Barcode tidak bisa diubah' : null,
                  suffixIcon: widget.isEditMode
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          tooltip: 'Scan barcode buku',
                          onPressed: _scanBarcode,
                        ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Barcode wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Buku', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Judul wajib diisi';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BookCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: BookCategory.umum, child: Text('Umum (komik, novel, dll)')),
                  DropdownMenuItem(value: BookCategory.pelajaran, child: Text('Pelajaran / Paket')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isEditMode ? 'Simpan Perubahan' : 'Tambah Buku'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}