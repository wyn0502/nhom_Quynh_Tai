import 'package:flutter_test/flutter_test.dart';

import 'package:tai_quynh_dormitory_management/controllers/auth_controller.dart';
import 'package:tai_quynh_dormitory_management/models/user.dart';

void main() {
  test('Lưu và đọc đúng trạng thái cùng tên phòng', () {
    final user = User(
      id: 10,
      username: 'student_test',
      email: '',
      roomStatus: RoomStatus.pending,
      pendingRoomName: 'Phòng 101 - Tòa A',
    );

    final decoded = User.fromJson(user.toJson());

    expect(decoded.roomStatus, RoomStatus.pending);

    expect(
      decoded.pendingRoomName,
      'Phòng 101 - Tòa A',
    );

    expect(decoded.canRegisterRoom, isFalse);

    user.pendingRoomName = null;
    user.roomStatus = RoomStatus.rejected;

    expect(
      user.toJson()['pending_room_name'],
      isNull,
    );

    expect(user.canRegisterRoom, isTrue);
  });

  test('Không ghi mật khẩu vào JSON hồ sơ', () {
    final user = User(
      username: 'student_test',
      email: '',
      password: 'example-password',
    );

    expect(user.toJson().containsKey('password'), isFalse);
  });

  for (final username in ['admin', ' ADMIN ']) {
    test('Không đăng ký tên admin: $username', () async {
      final result = await AuthController.instance.register(
        username: username,
        password: 'example-password',
        email: '',
        fullName: 'Test',
        mssv: 'TEST',
        phone: '',
        className: '',
        hometown: '',
        role: UserRole.student,
      );

      expect(result.success, isFalse);
      expect(AuthController.instance.isLoggedIn, isFalse);
    });
  }

  test('Không tự đăng ký vai trò admin', () async {
    final result = await AuthController.instance.register(
      username: 'another_admin',
      password: 'example-password',
      email: '',
      fullName: 'Test',
      mssv: 'TEST',
      phone: '',
      className: '',
      hometown: '',
      role: UserRole.admin,
    );

    expect(result.success, isFalse);
  });
}