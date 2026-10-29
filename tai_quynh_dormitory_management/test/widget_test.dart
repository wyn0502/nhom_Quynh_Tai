import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tai_quynh_dormitory_management/widgets/app_ui.dart';

void main() {
  for (final width in [280.0, 320.0, 375.0, 430.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'Bố cục không tràn ở chiều rộng $width, chữ $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1400);
          tester.view.devicePixelRatio = 1;

          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  return MediaQuery(
                    data: MediaQueryData(
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: Scaffold(
                      body: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          AppUi.card(
                            context,
                            title: 'Thành viên trong phòng',
                            icon: Icons.group_rounded,
                            badge:
                                'PHÒNG 101 - TÒA NHÀ SINH VIÊN',
                            children: [
                              AppUi.info(
                                'Họ tên',
                                'Sinh viên có họ tên dài '
                                    'để kiểm tra xuống dòng',
                              ),
                              AppUi.grid([
                                const Text('Thông tin phòng'),
                                const Text('Thông tin hóa đơn'),
                              ]),
                            ],
                          ),
                          AppUi.card(
                            context,
                            title: 'Thiết bị trong phòng',
                            children: const [
                              Text(
                                'Nội dung dài phải tự xuống dòng '
                                'khi màn hình nhỏ hoặc tăng cỡ chữ.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );

          expect(
            find.text('Thành viên trong phòng'),
            findsOneWidget,
          );

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}