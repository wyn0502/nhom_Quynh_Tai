
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tai_quynh_dormitory_management/controllers/auth_controller.dart';
import 'package:tai_quynh_dormitory_management/main.dart';

void main() {
  testWidgets(
    'Kiem tra giao dien quan ly ky tuc xa',
    (WidgetTester tester) async {
      // 1. Kiểm tra màn hình đăng nhập ban đầu
      AuthController.instance.logout();
      await tester.pumpWidget(const DormitoryApp());
      await tester.pumpAndSettle();

      expect(find.text('ĐĂNG NHẬP'), findsWidgets);
      expect(find.text('Tên đăng nhập'), findsOneWidget);

      // 2. Đăng nhập vào hệ thống
      AuthController.instance.quickLoginStudent();
      await tester.pumpAndSettle();

      // Kiểm tra logo thương hiệu DOMITORY
      expect(
        find.text('DOMITORY'),
        findsOneWidget,
      );

      // Kiểm tra các tab điều hướng
      expect(
        find.text('Trang chủ'),
        findsWidgets,
      );

      expect(
        find.text('Phòng KTX'),
        findsWidgets,
      );

      expect(
        find.text('Sinh viên'),
        findsWidgets,
      );

      expect(
        find.text('Hóa đơn'),
        findsWidgets,
      );

      // Kiểm tra chuyển sang màn hình Phòng KTX
      await tester.tap(
        find.byIcon(Icons.meeting_room_outlined).last,
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình cho Sinh viên
      expect(
        find.text('Quản lý Phòng KTX'),
        findsOneWidget,
      );

      // Kiểm tra phòng 101 được hiển thị
      expect(
        find.text('Phòng 101 - Tòa A'),
        findsWidgets,
      );
    },
  );
}

