import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(), 
            icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Center(
        child: Text(
          'Login berhasil\nuserId: ${user?.userId}\nrole: ${user?.role}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ), 
      ),
    );
  }
}