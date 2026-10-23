
import 'package:flutter/material.dart';

import '../models/room.dart';
import 'generic_screen.dart';

// RoomScreen kế thừa Generic Layout
class RoomScreen extends GenericScreen<Room> {
  RoomScreen({Key? key})
      : super(
          key: key,
          title: 'Quản lý Phòng KTX',
          items: [
            Room(
              buildingId: 'Tòa A',
              name: '101',
              capacity: 4,
              currentOccupancy: 3,
              roomType: 'Tiêu chuẩn',
              fixedPrice: 1500000,
            ),
            Room(
              buildingId: 'Tòa A',
              name: '102',
              capacity: 6,
              currentOccupancy: 2,
              roomType: 'Tiêu chuẩn',
              fixedPrice: 1800000,
            ),
            Room(
              buildingId: 'Tòa B',
              name: '201',
              capacity: 4,
              currentOccupancy: 4,
              roomType: 'Cao cấp',
              fixedPrice: 2500000,
            ),
          ],
          itemBuilder: buildRoomItem,
        );

  // Giao diện riêng cho từng phòng
  static Widget buildRoomItem(
    BuildContext context,
    Room room,
  ) {
    return StatefulBuilder(
      builder: (context, setState) {
        // Thêm sinh viên vào phòng
        void addStudent() {
          final bool success = room.addOccupant();

          if (success) {
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Phòng đã đạt tối đa sức chứa!',
                ),
              ),
            );
          }
        }

        // Bớt sinh viên khỏi phòng
        void removeStudent() {
          final bool success = room.removeOccupant();

          if (success) {
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Phòng hiện đang trống!',
                ),
              ),
            );
          }
        }

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin tên phòng
                Row(
                  children: [
                    const Icon(
                      Icons.meeting_room,
                      color: Colors.blue,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phòng ${room.name} - ${room.buildingId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Text('Loại phòng: ${room.roomType}'),
                const SizedBox(height: 6),

                Text(
                  'Giá phòng: '
                  '${room.fixedPrice.toStringAsFixed(0)} VNĐ',
                ),
                const SizedBox(height: 6),

                Text(
                  'Sĩ số: '
                  '${room.currentOccupancy}/${room.capacity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Thanh thể hiện mức độ sử dụng phòng
                LinearProgressIndicator(
                  value: room.capacity > 0
                      ? room.currentOccupancy / room.capacity
                      : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    room.hasAvailableBeds()
                        ? Colors.green
                        : Colors.red,
                  ),
                ),

                const SizedBox(height: 16),

                // Nút thêm và bớt sinh viên
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: removeStudent,
                      icon: const Icon(Icons.remove),
                      label: const Text('Bớt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: addStudent,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
