
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'generic_screen.dart';

// Kế thừa GenericScreen với kiểu User
class UserScreen extends GenericScreen<User> {
  UserScreen({Key? key})
      : super(
          key: key,
          title: 'Quản lý Sinh viên KTX',
          items: [
            User(
              id: 1,
              username: 'nguyenvana',
              email: 'vana@example.com',
              fullName: 'Nguyễn Văn A',
              mssv: 'SV001',
              phone: '0912345678',
              className: 'CNTT01',
              hometown: 'Hà Nội',
              gender: 'Nam',
              roomId: 101,
              roomStatus: RoomStatus.approved,
            ),
            User(
              id: 2,
              username: 'tranthib',
              email: 'thib@example.com',
              fullName: 'Trần Thị B',
              mssv: 'SV002',
              phone: '0987654321',
              className: 'CNTT02',
              hometown: 'Đà Nẵng',
              gender: 'Nữ',
              roomStatus: RoomStatus.pending,
            ),
            User(
              id: 3,
              username: 'levanc',
              email: 'vanc@example.com',
              fullName: 'Lê Văn C',
              mssv: 'SV003',
              phone: '0901234567',
              className: 'CNTT03',
              hometown: 'Huế',
              gender: 'Nam',
              roomStatus: RoomStatus.none,
            ),
          ],
          itemBuilder: buildUserItem,
        );

  // Phân loại trạng thái phòng
  static String getRoomStatus(User user) {
    switch (user.roomStatus) {
      case RoomStatus.approved:
        return 'Đã có phòng';
      case RoomStatus.pending:
        return 'Đang chờ duyệt';
      case RoomStatus.rejected:
        return 'Bị từ chối';
      default:
        return 'Chưa đăng ký phòng';
    }
  }

  // Màu trạng thái phòng
  static Color getStatusColor(User user) {
    switch (user.roomStatus) {
      case RoomStatus.approved:
        return Colors.green;
      case RoomStatus.pending:
        return Colors.orange;
      case RoomStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Giao diện mỗi sinh viên
  static Widget buildUserItem(
    BuildContext context,
    User user,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue[100],
                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('MSSV: ${user.mssv ?? "Chưa có"}'),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Text('Email: ${user.email}'),
            const SizedBox(height: 6),

            Text('Lớp: ${user.className ?? "Chưa có"}'),
            const SizedBox(height: 6),

            Text(
              'Trạng thái: ${getRoomStatus(user)}',
              style: TextStyle(
                color: getStatusColor(user),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Xem chi tiết'),
                onPressed: () {
                  showUserDetail(context, user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị thông tin chi tiết User
  static void showUserDetail(
    BuildContext context,
    User user,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Thông tin sinh viên'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.getInfo()),
                const SizedBox(height: 8),
                Text(
                  'Giới tính: ${user.gender}',
                ),
                Text(
                  'Quê quán: ${user.hometown ?? "Chưa có"}',
                ),
                Text(
                  'Trạng thái: ${getRoomStatus(user)}',
                ),
                if (user.roomId != null)
                  Text('Phòng: ${user.roomId}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}
