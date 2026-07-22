import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/device_entity.dart';
import '../providers/devices_provider.dart';

class DevicesListScreen extends ConsumerWidget {
  const DevicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perangkat')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(devicesListProvider);
          await ref.read(devicesListProvider.future);
        }, 
        child: devicesAsync.when(
          data: (devices) {
            if (devices.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Belum ada device terdaftar')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _DeviceCard(device: devices[index]),
            );
          }, 
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                const Text('Gagal memuat data perangkat'),
                TextButton(
                  onPressed: () => ref.invalidate(devicesListProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ), loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({
    required this.device
  });

  final DeviceEntity device;

  @override
   Widget build(BuildContext context, WidgetRef ref) {
    final toggleState = ref.watch(deviceToggleControllerProvider);
    final isOnline = device.status == DeviceStatus.online;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: isOnline ? Colors.green : Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(device.deviceCode, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (device.location != null) ...[
              const SizedBox(height: 4),
              Text(device.location!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 4),
            Text(
              'Terakhir terlihat: ${device.lastSeenAt != null ? DateFormat('dd MMM HH:mm').format(device.lastSeenAt!) : 'Belum pernah'}'
              '${device.firmwareVersion != null ? ' • FW ${device.firmwareVersion}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(child: Text('Mode Registrasi')),
                if (toggleState.isLoading)
                  const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Switch(
                    value: device.registrationMode,
                    onChanged: !isOnline
                        ? null // tidak bisa aktifkan mode registrasi kalau device offline
                        : (value) async {
                            final success = await ref
                                .read(deviceToggleControllerProvider.notifier)
                                .toggle(device.id, value);
                            if (!context.mounted) return;
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal mengubah mode registrasi')),
                              );
                            }
                          },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}