import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';
import 'record_editor.dart';
import 'equipment_screen.dart';

class ManagementScreen extends StatefulWidget {
  final String initialKind;

  const ManagementScreen({
    super.key,
    this.initialKind = 'announcements',
  });

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  final service = FirestoreService();

  late String kind;

  @override
  void initState() {
    super.initState();

    kind = RecordEditor.names.containsKey(widget.initialKind)
        ? widget.initialKind
        : 'announcements';
  }

  Future<void> _delete(
    String entity,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await AppUi.confirm(
      context,
      entity == 'users'
          ? 'Xóa hồ sơ sinh viên và giải phóng phòng đang ở?'
          : 'Xóa bản ghi này? Dữ liệu đã xóa không thể khôi phục.',
    );

    if (!confirmed || !mounted) return;

    await AppUi.run(
      context,
      () async {
        if (entity == 'users') {
          await service.deleteUser((document['id'] as num).toInt());
        } else {
          await document.reference.delete();
        }
      },
      success: 'Đã xóa dữ liệu.',
    );
  }

  String _display(String field, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Chưa cập nhật';
    }

    if (field == 'status' || field == 'urgency') {
      return AppUi.status(value.toString());
    }

    if ([
      'room_fee',
      'electricity_fee',
      'water_fee',
      'total_amount',
    ].contains(field)) {
      return AppUi.money(value as num);
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthController.instance.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Không có quyền truy cập.')),
      );
    }

    final entity = kind;

    if (entity == 'assets') {
      return const EquipmentScreen();
    }

    Query<Map<String, dynamic>> query = service.collection(entity);

    if (entity == 'users') {
      query = query.where('role', isEqualTo: 'student');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý dữ liệu',
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: entity == 'users'
          ? null
          : FloatingActionButton(
              onPressed: () {
                RecordEditor.edit(context, entity);
              },
              child: const Icon(Icons.add),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          DropdownButtonFormField<String>(
            initialValue: entity,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Chức năng',
              border: OutlineInputBorder(),
            ),
            items: RecordEditor.names.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => kind = value);
              }
            },
          ),
          const SizedBox(height: 16),
          if (entity == 'users')
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Tạo tài khoản qua Đăng ký. '
                'Duyệt, từ chối và trả phòng tại tab Sinh viên.',
              ),
            ),
          AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (snapshot) {
              if (snapshot.docs.isEmpty) {
                return const Text('Chưa có dữ liệu.');
              }

              return Column(
                children: snapshot.docs.map((document) {
                  final data = document.data();

                  final title = data['title'] ??
                      data['name'] ??
                      data['full_name'] ??
                      data['room_name'] ??
                      RecordEditor.names[entity]!;

                  return AppUi.card(
                    context,
                    title: title.toString(),
                    icon: Icons.edit_note_rounded,
                    children: [
                      ...RecordEditor.labels[entity]!.entries.map(
                        (entry) => AppUi.info(
                          entry.value,
                          _display(entry.key, data[entry.key]),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              RecordEditor.edit(
                                context,
                                entity,
                                id: document.id,
                                data: data,
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Sửa'),
                          ),
                          TextButton.icon(
                            onPressed: () => _delete(entity, document),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppUi.red,
                            ),
                            label: const Text(
                              'Xóa',
                              style: TextStyle(color: AppUi.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}