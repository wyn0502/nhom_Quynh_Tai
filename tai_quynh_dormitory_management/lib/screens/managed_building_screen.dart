import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../services/discipline_service.dart';
import '../widgets/app_ui.dart';

class ManagedBuildingScreen extends StatefulWidget {
  const ManagedBuildingScreen({super.key});

  @override
  State<ManagedBuildingScreen> createState() =>
      _ManagedBuildingScreenState();
}

class _ManagedBuildingScreenState extends State<ManagedBuildingScreen> {
  final service = DisciplineService();

  late Future<List<Map<String, dynamic>>> _residents =
      service.managedResidents();

  String search = '';

  void _reload() {
    setState(() => _residents = service.managedResidents());
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tòa ${user.managedBuildingId ?? ""}'),
        actions: [
          IconButton(
            tooltip: 'Tải lại danh sách',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => AuthController.instance.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppUi.card(
            context,
            title: 'Quản lý tòa: ${user.displayName}',
            icon: Icons.security,
            children: [
              AppUi.info('Điện thoại', user.phone),
              AppUi.info('Nơi sinh sống', user.hometown),
              const Text(
                'Bạn chỉ được xem sinh viên và minh chứng của tòa '
                'được giao. Điểm danh: 22:00–22:10 mỗi ngày, giờ Việt Nam.',
              ),
            ],
          ),
          TextField(
            onChanged: (value) {
              setState(() => search = value.trim().toLowerCase());
            },
            decoration: const InputDecoration(
              labelText: 'Tìm phòng, họ tên hoặc MSSV',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _residents,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(AppUi.errorText(snapshot.error!)),
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final grouped = <String, List<Map<String, dynamic>>>{};

              for (final student in snapshot.data!) {
                final text =
                    '${student['room_name']} '
                    '${student['full_name']} '
                    '${student['mssv']}';

                if (!text.toLowerCase().contains(search)) continue;

                grouped
                    .putIfAbsent(student['room_name'] as String, () => [])
                    .add(student);
              }

              return Column(
                children: [
                  if (grouped.isEmpty)
                    const Text('Không có sinh viên phù hợp trong tòa này.'),
                  for (final entry in grouped.entries)
                    AppUi.card(
                      context,
                      title: entry.key,
                      badge: '${entry.value.length} sinh viên',
                      icon: Icons.meeting_room_outlined,
                      children: [
                        for (final student in entry.value)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(student['full_name'] as String),
                            subtitle: Text(
                              'MSSV: ${student['mssv']} '
                              '• ${student['username']}',
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}