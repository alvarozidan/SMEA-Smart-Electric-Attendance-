import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/book_entity.dart';
import '../providers/library_provider.dart';
import 'book_form_screen.dart';
import 'library_borrow_screen.dart';
import 'library_return_screen.dart';

class BooksListScreen extends ConsumerStatefulWidget {
  const BooksListScreen({super.key});

  @override
  ConsumerState<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends ConsumerState<BooksListScreen> {
  String _query = '';

  List<BookEntity> _filter(List<BookEntity> books) {
    if (_query.trim().isEmpty) return books;
    final q = _query.toLowerCase();
    return books.where((b) {
      return b.title.toLowerCase().contains(q) || b.barcode.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(BookEntity book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Hapus "${book.title}"? Tidak bisa dihapus kalau sedang dipinjam atau punya riwayat pinjam.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref.read(bookControllerProvider.notifier).deleteBook(book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Buku berhasil dihapus' : 'Gagal menghapus buku')),
    );
  }

  Future<void> _printLabel(BookEntity book) async {
    final bytes = await ref.read(bookLabelControllerProvider.notifier).fetchLabelPdf(book.barcode);
    if (!mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat label. Coba lagi.')),
      );
      return;
    }

    await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Buku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(), 
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari judul atau barcode...',
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Perpustakaan')),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text("Katalog Buku"),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text("Peminjaman Buku"),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LibraryBorrowScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_return_outlined),
              title: const Text("Pengembalian / Perpanjangan"),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LibraryReturnScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: booksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Gagal memuat katalog buku')),
        data: (books) {
          final filtered = _filter(books);
          if (filtered.isEmpty) {
            return const Center(child: Text('Belum ada buku terdaftar'));
          }

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final book = filtered[index];
              final isBorrowed = book.status == BookStatus.dipinjam;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBorrowed
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  child: Icon(
                    isBorrowed ? Icons.book : Icons.check,
                    color: isBorrowed ? Colors.orange : Colors.green,
                  ),
                ),
                title: Text(book.title),
                subtitle: Text(
                  '${book.barcode} · ${book.category == BookCategory.umum ? "Umum" : "Pelajaran"} · '
                  '${isBorrowed ? "Dipinjam" : "Tersedia"}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BookFormScreen(book: book)),
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(book);
                    } else if (value == 'label') {
                      _printLabel(book);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'label', child: Text('Cetak Label')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookFormScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}