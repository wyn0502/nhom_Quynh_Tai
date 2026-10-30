import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';
import '../widgets/room_occupancy.dart';

import 'room_editor.dart';

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

  Future<void> _editRoom([Room? room]) {
    return RoomEditor.show(context, room: room);
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
      badge: RoomOccupancy.label(room),
      color: RoomOccupancy.color(room),
      children: [
        AppUi.info('Loại phòng', room.roomType),
        AppUi.info('Giá phòng', AppUi.money(room.fixedPrice)),
        AppUi.info('Chỗ còn trống', room.availableBeds),
        RoomOccupancy(room: room),
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
                FirestoreService.roomLabel(room) ==
                        user.pendingRoomName
                    ? user.roomStatus == RoomStatus.pending
                        ? 'Phòng đang chờ duyệt'
                        : 'Phòng của bạn'
                    : 'Bạn đã có phòng hoặc đơn đăng ký khác',
                color: AppUi.navy,
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

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Phòng KTX',
              style: TextStyle(fontSize: 18),
            ),
            actions: [
              if (auth.isAdmin)
                TextButton.icon(
                  onPressed: () => _editRoom(),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Thêm phòng'),
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
                        'Bạn vẫn xem được tình trạng các phòng, '
                        'nhưng cần chờ admin xử lý trước khi đăng ký tiếp.',
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
                    final keyword = search.trim().toLowerCase();

                    final matchesBuilding =
                        building == 'all' ||
                        room.buildingId == building;

                    final matchesSearch =
                        keyword.isEmpty ||
                        room.name.toLowerCase().contains(keyword) ||
                        room.buildingId
                            .toLowerCase()
                            .contains(keyword);

                    return matchesBuilding && matchesSearch;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        'Danh sách phòng (${visible.length})',
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