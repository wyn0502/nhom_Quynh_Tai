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

    final raw = room?.id == null
        ? null
        : (await service.collection('rooms').doc(room!.id).get()).data();

    if (!context.mounted) return;

    final locked =
        ((raw?['equipment_count'] as num?)?.toInt() ?? 0) > 0;

    final saved = await AppUi.form(
      context,
      title: room == null ? 'Thêm phòng KTX' : 'Sửa phòng KTX',
      fields: [
        InputSpec(
          'building',
          'Tòa nhà *',
          value: room?.buildingId,
          enabled: !locked,
        ),
        InputSpec(
          'name',
          'Tên / số phòng *',
          value: room?.name,
          enabled: !locked,
        ),
        InputSpec(
          'capacity',
          'Số người tối đa (sức chứa) *',
          value: room?.capacity ?? 6,
          number: true,
          min: 1,
          max: 100,
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
        final capacity = values['capacity'] as num;

        if (capacity != capacity.round()) {
          throw StateError('Sức chứa phải là số nguyên.');
        }

        final updated = Room(
          id: room?.id,
          buildingId: '${values['building']}'.trim(),
          name: '${values['name']}'.trim(),
          capacity: capacity.toInt(),
          currentOccupancy: room?.currentOccupancy ?? 0,
          roomType: values['type'],
          fixedPrice: (values['price'] as num).toDouble(),
        );

        final rooms = await service.getRoomsStream().first;

        final duplicate = rooms.any(
          (item) =>
              item.id != room?.id &&
              item.name.toLowerCase() == updated.name.toLowerCase() &&
              item.buildingId.toLowerCase() ==
                  updated.buildingId.toLowerCase(),
        );

        if (duplicate) {
          throw StateError('Phòng này đã tồn tại trong tòa.');
        }

        if (room == null) {
          await service.addRoom(updated);
        } else {
          final current =
              (await service.collection('rooms').doc(room.id).get())
                  .data();

          if (((current?['equipment_count'] as num?)?.toInt() ?? 0) > 0 &&
              current?['label'] != updated.label) {
            throw StateError(
              'Phòng còn thiết bị đã bàn giao. '
              'Không đổi tên hoặc tòa trước khi thu hồi thiết bị.',
            );
          }

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