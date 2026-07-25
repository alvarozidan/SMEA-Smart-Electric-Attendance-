import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/managed_user_entity.dart';
import '../providers/user_management_provider.dart';
import 'user_form_screen.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    ManagedUserEntity user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan Akun'),
        content: Text(
          'Nonaktifkan akun ${user.name}? Akun ini tidak akan bisa login kembali '
          'sampai diaktifkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), 
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), 
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success =
      await ref.read(userFormControllerProvider.notifier).deactivateUser(user.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Akun berhasil dinonaktifkan' : 'Gagal menonaktifkan akun')),
    );
  }

  Future<void> _reactivate(
    BuildContext context,
    WidgetRef ref,
    ManagedUserEntity user
  ) async {
    final success =
      await ref.read(userFormControllerProvider.notifier).reactiveUser(user.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Akun berhasil diaktifkan' : 'Gagal mengaktifkan akun')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(managedUsersListProvider);
    final includeInactive = ref.watch(includeInactiveUsersProvider);
    final currentUserId = ref.watch(authNotifierProvider).valueOrNull?.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun Guru & Admin'),
        actions: [
          IconButton(
            icon: Icon(includeInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: includeInactive ? 'Sembunyikan nonaktif' : 'Tampilkan nonaktif',
            onPressed: () {
              ref.read(includeInactiveUsersProvider.notifier).state = !includeInactive;
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(managedUsersListProvider);
          await ref.read(managedUsersListProvider.future);
        },
        child: usersAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada akun')),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelf = user.id == currentUserId;

                return Card(
                  color: user.isActive ? null : Colors.grey.shade200,
                  child: ListTile(
                    title: Text(user.name),
                    subtitle: Text(
                      '${user.email} • ${user.role == UserRole.admin ? 'Admin' : 'Guru'}'
                      '${user.isActive ? '' : ' • Nonaktif'}'
                      '${isSelf ? ' • Anda' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
                            );
                          },
                        ),
                        if (!isSelf)
                          user.isActive
                              ? IconButton(
                                  icon: const Icon(Icons.block, color: Colors.red),
                                  tooltip: 'Nonaktifkan',
                                  onPressed: () => _confirmDeactivate(context, ref, user),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.restart_alt, color: Colors.green),
                                  tooltip: 'Aktifkan kembali',
                                  onPressed: () => _reactivate(context, ref, user),
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
                const Text('Gagal memuat data akun'),
                TextButton(
                  onPressed: () => ref.invalidate(managedUsersListProvider),
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