import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/status_summary_grid.dart';
import '../widgets/attendance_trend_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(dashboardTrendProvider);
    await Future.wait([
      ref.read(dashboardSummaryProvider.future),
      ref.read(dashboardTrendProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final trendAsync = ref.watch(dashboardTrendProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(), 
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Smart Attendance')),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Siswa'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/students');
              },
            ),
             ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Kelas'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/classes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Presensi'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/attendance');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref), 
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Selamat Datang, ${user?.role.name ?? ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) => StatusSummaryGrid(
                counts: summary.statusCounts, 
                notYetRecorded: summary.notYetRecorded,
              ),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => _ErrorRetry(
                message: 'Gagal memuat ringkasan',
                onRetry: () => ref.invalidate(dashboardSummaryProvider),
              ),
            ),
            const SizedBox(height: 24),
            Text('Trend 7 Hari Terakhir', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            trendAsync.when(
              data: (points) => AttendanceTrendChart(points: points),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )),
              error: (error, _) => _ErrorRetry(
                message: 'Gagal memuat trend',
                onRetry: () => ref.invalidate(dashboardTrendProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 8),
            Text(message),
            TextButton(
              onPressed: onRetry, 
              child: const Text('Coba Lagi')
            ),
          ],
        ),
      ),
    );
  }
}