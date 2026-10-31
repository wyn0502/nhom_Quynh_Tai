import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/attendance.dart';
import '../models/room.dart';
import '../models/ticket.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';
import '../widgets/room_occupancy.dart';
import 'room_editor.dart';

typedef Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

final portalDb = FirebaseFirestore.instance;
final portalAuth = AuthController.instance;

class PortalPage extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final List<Widget> children, actions;

  const PortalPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () => portalAuth.logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1150),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5141E8),
                        Color(0xFF7967EE),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: Colors.white, size: 32),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: actions,
                    ),
                  ),
                ...children,
              ],
            ),
          ),
        ),
      );
}

class PortalRooms extends StatefulWidget {
  const PortalRooms({super.key});

  @override
  State<PortalRooms> createState() => _PortalRoomsState();
}

class _PortalRoomsState extends State<PortalRooms> {
  final service = FirestoreService();

  late final rooms = service.getRoomsStream();

  late final profiles = service
      .collection('users')
      .where('role', isEqualTo: 'student')
      .snapshots();

  DateTime date = AttendanceClock.vietnamNow();
  String search = '';
  bool syncing = false;

  bool matches(Map<String, dynamic> data, Room room) =>
      data['room_status'] == 'approved' &&
      (data['pending_room_doc'] == room.id ||
          data['pending_room_name'] == room.label);

  Future<void> synchronize() async {
    if (syncing || !portalAuth.isAdmin) return;

    final yes = await AppUi.confirm(
      context,
      'Đồng bộ danh sách từ hồ sơ sinh viên đã duyệt? '
      'Hãy tạm dừng duyệt, chuyển và trả phòng trong lúc đồng bộ.',
    );

    if (!yes || !mounted) return;

    setState(() => syncing = true);

    await AppUi.run(
      context,
      () async {
        final allRooms = await rooms.first;

        final users = (await service
                .collection('users')
                .where('role', isEqualTo: 'student')
                .get())
            .docs;

        for (final room in allRooms) {
          final candidates =
              users.where((doc) => matches(doc.data(), room)).toList();

          await portalDb.runTransaction((tx) async {
            final current = (await tx.get(
              service.collection('rooms').doc(room.id),
            ))
                .data();

            if (current == null) {
              throw StateError('Phòng đã bị xóa. Hãy tải lại.');
            }

            final members = <Map<String, dynamic>>[];

            for (final user in candidates) {
              final fresh = (await tx.get(user.reference)).data();

              if (fresh == null || !matches(fresh, room)) {
                throw StateError(
                  'Dữ liệu cư trú vừa thay đổi. Hãy đồng bộ lại.',
                );
              }

              members.add({
                'username': user.id,
                'full_name': fresh['full_name'] ?? user.id,
                'mssv': fresh['mssv'] ?? '',
              });
            }

            if (members.length != current['current_occupancy']) {
              throw StateError(
                '${room.label}: sĩ số ${current['current_occupancy']} '
                'nhưng chỉ tìm thấy ${members.length} hồ sơ được duyệt. '
                'Hãy kiểm tra và xếp lại hồ sơ trước khi đồng bộ.',
              );
            }

            tx.set(
              service.collection('room_rosters').doc(room.id),
              {
                'room_id': room.id,
                'room_name': room.label,
                'building_id': room.buildingId,
                'members': members,
              },
            );
          });
        }
      },
      success: 'Đã đồng bộ danh sách cư trú.',
    );

    if (mounted) setState(() => syncing = false);
  }

  Stream<List<ViolationEntry>> weekly() {
    Query<Map<String, dynamic>> query =
        portalDb.collection('v2_violations');

    if (portalAuth.isBuildingManager) {
      query = query.where(
        'building_id',
        isEqualTo: portalAuth.currentUser.managedBuildingId,
      );
    }

    final week = AttendanceClock.monday(date);

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .where((doc) => doc.data()['week_start'] == week)
              .map((doc) => ViolationEntry(doc.id, doc.data()))
              .toList(),
        );
  }

  Widget members(
    Room room,
    List<Map<String, dynamic>> list,
    List<ViolationEntry> violations,
  ) {
    final total = violations
        .where((v) => list.any((m) => m['username'] == v.username))
        .length;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Thành viên (${list.length}) • $total lần vi phạm trong tuần',
      ),
      children: [
        if (list.length != room.currentOccupancy)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Sĩ số ${room.currentOccupancy}, '
              'danh sách có ${list.length} hồ sơ. '
              'Admin cần kiểm tra hồ sơ và đồng bộ danh sách cư trú.',
              style: const TextStyle(color: AppUi.orange),
            ),
          ),
        if (list.isEmpty && room.currentOccupancy == 0)
          const ListTile(
            title: Text('Phòng chưa có người ở.'),
          ),
        for (final person in list)
          Builder(
            builder: (context) {
              final entries = violations
                  .where((v) => v.username == person['username'])
                  .toList();

              final fine = entries.fold<int>(
                0,
                (sum, v) => sum + v.fine,
              );

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    '${person['full_name'] ?? '?'}'
                            .characters
                            .firstOrNull ??
                        '?',
                  ),
                ),
                title: Text(
                  '${person['full_name'] ?? person['username']}',
                ),
                subtitle: Text(
                  'MSSV: ${person['mssv'] ?? ''}\n'
                  '${entries.length} lần vi phạm • ${AppUi.money(fine)}',
                ),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('${person['full_name']}'),
                    scrollable: true,
                    content: SizedBox(
                      width: 480,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tuần từ ${AttendanceClock.monday(date)}',
                          ),
                          if (entries.isEmpty)
                            const Text(
                              'Không có vi phạm được ghi nhận '
                              'trong tuần này.',
                            ),
                          for (final v in entries)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(v.reason),
                              subtitle: Text(
                                '${v.day} • ${AppUi.money(v.fine)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget card(
    Room room,
    List<ViolationEntry> violations,
  ) =>
      AppUi.card(
        context,
        title: room.label,
        icon: Icons.apartment_rounded,
        badge: RoomOccupancy.label(room),
        color: RoomOccupancy.color(room),
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              Text('Tòa ${room.buildingId}'),
              Text(room.roomType),
              Text('${AppUi.money(room.fixedPrice)}/tháng'),
            ],
          ),
          const SizedBox(height: 16),
          RoomOccupancy(room: room),
          if (portalAuth.isAdmin)
            AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
              stream: profiles,
              builder: (snapshot) => members(
                room,
                snapshot.docs
                    .where((d) => matches(d.data(), room))
                    .map(
                      (d) => {
                        'username': d.id,
                        'full_name': d.data()['full_name'],
                        'mssv': d.data()['mssv'],
                      },
                    )
                    .toList(),
                violations,
              ),
            )
          else
            AppUi.data<List<Map<String, dynamic>>>(
              stream: service.getRoomResidentsStream(room.id!),
              builder: (list) => members(room, list, violations),
            ),
          if (portalAuth.isAdmin)
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => RoomEditor.show(
                    context,
                    room: room,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Sửa phòng'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    if (!await AppUi.confirm(
                          context,
                          'Xóa ${room.label}?',
                        ) ||
                        !mounted) {
                      return;
                    }

                    if (context.mounted) {
                      await AppUi.run(
                        context,
                        () => service.deleteRoom(room.id!),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Xóa phòng'),
                ),
              ],
            ),
        ],
      );

  @override
  Widget build(BuildContext context) => PortalPage(
        title: portalAuth.isAdmin
            ? 'Quản lý phòng'
            : 'Tòa ${portalAuth.currentUser.managedBuildingId}',
        subtitle: 'Danh sách phòng, thành viên '
            'và số lần vi phạm theo tuần.',
        icon: Icons.apartment_rounded,
        actions: [
          if (portalAuth.isAdmin)
            FilledButton.icon(
              onPressed: () => RoomEditor.show(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm phòng'),
            ),
          if (portalAuth.isAdmin)
            OutlinedButton.icon(
              onPressed: syncing ? null : synchronize,
              icon: const Icon(Icons.sync),
              label: Text(
                syncing ? 'Đang đồng bộ…' : 'Đồng bộ cư trú cũ',
              ),
            ),
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
        children: [
          TextField(
            onChanged: (value) => setState(
              () => search = value.toLowerCase(),
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm phòng hoặc tòa nhà',
            ),
          ),
          const SizedBox(height: 20),
          AppUi.data<List<Room>>(
            stream: rooms,
            builder: (list) => AppUi.data<List<ViolationEntry>>(
              stream: weekly(),
              builder: (violations) {
                final visible = list
                    .where(
                      (r) => '${r.label}'
                          .toLowerCase()
                          .contains(search),
                    )
                    .toList()
                  ..sort((a, b) => a.label.compareTo(b.label));

                return Column(
                  children: [
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text('Chưa có phòng phù hợp.'),
                      ),
                    for (final room in visible)
                      card(room, violations),
                  ],
                );
              },
            ),
          ),
        ],
      );
}

class PortalTickets extends StatefulWidget {
  const PortalTickets({super.key});

  @override
  State<PortalTickets> createState() => _PortalTicketsState();
}

class _PortalTicketsState extends State<PortalTickets> {
  final service = FirestoreService();

  late final rooms = service.getRoomsStream();

  String? selected;
  String status = 'all';

  Future<void> create() async {
    final user = portalAuth.currentUser;

    if (!user.hasActiveRoom) {
      AppUi.message(
        context,
        'Bạn cần được duyệt phòng trước.',
        error: true,
      );
      return;
    }

    await AppUi.form(
      context,
      title: 'Gửi yêu cầu sửa chữa',
      fields: const [
        InputSpec('title', 'Tiêu đề'),
        InputSpec('description', 'Mô tả chi tiết', lines: 4),
        InputSpec(
          'urgency',
          'Mức độ',
          value: 'medium',
          options: {
            'low': 'Thấp',
            'medium': 'Trung bình',
            'high': 'Khẩn cấp',
          },
        ),
      ],
      onSave: (values) => service.createTicket(
        Ticket(
          id: 'ticket_${DateTime.now().microsecondsSinceEpoch}',
          roomName: user.pendingRoomName!,
          studentName: user.displayName,
          title: values['title'],
          description: values['description'],
          urgency: values['urgency'],
          date: AppUi.today(),
        ),
      ),
    );
  }

  Widget reports(String? room) {
    Query<Map<String, dynamic>> query =
        service.collection('tickets');

    if (room != null) {
      query = query.where('room_name', isEqualTo: room);
    }

    return AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (snapshot) {
        final docs = snapshot.docs
            .where(
              (d) => status == 'all' || d.data()['status'] == status,
            )
            .toList();

        return Column(
          children: [
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Chưa có báo cáo phù hợp.'),
              ),
            for (final doc in docs)
              AppUi.card(
                context,
                title: '${doc.data()['title'] ?? 'Báo cáo'}',
                icon: Icons.handyman_outlined,
                badge: AppUi.status('${doc.data()['status']}'),
                color: AppUi.orange,
                children: [
                  Text(
                    '${doc.data()['room_name']} • '
                    '${doc.data()['student_name'] ?? ''}',
                  ),
                  const SizedBox(height: 12),
                  Text('${doc.data()['description'] ?? ''}'),
                  const SizedBox(height: 12),
                  Text(
                    'Mức độ: '
                    '${AppUi.status('${doc.data()['urgency']}')} '
                    '• ${doc.data()['date'] ?? ''}',
                  ),
                  if (portalAuth.isAdmin ||
                      portalAuth.isBuildingManager)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final value in [
                            'pending',
                            'processing',
                            'completed',
                          ])
                            OutlinedButton(
                              onPressed:
                                  doc.data()['status'] == value
                                      ? null
                                      : () => AppUi.run(
                                            context,
                                            () => doc.reference.update(
                                              {'status': value},
                                            ),
                                          ),
                              child: Text(AppUi.status(value)),
                            ),
                          if (portalAuth.isAdmin)
                            TextButton(
                              onPressed: () async {
                                if (!await AppUi.confirm(
                                      context,
                                      'Xóa báo cáo này?',
                                    ) ||
                                    !mounted) {
                                  return;
                                }

                                if (context.mounted) {
                                  await AppUi.run(
                                    context,
                                    () => doc.reference.delete(),
                                  );
                                }
                              },
                              child: const Text('Xóa'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => PortalPage(
        title: 'Sự cố & kỹ thuật',
        subtitle: 'Theo dõi yêu cầu sửa chữa và tiến độ xử lý.',
        icon: Icons.handyman_rounded,
        actions: [
          if (portalAuth.isStudent)
            FilledButton.icon(
              onPressed: create,
              icon: const Icon(Icons.add),
              label: const Text('Báo sự cố'),
            ),
        ],
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final value in [
                'all',
                'pending',
                'processing',
                'completed',
              ])
                ChoiceChip(
                  label: Text(
                    value == 'all' ? 'Tất cả' : AppUi.status(value),
                  ),
                  selected: status == value,
                  onSelected: (_) => setState(
                    () => status = value,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (portalAuth.isAdmin)
            reports(null)
          else if (portalAuth.isStudent)
            if (portalAuth.currentUser.hasActiveRoom)
              reports(portalAuth.currentUser.pendingRoomName)
            else
              const Text(
                'Bạn cần được duyệt phòng để gửi và xem báo cáo.',
              )
          else
            AppUi.data<List<Room>>(
              stream: rooms,
              builder: (list) {
                if (list.isEmpty) {
                  return const Text('Tòa chưa có phòng.');
                }

                final current =
                    list.any((r) => r.label == selected)
                        ? selected!
                        : list.first.label;

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(current),
                      initialValue: current,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Xem sự cố của phòng',
                      ),
                      items: list
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.label,
                              child: Text(r.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(
                        () => selected = value,
                      ),
                    ),
                    const SizedBox(height: 18),
                    reports(current),
                  ],
                );
              },
            ),
        ],
      );
}

class PortalNotices extends StatefulWidget {
  const PortalNotices({super.key});

  @override
  State<PortalNotices> createState() => _PortalNoticesState();
}

class _PortalNoticesState extends State<PortalNotices> {
  final collection = portalDb.collection('v2_building_notices');

  String get building {
    if (portalAuth.isBuildingManager) {
      return portalAuth.currentUser.managedBuildingId ?? '';
    }

    if (!portalAuth.currentUser.hasActiveRoom) return '';

    return (portalAuth.currentUser.pendingRoomName ?? '')
        .split(' - ')
        .last;
  }

  Future<void> edit([Doc? doc]) async {
    final old = doc?.data() ?? <String, dynamic>{};

    await AppUi.form(
      context,
      title: doc == null ? 'Đăng thông báo' : 'Sửa thông báo',
      fields: [
        InputSpec('title', 'Tiêu đề', value: old['title']),
        InputSpec(
          'content',
          'Nội dung',
          value: old['content'],
          lines: 5,
        ),
        if (portalAuth.isAdmin)
          InputSpec(
            'building_id',
            'Tòa nhận (để trống = toàn KTX)',
            value: old['building_id'],
            required: false,
          ),
      ],
      onSave: (values) =>
          (doc?.reference ?? collection.doc()).set({
        'title': values['title'],
        'content': values['content'],
        'building_id':
            portalAuth.isAdmin ? values['building_id'] : building,
        'author_uid': old['author_uid'] ??
            fb.FirebaseAuth.instance.currentUser!.uid,
        'author_name':
            old['author_name'] ?? portalAuth.currentUser.displayName,
        'created_at':
            old['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = collection;

    if (!portalAuth.isAdmin) {
      query = query.where(
        'building_id',
        whereIn: {'', building}.toList(),
      );
    }

    return PortalPage(
      title: 'Bảng thông báo',
      subtitle: 'Thông tin chung và thông báo của tòa nhà.',
      icon: Icons.campaign_rounded,
      actions: [
        if (portalAuth.isAdmin || portalAuth.isBuildingManager)
          FilledButton.icon(
            onPressed: edit,
            icon: const Icon(Icons.edit_notifications),
            label: const Text('Đăng thông báo'),
          ),
      ],
      children: [
        AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (snapshot) {
            final docs = snapshot.docs.toList()
              ..sort((a, b) {
                final left = a.data()['created_at'] as Timestamp?;
                final right = b.data()['created_at'] as Timestamp?;

                return (right?.millisecondsSinceEpoch ?? 0)
                    .compareTo(left?.millisecondsSinceEpoch ?? 0);
              });

            return Column(
              children: [
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Chưa có thông báo.'),
                  ),
                for (final doc in docs)
                  AppUi.card(
                    context,
                    title: '${doc.data()['title']}',
                    icon: Icons.campaign_outlined,
                    badge: doc.data()['building_id'] == ''
                        ? 'Toàn KTX'
                        : 'Tòa ${doc.data()['building_id']}',
                    children: [
                      Text('${doc.data()['content']}'),
                      const SizedBox(height: 14),
                      Text(
                        'Đăng bởi ${doc.data()['author_name']}',
                      ),
                      if (portalAuth.isAdmin ||
                          (portalAuth.isBuildingManager &&
                              doc.data()['author_uid'] ==
                                  fb.FirebaseAuth
                                      .instance.currentUser?.uid &&
                              doc.data()['building_id'] == building))
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () => edit(doc),
                              child: const Text('Sửa'),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (!await AppUi.confirm(
                                      context,
                                      'Xóa thông báo này?',
                                    ) ||
                                    !mounted) {
                                  return;
                                }

                                if (context.mounted) {
                                  await AppUi.run(
                                    context,
                                    () => doc.reference.delete(),
                                  );
                                }
                              },
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}