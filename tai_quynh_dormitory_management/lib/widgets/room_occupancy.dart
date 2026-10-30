import 'package:flutter/material.dart';

import '../models/room.dart';

class RoomOccupancy extends StatelessWidget {
  final Room room;

  const RoomOccupancy({
    super.key,
    required this.room,
  });

  static double ratio(Room room) {
    if (room.capacity <= 0) return 0;

    return (room.currentOccupancy / room.capacity)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static Color color(Room room) {
    if (!room.hasAvailableBeds()) {
      return const Color(0xFFDC2626);
    }

    if (ratio(room) >= 0.8) {
      return const Color(0xFFB77900);
    }

    return const Color(0xFF059669);
  }

  static String label(Room room) {
    if (room.capacity <= 0) {
      return 'Chưa có sức chứa';
    }

    if (!room.hasAvailableBeds()) {
      return 'Đã đầy';
    }

    if (ratio(room) >= 0.8) {
      return 'Gần đầy';
    }

    return 'Còn chỗ';
  }

  @override
  Widget build(BuildContext context) {
    final tint = color(room);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Hiện có ${room.currentOccupancy}/${room.capacity} người',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label(room),
                style: TextStyle(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: ratio(room),
          color: tint,
          backgroundColor: tint.withValues(alpha: 0.12),
          minHeight: 7,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Text(
          'Còn ${room.availableBeds} chỗ trống',
          style: TextStyle(color: tint),
        ),
      ],
    );
  }
}