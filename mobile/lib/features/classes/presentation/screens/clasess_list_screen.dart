import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/class_provider.dart';
import 'class_form_screen.dart';

class ClassesListScreen extends ConsumerWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classesListProvider);
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final isAdmin = currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelas')),
    
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClassFormScreen()),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(classesListProvider);
          await ref.read(classesListProvider.future);
        },
        child: classesAsync.when(
          data: (classes) {
            if (classes.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada kelas')),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final classItem = classes[index];
                return Card(
                  child: ListTile(
                    title: Text(classItem.name),
                    subtitle: Text(
                      'Jam masuk: ${classItem.checkInStart ?? '-'} • '
                      'Batas: ${classItem.checkInDeadline ?? '-'}',
                    ),
                    trailing: isAdmin
                        ? IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClassFormScreen(classItem: classItem),
                                ),
                              );
                            },
                          )
                        : null,
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
                const Text('Gagal memuat data kelas'),
                TextButton(
                  onPressed: () => ref.invalidate(classesListProvider),
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