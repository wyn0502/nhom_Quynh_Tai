import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

class StaffActivityScreen extends StatefulWidget {
  final bool tickets;

  const StaffActivityScreen({
    super.key,
    this.tickets = false,
  });

  @override
  State<StaffActivityScreen> createState() =>
      _StaffActivityScreenState();
}

class _StaffActivityScreenState extends State<StaffActivityScreen> {
  final service = FirestoreService();

  late final rooms = service.getRoomsStream();

  String? selected;

  String get building =>
      AuthController.instance.currentUser.managedBuildingId ?? '';

  Future<void> edit([
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  ]) async {
    final old = doc?.data() ?? <String, dynamic>{};

    final saved = await AppUi.form(
      context,
      title: doc == null ? 'Thêm thông báo' : 'Sửa thông báo',
      fields: [
        InputSpec('title', 'Tiêu đề', value: old['title']),
        InputSpec(
          'content',
          'Nội dung',
          value: old['content'],
          lines: 5,
        ),
      ],
      onSave: (values) =>
          (doc?.reference ?? service.collection('announcements').doc())
              .set({
        'title': values['title'],
        'content': values['content'],
        'building_id': building,
        'author_uid': fb.FirebaseAuth.instance.currentUser!.uid,
        'department': 'Quản lý tòa $building',
        'date': old['date'] ?? AppUi.today(),
      }),
    );

    if (saved && mounted) {
      AppUi.message(
        context,
        'Đã lưu thông báo. '
        'Sinh viên tòa này xem được tại Home.',
      );
    }
  }

  Widget tickets(String label) =>
      AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
        stream: service
            .collection('tickets')
            .where('room_name', isEqualTo: label)
            .snapshots(),
        builder: (snapshot) => Column(
          children: [
            if (snapshot.docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Text('Phòng chưa có báo cáo sự cố.'),
              ),
            for (final doc in snapshot.docs)
              AppUi.card(
                context,
                title: '${doc.data()['title']}',
                icon: Icons.handyman_outlined,
                badge: AppUi.status('${doc.data()['status']}'),
                children: [
                  Text(
                    '${doc.data()['student_name'] ?? ''} '
                    '• ${doc.data()['room_name']}',
                  ),
                  const SizedBox(height: 12),
                  Text('${doc.data()['description'] ?? ''}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in [
                        'pending',
                        'processing',
                        'completed',
                      ])
                        OutlinedButton(
                          onPressed:
                              doc.data()['status'] == status
                                  ? null
                                  : () => AppUi.run(
                                        context,
                                        () => doc.reference.update(
                                          {'status': status},
                                        ),
                                      ),
                          child: Text(AppUi.status(status)),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );

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
        title: Text(
          widget.tickets
              ? 'Sự cố tòa $building'
              : 'Thông báo tòa $building',
        ),
        actions: [
          if (!widget.tickets)
            IconButton(
              tooltip: 'Thêm thông báo',
              onPressed: edit,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.tickets)
            AppUi.data<List<Room>>(
              stream: rooms,
              builder: (list) {
                if (list.isEmpty) {
                  return const Text('Tòa chưa có phòng.');
                }

                final current =
                    list.any((room) => room.label == selected)
                        ? selected!
                        : list.first.label;

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(current),
                      initialValue: current,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Chọn phòng',
                      ),
                      items: list
                          .map(
                            (room) => DropdownMenuItem(
                              value: room.label,
                              child: Text(room.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selected = value),
                    ),
                    const SizedBox(height: 16),
                    tickets(current),
                  ],
                );
              },
            )
          else
            AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  service.collection('announcements').snapshots(),
              builder: (snapshot) {
                final docs = snapshot.docs
                    .where(
                      (doc) =>
                          (doc.data()['building_id'] ?? '') == '' ||
                          doc.data()['building_id'] == building,
                    )
                    .toList();

                return Column(
                  children: [
                    FilledButton.icon(
                      onPressed: edit,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thông báo'),
                    ),
                    const SizedBox(height: 16),
                    if (docs.isEmpty)
                      const Text('Chưa có thông báo.'),
                    for (final doc in docs)
                      AppUi.card(
                        context,
                        title: '${doc.data()['title']}',
                        icon: Icons.campaign_outlined,
                        badge:
                            (doc.data()['building_id'] ?? '') == ''
                                ? 'Toàn KTX'
                                : 'Tòa $building',
                        children: [
                          Text('${doc.data()['content'] ?? ''}'),
                          const SizedBox(height: 12),
                          Text(
                            '${doc.data()['department'] ?? ''} '
                            '• ${doc.data()['date'] ?? ''}',
                          ),
                          if (doc.data()['author_uid'] ==
                                  fb.FirebaseAuth
                                      .instance.currentUser!.uid &&
                              doc.data()['building_id'] == building)
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
                                        () =>
                                            doc.reference.delete(),
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
      ),
    );
  }
}