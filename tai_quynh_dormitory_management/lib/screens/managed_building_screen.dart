import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../models/attendance.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';
import '../widgets/room_occupancy.dart';

class ManagedBuildingScreen extends StatefulWidget {
  const ManagedBuildingScreen({super.key});

  @override
  State<ManagedBuildingScreen> createState() =>
      _ManagedBuildingScreenState();
}

class _ManagedBuildingScreenState
    extends State<ManagedBuildingScreen> {
  final service = FirestoreService();

  late final rooms = service.getRoomsStream();

  String search = '';
  DateTime date = AttendanceClock.vietnamNow();

  Stream<List<ViolationEntry>> weekly() {
    final week = AttendanceClock.monday(date);

    return service
        .collection('violations')
        .where(
          'building_id',
          isEqualTo:
              AuthController.instance.currentUser.managedBuildingId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['week_start'] == week)
              .map((doc) => ViolationEntry(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;

    if (!auth.isBuildingManager) {
      return const Scaffold(
        body: Center(child: Text('Không có quyền quản lý tòa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tòa ${auth.currentUser.managedBuildingId}'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppUi.card(
            context,
            title: auth.currentUser.displayName,
            icon: Icons.shield_outlined,
            badge:
                'Quản lý tòa ${auth.currentUser.managedBuildingId}',
            children: [
              const Text(
                'Xem phòng, thành viên và thống kê vi phạm '
                'của tòa được giao.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );

                  if (selected != null && mounted) {
                    setState(() => date = selected);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: Text(
                  'Tuần ${AttendanceClock.monday(date)}',
                ),
              ),
            ],
          ),
          TextField(
            onChanged: (value) =>
                setState(() => search = value.toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm phòng trong tòa',
            ),
          ),
          const SizedBox(height: 16),
          AppUi.data<List<Room>>(
            stream: rooms,
            builder: (all) {
              final visible = all
                  .where(
                    (room) =>
                        room.label.toLowerCase().contains(search),
                  )
                  .toList()
                ..sort((a, b) => a.label.compareTo(b.label));

              return Column(
                children: [
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tòa chưa có phòng phù hợp.'),
                    ),
                  for (final room in visible)
                    AppUi.card(
                      context,
                      title: room.label,
                      icon: Icons.meeting_room_outlined,
                      badge: RoomOccupancy.label(room),
                      color: RoomOccupancy.color(room),
                      children: [
                        RoomOccupancy(room: room),
                        AppUi.data<List<Map<String, dynamic>>>(
                          stream: service.getRoomResidentsStream(
                            room.id!,
                          ),
                          builder: (members) => ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(
                              'Thành viên (${members.length})',
                            ),
                            children: [
                              if (members.isEmpty)
                                const ListTile(
                                  title: Text(
                                    'Chưa có hồ sơ cư trú '
                                    'được duyệt trong danh sách.',
                                  ),
                                ),
                              for (final member in members)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(
                                      Icons.person_outline,
                                    ),
                                  ),
                                  title: Text(
                                    '${member['full_name'] ?? member['username']}',
                                  ),
                                  subtitle: Text(
                                    'MSSV: ${member['mssv'] ?? ''}',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                  ),
                                  onTap: () =>
                                      showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (_) => SafeArea(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(20),
                                        child: SizedBox(
                                          height:
                                              MediaQuery.sizeOf(
                                                    context,
                                                  ).height *
                                                  .6,
                                          child: AppUi.data<
                                              List<ViolationEntry>>(
                                            stream: weekly(),
                                            builder: (rows) {
                                              final entries = rows
                                                  .where(
                                                    (v) =>
                                                        v.username ==
                                                        member[
                                                            'username'],
                                                  )
                                                  .toList();

                                              final total =
                                                  entries.fold<int>(
                                                0,
                                                (sum, v) =>
                                                    sum + v.fine,
                                              );

                                              return ListView(
                                                children: [
                                                  Text(
                                                    '${member['full_name']}',
                                                    style: Theme.of(
                                                      context,
                                                    )
                                                        .textTheme
                                                        .titleLarge,
                                                  ),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                  Text(
                                                    'Tuần từ ${AttendanceClock.monday(date)}',
                                                  ),
                                                  const SizedBox(
                                                    height: 8,
                                                  ),
                                                  Text(
                                                    '${entries.length} lần • ${AppUi.money(total)}',
                                                  ),
                                                  if (entries
                                                      .isEmpty)
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets
                                                              .symmetric(
                                                        vertical: 20,
                                                      ),
                                                      child: Text(
                                                        'Không có vi phạm được ghi nhận trong tuần đã chọn.',
                                                      ),
                                                    ),
                                                  for (final entry
                                                      in entries)
                                                    ListTile(
                                                      title: Text(
                                                        entry.reason,
                                                      ),
                                                      subtitle: Text(
                                                        '${entry.day} • ${AppUi.money(entry.fine)}',
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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