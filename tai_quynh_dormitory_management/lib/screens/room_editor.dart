import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

class RoomEditor {
  static Future<void> show(
    BuildContext context, {
    Room? room,
  }) async {
    if (!AuthController.instance.isAdmin) return;

    final service = FirestoreService();

    final saved = await AppUi.form(
      context,
      title: room == null ? 'Thêm phòng KTX' : 'Sửa phòng KTX',
      fields: [
        InputSpec(
          'building',
          'Tòa nhà *',
          value: room?.buildingId,
        ),
        InputSpec(
          'name',
          'Tên / số phòng *',
          value: room?.name,
        ),
        InputSpec(
          'capacity',
          'Số người tối đa (sức chứa) *',
          value: room?.capacity ?? 6,
          integer: true,
          min: 1,
        ),
        InputSpec(
          'current',
          'Số người hiện tại (tự cập nhật khi duyệt / trả phòng)',
          value: room?.currentOccupancy ?? 0,
          integer: true,
          enabled: false,
        ),
        InputSpec(
          'type',
          'Loại phòng',
          value: room?.roomType ?? 'Thường',
        ),
        InputSpec(
          'price',
          'Giá phòng (đ)',
          value: room?.fixedPrice ?? 0,
          number: true,
          min: 0,
        ),
      ],
      onSave: (values) async {
        final updated = Room(
          id: room?.id,
          buildingId: values['building'],
          name: values['name'],
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
          throw StateError(
            'Phòng này đã tồn tại trong tòa.',
          );
        }

        if (room == null) {
          await service.addRoom(updated);
        } else {
          await service.updateRoom(room.id!, updated);
        }
      },
    );

    if (saved && context.mounted) {
      AppUi.message(
        context,
        'Đã lưu phòng. Số người ở được đồng bộ khi duyệt / trả phòng.',
      );
    }
  }
}