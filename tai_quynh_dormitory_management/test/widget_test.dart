
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tai_quynh_dormitory_management/main.dart';

void main() {
  testWidgets(
    'Kiem tra giao dien quan ly ky tuc xa',
    (WidgetTester tester) async {
      // Khởi tạo giao diện ứng dụng
      await tester.pumpWidget(
        const DormitoryApp(),
      );

      // Kiểm tra màn hình Trang chủ
      expect(
        find.text('Trang chủ KTX'),
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
        find.byIcon(Icons.meeting_room_outlined),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Quản lý Phòng KTX'),
        findsOneWidget,
      );

      // Kiểm tra phòng 101 được hiển thị
      expect(
        find.text('Phòng 101 - Tòa A'),
        findsOneWidget,
      );
    },
  );
}
