import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final service = FirestoreService();

  String search = '';
  String building = 'all';
  bool requesting = false;

  Future<void> _editRoom([Room? room]) async {
    final saved = await AppUi.form(
      context,
      title: room == null ? 'Thêm phòng KTX' : 'Sửa phòng KTX',
      fields: [
        InputSpec(
          'name',
          'Tên phòng',
          value: room?.name,
        ),
        InputSpec(
          'building',
          'Tòa nhà',
          value: room?.buildingId,
        ),
        InputSpec(
          'capacity',
          'Sức chứa',
          value: room?.capacity ?? 1,
          integer: true,
          min: 1,
        ),
        InputSpec(
          'type',
          'Loại phòng',
          value: room?.roomType ?? 'Thường',
        ),
        InputSpec(
          'price',
          'Giá phòng',
          value: room?.fixedPrice ?? 0,
          number: true,
          min: 0,
        ),
      ],
      onSave: (values) async {
        final updated = Room(
          id: room?.id,
          name: values['name'],
          buildingId: values['building'],
          capacity: values['capacity'],
          currentOccupancy: room?.currentOccupancy ?? 0,
          roomType: values['type'],
          fixedPrice: (values['price'] as num).toDouble(),
        );

        final rooms = await service.getRoomsStream().first;

        final duplicate = rooms.any(
          (item) =>
              item.id != room?.id &&
              item.name.toLowerCase() ==
                  updated.name.toLowerCase() &&
              item.buildingId.toLowerCase() ==
                  updated.buildingId.toLowerCase(),
        );

        if (duplicate) {
          throw StateError('Tên phòng trong tòa này đã tồn tại.');
        }

        if (room == null) {
          await service.addRoom(updated);
        } else {
          await service.updateRoom(room.id!, updated);
        }
      },
    );

    if (saved && mounted) {
      AppUi.message(context, 'Đã lưu thông tin phòng.');
    }
  }

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await AppUi.confirm(
      context,
      'Xóa ${FirestoreService.roomLabel(room)}?',
    );

    if (!confirmed || !mounted) return;

    await AppUi.run(
      context,
      () => service.deleteRoom(room.id!),
      success: 'Đã xóa phòng.',
    );
  }

  Future<void> _register(Room room) async {
    if (requesting) return;

    final user = AuthController.instance.currentUser;

    if (!user.canRegisterRoom) {
      AppUi.message(
        context,
        'Bạn đã có yêu cầu hoặc đã được duyệt phòng.',
        error: true,
      );
      return;
    }

    setState(() => requesting = true);

    try {
      final confirmed = await AppUi.confirm(
        context,
        'Đăng ký ${FirestoreService.roomLabel(room)}?\n\n'
        'Sau khi gửi, bạn phải chờ admin xử lý '
        'và không thể đăng ký phòng khác.',
      );

      if (!confirmed || !mounted) return;

      await AppUi.run(
        context,
        () => service.requestRoomRegistration(
          user.id!,
          FirestoreService.roomLabel(room),
        ),
        success: 'Đã gửi yêu cầu. Vui lòng chờ admin duyệt.',
      );
    } finally {
      if (mounted) {
        setState(() => requesting = false);
      }
    }
  }

  Widget _roomCard(
    Room room,
    User user,
    bool admin,
  ) {
    final locked = !user.canRegisterRoom;

    return AppUi.card(
      context,
      title: FirestoreService.roomLabel(room),
      icon: Icons.meeting_room_outlined,
      badge: '${room.currentOccupancy}/${room.capacity} người',
      children: [
        AppUi.info('Loại phòng', room.roomType),
        AppUi.info('Giá phòng', AppUi.money(room.fixedPrice)),
        AppUi.info('Chỗ còn trống', room.availableBeds),
        LinearProgressIndicator(
          value: room.capacity <= 0
              ? 0
              : (room.currentOccupancy / room.capacity)
                  .clamp(0.0, 1.0)
                  .toDouble(),
          color: room.hasAvailableBeds()
              ? AppUi.green
              : AppUi.orange,
          minHeight: 6,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (admin) ...[
              OutlinedButton.icon(
                onPressed: () => _editRoom(room),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa'),
              ),
              TextButton.icon(
                onPressed: () => _deleteRoom(room),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppUi.red,
                ),
                label: const Text(
                  'Xóa',
                  style: TextStyle(color: AppUi.red),
                ),
              ),
            ] else if (locked)
              AppUi.badge(
                user.roomStatus == RoomStatus.pending
                    ? 'Đang chờ duyệt'
                    : 'Phòng của bạn',
                color: user.roomStatus == RoomStatus.pending
                    ? AppUi.orange
                    : AppUi.green,
              )
            else
              FilledButton.icon(
                onPressed: requesting || !room.hasAvailableBeds()
                    ? null
                    : () => _register(room),
                icon: const Icon(Icons.app_registration),
                label: Text(
                  room.hasAvailableBeds()
                      ? 'Đăng ký phòng này'
                      : 'Phòng đã đầy',
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final auth = AuthController.instance;
        final user = auth.currentUser;
        final locked = !auth.isAdmin && !user.canRegisterRoom;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Quản lý Phòng KTX',
              style: TextStyle(fontSize: 18),
            ),
            actions: [
              if (auth.isAdmin)
                IconButton(
                  tooltip: 'Thêm phòng',
                  onPressed: () => _editRoom(),
                  icon: const Icon(Icons.add_circle_outline),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!auth.isAdmin)
                AppUi.card(
                  context,
                  title: user.getRoomStatus(),
                  icon: Icons.home_work_outlined,
                  color: user.roomStatus == RoomStatus.pending
                      ? AppUi.orange
                      : AppUi.navy,
                  children: [
                    if (user.pendingRoomName != null)
                      Text(user.pendingRoomName!),
                    if (user.roomStatus == RoomStatus.pending)
                      const Text(
                        'Yêu cầu đã gửi tới admin. '
                        'Các phòng khác được ẩn cho đến khi '
                        'yêu cầu được xử lý.',
                      ),
                    if (user.canRegisterRoom)
                      const Text(
                        'Hãy chọn một phòng còn chỗ để đăng ký.',
                      ),
                  ],
                ),
              AppUi.data<List<Room>>(
                stream: service.getRoomsStream(),
                builder: (rooms) {
                  final buildings = rooms
                      .map((room) => room.buildingId)
                      .toSet()
                      .toList()
                    ..sort();

                  final visible = rooms.where((room) {
                    if (locked) {
                      return FirestoreService.roomLabel(room) ==
                          user.pendingRoomName;
                    }

                    final keyword = search.trim().toLowerCase();

                    return (building == 'all' ||
                            room.buildingId == building) &&
                        (keyword.isEmpty ||
                            room.name.toLowerCase().contains(keyword) ||
                            room.buildingId
                                .toLowerCase()
                                .contains(keyword));
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!locked) ...[
                        TextField(
                          onChanged: (value) {
                            setState(() => search = value);
                          },
                          decoration: const InputDecoration(
                            hintText: 'Tìm phòng hoặc tòa nhà',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: building == 'all',
                              onSelected: (_) {
                                setState(() => building = 'all');
                              },
                            ),
                            ...buildings.map((value) {
                              return ChoiceChip(
                                label: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: building == value,
                                onSelected: (_) {
                                  setState(() => building = value);
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      Text(
                        locked
                            ? 'Phòng của bạn'
                            : 'Danh sách phòng (${visible.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (visible.isEmpty)
                        const Text('Chưa có phòng phù hợp.'),
                      ...visible.map(
                        (room) => _roomCard(
                          room,
                          user,
                          auth.isAdmin,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}