import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../services/equipment_service.dart';
import '../services/firestore_service.dart';
import '../utils/dorm_dates.dart';
import '../widgets/app_ui.dart';

typedef EquipmentDoc = QueryDocumentSnapshot<Map<String, dynamic>>;

class EquipmentScreen extends StatefulWidget {
  final Room? room;

  const EquipmentScreen({super.key, this.room});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final service = EquipmentService();
  late final inventory = service.stock.snapshots();

  String search = '';

  bool get admin => AuthController.instance.isAdmin;

  static const labels = {
    'restock': 'Nhập thêm',
    'issue': 'Bàn giao',
    'return': 'Thu hồi đồ tốt',
    'damage': 'Ghi nhận hỏng',
    'repair': 'Xác nhận đã sửa',
    'dispose': 'Thanh lý đồ hỏng',
  };

  int integer(Object? value) {
    final number = value is num ? value : num.tryParse('$value');

    if (number == null ||
        !number.isFinite ||
        number != number.round() ||
        number < 0 ||
        number > 1000000) {
      throw StateError(
        'Số lượng phải là số nguyên từ 0 đến 1.000.000.',
      );
    }

    return number.toInt();
  }

  Future<void> add() async {
    final saved = await AppUi.form(
      context,
      title: 'Thêm thiết bị vào kho',
      fields: const [
        InputSpec('name', 'Tên thiết bị'),
        InputSpec('unit', 'Đơn vị', value: 'cái'),
        InputSpec(
          'quantity',
          'Số lượng ban đầu',
          value: 0,
          number: true,
          min: 0,
          max: 1000000,
        ),
      ],
      onSave: (values) => service.create(
        '${values['name']}',
        '${values['unit']}',
        integer(values['quantity']),
      ),
    );

    if (saved && mounted) {
      AppUi.message(context, 'Đã thêm thiết bị.');
    }
  }

  Future<void> move(
    String inventoryId,
    String name,
    String kind,
  ) async {
    final request = service.requestId();

    try {
      final rooms = kind == 'restock' || widget.room != null
          ? <Room>[]
          : await FirestoreService().getRoomsStream().first;

      if (!mounted) return;

      if (kind != 'restock' && widget.room == null && rooms.isEmpty) {
        throw StateError('Hãy tạo phòng trước khi bàn giao.');
      }

      final saved = await AppUi.form(
        context,
        title: '${labels[kind]}: $name',
        fields: [
          if (kind != 'restock' && widget.room == null)
            InputSpec(
              'room',
              'Phòng nhận',
              value: rooms.first.id,
              options: {
                for (final room in rooms) room.id!: room.label,
              },
            ),
          const InputSpec(
            'quantity',
            'Số lượng (số nguyên)',
            value: 1,
            number: true,
            min: 1,
            max: 1000000,
          ),
        ],
        onSave: (values) async {
          final quantity = integer(values['quantity']);
          final room = kind == 'restock'
              ? null
              : widget.room ??
                  rooms.firstWhere((r) => r.id == values['room']);

          await service.change(
            requestId: request,
            kind: kind,
            inventoryId: inventoryId,
            quantity: quantity,
            room: room,
          );
        },
      );

      if (saved && mounted) {
        AppUi.message(
          context,
          '${labels[kind]} thành công. Tồn kho đã được cập nhật.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppUi.message(
          context,
          AppUi.errorText(error),
          error: true,
        );
      }
    }
  }

  Widget allocations() =>
      AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.assets
            .where('room_name', isEqualTo: widget.room!.label)
            .snapshots(),
        builder: (snapshot) => Column(
          children: [
            if (snapshot.docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Phòng chưa được bàn giao thiết bị.'),
              ),
            for (final doc in snapshot.docs)
              AppUi.card(
                context,
                title: '${doc.data()['name'] ?? 'Thiết bị'}',
                icon: Icons.chair_outlined,
                badge:
                    '${doc.data()['quantity']} ${doc.data()['unit'] ?? 'cái'}',
                children: [
                  if (doc.data()['inventory_id'] == null)
                    const Text(
                      'Bản ghi cũ chưa liên kết với kho thiết bị mới.',
                    )
                  else ...[
                    Text(
                      'Đang tốt: '
                      '${(doc.data()['quantity'] as num) - (doc.data()['damaged_count'] as num)}'
                      ' • Hỏng: ${doc.data()['damaged_count']}',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kind in [
                          'return',
                          'damage',
                          'repair',
                          if (admin) 'dispose',
                        ])
                          OutlinedButton(
                            onPressed: () => move(
                              '${doc.data()['inventory_id']}',
                              '${doc.data()['name']}',
                              kind,
                            ),
                            child: Text(labels[kind]!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      );

  Future<void> history() async {
    Query<Map<String, dynamic>> query = service.moves;

    if (!admin) {
      query = query.where(
        'building_id',
        isEqualTo:
            AuthController.instance.currentUser.managedBuildingId,
      );
    }

    if (widget.room != null) {
      query = query.where('room_id', isEqualTo: widget.room!.id);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (snapshot) {
                final rows = snapshot.docs.toList()
                  ..sort((a, b) {
                    final x = a.data()['created_at'] as Timestamp?;
                    final y = b.data()['created_at'] as Timestamp?;
                    return (y?.millisecondsSinceEpoch ?? 0)
                        .compareTo(x?.millisecondsSinceEpoch ?? 0);
                  });

                return ListView(
                  children: [
                    Text(
                      'Lịch sử thiết bị',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (rows.isEmpty)
                      const Text('Chưa có giao dịch.'),
                    for (final row in rows.take(100))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${labels[row.data()['kind']]}'
                          ' • ${row.data()['item_name']}'
                          ' × ${row.data()['quantity']}',
                        ),
                        subtitle: Text(
                          '${row.data()['room_name'] ?? ''}\n'
                          '${row.data()['actor_name']}'
                          ' • ${DormDates.instant(row.data()['created_at'])} (VN)',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;

    if (!(auth.isAdmin || auth.isBuildingManager)) {
      return const Scaffold(
        body: Center(child: Text('Không có quyền truy cập kho.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room == null
              ? 'Kho thiết bị'
              : 'Thiết bị ${widget.room!.label}',
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử thiết bị',
            onPressed: history,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppUi.card(
            context,
            title: widget.room == null
                ? 'Kho thiết bị KTX'
                : 'Bàn giao & theo dõi hỏng hóc',
            icon: Icons.inventory_2_outlined,
            children: [
              Text(
                widget.room == null
                    ? 'Quản lý số lượng trong kho và thiết bị đang ở các phòng.'
                    : '${widget.room!.label} • Tòa ${widget.room!.buildingId}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (admin)
                    FilledButton.icon(
                      onPressed: add,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thiết bị'),
                    ),
                  OutlinedButton.icon(
                    onPressed: history,
                    icon: const Icon(Icons.history),
                    label: const Text('Lịch sử'),
                  ),
                ],
              ),
            ],
          ),
          if (widget.room != null) ...[
            Text(
              'Thiết bị trong phòng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            allocations(),
            const SizedBox(height: 12),
          ],
          TextField(
            onChanged: (value) =>
                setState(() => search = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm thiết bị trong kho',
            ),
          ),
          const SizedBox(height: 16),
          AppUi.data<QuerySnapshot<Map<String, dynamic>>>(
            stream: inventory,
            builder: (snapshot) {
              final docs = snapshot.docs
                  .where(
                    (d) => '${d.data()['name']}'
                        .toLowerCase()
                        .contains(search),
                  )
                  .toList()
                ..sort(
                  (a, b) => '${a.data()['name']}'
                      .compareTo('${b.data()['name']}'),
                );

              return Column(
                children: [
                  if (docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Chưa có thiết bị phù hợp.'),
                    ),
                  for (final doc in docs)
                    EquipmentStockCard(
                      data: doc.data(),
                      onIssue: () => move(
                        doc.id,
                        '${doc.data()['name']}',
                        'issue',
                      ),
                      onRestock: admin
                          ? () => move(
                                doc.id,
                                '${doc.data()['name']}',
                                'restock',
                              )
                          : null,
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

class EquipmentStockCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onIssue;
  final VoidCallback? onRestock;

  const EquipmentStockCard({
    super.key,
    required this.data,
    required this.onIssue,
    this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    final available = (data['available'] as num).toInt();

    final color = available == 0
        ? AppUi.red
        : available <= 2
            ? AppUi.orange
            : AppUi.green;

    return AppUi.card(
      context,
      title: '${data['name']}',
      icon: Icons.inventory_outlined,
      badge: available == 0
          ? 'Hết kho'
          : available <= 2
              ? 'Sắp hết'
              : 'Còn hàng',
      color: color,
      children: [
        Text(
          'Còn $available ${data['unit']}'
          ' • Đã bàn giao ${data['assigned']}'
          ' • Tổng ${data['total']}',
        ),
        if (available == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Đã hết thiết bị trong kho.',
              style: TextStyle(color: AppUi.red),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: available == 0 ? null : onIssue,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Bàn giao cho phòng'),
            ),
            if (onRestock != null)
              OutlinedButton.icon(
                onPressed: onRestock,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Nhập thêm'),
              ),
          ],
        ),
      ],
    );
  }
}