import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tai_quynh_dormitory_management/controllers/auth_controller.dart';
import 'package:tai_quynh_dormitory_management/models/user.dart';
import 'package:tai_quynh_dormitory_management/services/firestore_service.dart';
import 'package:tai_quynh_dormitory_management/screens/home_screen.dart';
import 'package:tai_quynh_dormitory_management/screens/room_screen.dart';
import 'package:tai_quynh_dormitory_management/screens/invoice_screen.dart';
import 'package:tai_quynh_dormitory_management/screens/user_screen.dart';

void main() {
  testWidgets('Kiem tra luong dang ky sinh vien moi, dong bo du lieu va phe duyet admin', (WidgetTester tester) async {
    // 1. Đăng ký tài khoản sinh viên mới
    final regResult = await AuthController.instance.register(
      username: 'student_new',
      password: 'password123',
      email: 'student_new@ktx.com',
      fullName: 'Nguyen Van Test',
      mssv: 'SV9999',
      phone: '0912999888',
      className: 'K65-CNTT',
      hometown: 'Hai Duong',
      role: UserRole.student,
    );

    expect(regResult.success, isTrue);
    final User currentUser = AuthController.instance.currentUser;
    expect(currentUser.username, 'student_new');
    expect(currentUser.fullName, 'Nguyen Van Test');
    expect(currentUser.mssv, 'SV9999');
    expect(currentUser.roomStatus, RoomStatus.none);
    expect(currentUser.pendingRoomName, isNull);
    expect(currentUser.roomId, isNull);

    // 2. Kiểm tra HomeScreen cho sinh viên mới đăng ký
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify greeting and student info
    expect(find.text('Xin chào, Nguyen Van Test!'), findsOneWidget);
    expect(find.text('Chưa có phòng'), findsOneWidget);
    expect(find.text('Bạn chưa đăng ký phòng ở KTX'), findsOneWidget);
    expect(find.text('Đăng ký phòng ngay'), findsOneWidget);
    // Verify fake roommates are NOT present
    expect(find.text('Thành viên trong phòng'), findsNothing);

    // 3. Kiểm tra UserScreen (Hồ sơ Sinh viên)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: UserScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nguyen Van Test'), findsWidgets);
    expect(find.text('MSSV: SV9999 • K65-CNTT'), findsOneWidget);
    expect(find.text('CHƯA ĐĂNG KÝ'), findsOneWidget);
    expect(find.text('0912999888'), findsOneWidget);
    expect(find.text('Hai Duong'), findsOneWidget);

    // 4. Kiểm tra InvoiceScreen khi chưa có phòng
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InvoiceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CHƯA CÓ PHÒNG NỘI TRÚ'), findsOneWidget);
    expect(find.text('0 đ'), findsOneWidget);

    // 5. Kiểm tra RoomScreen & Sinh viên gửi yêu cầu đăng ký phòng
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RoomScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa đăng ký phòng nội trú'), findsOneWidget);

    // Sinh viên đăng ký phòng 101
    await FirestoreService().requestRoomRegistration(currentUser.id!, 'Phòng 101');
    await tester.pumpAndSettle();

    expect(AuthController.instance.currentUser.roomStatus, RoomStatus.pending);
    expect(AuthController.instance.currentUser.pendingRoomName, 'Phòng 101');

    // 6. Admin phê duyệt phòng cho sinh viên
    await FirestoreService().updateStudentRoomStatus(currentUser.id!, RoomStatus.approved, roomName: 'Phòng 101');
    await tester.pumpAndSettle();

    expect(AuthController.instance.currentUser.roomStatus, RoomStatus.approved);
    expect(AuthController.instance.currentUser.pendingRoomName, 'Phòng 101');

    // 7. Render lại HomeScreen sau khi đã được duyệt phòng
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PHÒNG 101'), findsWidgets);
    expect(find.text('Thành viên trong phòng'), findsOneWidget);
    expect(find.text('Thiết bị trong phòng'), findsOneWidget);
  });
}
