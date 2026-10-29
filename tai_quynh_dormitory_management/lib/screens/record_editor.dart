import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

class RecordEditor {
  static const names = {
    'announcements': 'Thông báo',
    'assets': 'Thiết bị',
    'invoices': 'Hóa đơn',
    'tickets': 'Sự cố',
    'users': 'Sinh viên',
  };

  static const labels = <String, Map<String, String>>{
    'announcements': {
      'title': 'Tiêu đề',
      'content': 'Nội dung',
      'department': 'Đơn vị',
      'date': 'Ngày đăng',
    },
    'assets': {
      'room_name': 'Phòng',
      'name': 'Tên thiết bị',
      'description': 'Mô tả',
      'quantity': 'Số lượng',
      'status': 'Tình trạng',
    },
    'invoices': {
      'room_name': 'Phòng',
      'month': 'Tháng',
      'year': 'Năm',
      'room_fee': 'Tiền phòng',
      'electricity_fee': 'Tiền điện',
      'water_fee': 'Tiền nước',
      'total_amount': 'Tổng tiền',
      'status': 'Trạng thái',
    },
    'tickets': {
      'room_name': 'Phòng',
      'student_name': 'Người báo',
      'title': 'Tiêu đề',
      'description': 'Mô tả',
      'urgency': 'Mức độ',
      'status': 'Trạng thái',
      'date': 'Ngày báo',
    },
    'users': {
      'full_name': 'Họ tên',
      'email': 'Email liên hệ',
      'mssv': 'MSSV',
      'phone': 'Điện thoại',
      'class_name': 'Lớp',
      'hometown': 'Quê quán',
    },
  };

  static Future<bool> edit(
    BuildContext context,
    String kind, {
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final service = FirestoreService();

    if (!AuthController.instance.isAdmin) {
      AppUi.message(
        context,
        'Chỉ admin được thao tác.',
        error: true,
      );
      return false;
    }

    if (kind == 'users' && id == null) {
      AppUi.message(
        context,
        'Sinh viên tạo tài khoản qua màn hình đăng ký.',
        error: true,
      );
      return false;
    }

    final old = data ?? <String, dynamic>{};
    final fields = <InputSpec>[];
    final roomOptions = <String, String>{};

    if (['assets', 'invoices', 'tickets'].contains(kind)) {
      try {
        final rooms = await service.getRoomsStream().first;

        for (final room in rooms) {
          final label = FirestoreService.roomLabel(room);
          roomOptions[label] = label;
        }

        final oldRoom = old['room_name']?.toString();

        if (id != null &&
            oldRoom != null &&
            oldRoom.isNotEmpty) {
          roomOptions[oldRoom] = oldRoom;
        }
      } catch (_) {
        if (context.mounted) {
          AppUi.message(
            context,
            'Không thể tải danh sách phòng.',
            error: true,
          );
        }

        return false;
      }

      if (!context.mounted) return false;

      if (roomOptions.isEmpty) {
        AppUi.message(
          context,
          'Hãy tạo phòng tại tab Phòng KTX trước.',
          error: true,
        );
        return false;
      }

      fields.add(
        InputSpec(
          'room_name',
          'Phòng',
          value: old['room_name'],
          options: roomOptions,
          enabled: kind != 'invoices' || id == null,
        ),
      );
    }

    switch (kind) {
      case 'announcements':
        fields.addAll([
          InputSpec(
            'title',
            'Tiêu đề',
            value: old['title'],
          ),
          InputSpec(
            'content',
            'Nội dung',
            value: old['content'],
            lines: 4,
          ),
          InputSpec(
            'department',
            'Đơn vị',
            value: old['department'],
          ),
          InputSpec(
            'date',
            'Ngày đăng',
            value: old['date'] ?? AppUi.today(),
          ),
        ]);
        break;

      case 'assets':
        fields.addAll([
          InputSpec(
            'name',
            'Tên thiết bị',
            value: old['name'],
          ),
          InputSpec(
            'description',
            'Mô tả',
            value: old['description'],
            lines: 3,
          ),
          InputSpec(
            'quantity',
            'Số lượng',
            value: old['quantity'] ?? 1,
            integer: true,
            min: 1,
          ),
          InputSpec(
            'status',
            'Tình trạng',
            value: old['status'] ?? 'new',
            options: const {
              'new': 'Mới',
              'used': 'Đang dùng',
              'broken': 'Hỏng',
            },
          ),
        ]);
        break;

      case 'invoices':
        final now = DateTime.now();

        fields.addAll([
          InputSpec(
            'month',
            'Tháng',
            value: old['month'] ?? now.month,
            integer: true,
            min: 1,
            max: 12,
            enabled: id == null,
          ),
          InputSpec(
            'year',
            'Năm',
            value: old['year'] ?? now.year,
            integer: true,
            min: 1,
            enabled: id == null,
          ),
          InputSpec(
            'room_fee',
            'Tiền phòng',
            value: old['room_fee'] ?? 0,
            number: true,
            min: 0,
          ),
          InputSpec(
            'electricity_fee',
            'Tiền điện',
            value: old['electricity_fee'] ?? 0,
            number: true,
            min: 0,
          ),
          InputSpec(
            'water_fee',
            'Tiền nước',
            value: old['water_fee'] ?? 0,
            number: true,
            min: 0,
          ),
          InputSpec(
            'status',
            'Trạng thái',
            value: old['status'] ?? 'unpaid',
            options: const {
              'unpaid': 'Chưa thanh toán',
              'paid': 'Đã thanh toán',
            },
          ),
        ]);
        break;

      case 'tickets':
        fields.addAll([
          InputSpec(
            'student_name',
            'Người báo',
            value: old['student_name'],
          ),
          InputSpec(
            'title',
            'Tiêu đề',
            value: old['title'],
          ),
          InputSpec(
            'description',
            'Mô tả',
            value: old['description'],
            lines: 3,
          ),
          InputSpec(
            'urgency',
            'Mức độ',
            value: old['urgency'] ?? 'medium',
            options: const {
              'low': 'Thấp',
              'medium': 'Trung bình',
              'high': 'Khẩn cấp',
            },
          ),
          InputSpec(
            'status',
            'Trạng thái',
            value: old['status'] ?? 'pending',
            options: const {
              'pending': 'Chờ tiếp nhận',
              'processing': 'Đang xử lý',
              'completed': 'Hoàn thành',
            },
          ),
          InputSpec(
            'date',
            'Ngày báo',
            value: old['date'] ?? AppUi.today(),
          ),
        ]);
        break;

      case 'users':
        fields.addAll([
          InputSpec(
            'full_name',
            'Họ tên',
            value: old['full_name'],
          ),
          InputSpec(
            'mssv',
            'MSSV',
            value: old['mssv'],
          ),
          InputSpec(
            'email',
            'Email liên hệ',
            value: old['email'],
            required: false,
          ),
          InputSpec(
            'phone',
            'Điện thoại',
            value: old['phone'],
            required: false,
          ),
          InputSpec(
            'class_name',
            'Lớp',
            value: old['class_name'],
            required: false,
          ),
          InputSpec(
            'hometown',
            'Quê quán',
            value: old['hometown'],
            required: false,
          ),
        ]);
        break;

      default:
        return false;
    }

    if (!context.mounted) return false;

    final saved = await AppUi.form(
      context,
      title: '${id == null ? "Thêm" : "Sửa"} ${names[kind]}',
      fields: fields,
      onSave: (values) async {
        service.requireAdmin();

        if (kind == 'invoices') {
          values['total_amount'] =
              (values['room_fee'] as num) +
                  (values['electricity_fee'] as num) +
                  (values['water_fee'] as num);
        }

        if (id != null) {
          await service.collection(kind).doc(id).update(values);
          return;
        }

        if (kind == 'tickets') {
          values['owner_username'] =
              AuthController.instance.currentUser.username;
        }

        if (kind == 'invoices') {
          final invoiceId = Uri.encodeComponent(
            '${values['room_name']}_'
            '${values['year']}_${values['month']}',
          );

          final reference =
              service.collection(kind).doc(invoiceId);

          await service.db.runTransaction((transaction) async {
            if ((await transaction.get(reference)).exists) {
              throw StateError(
                'Phòng đã có hóa đơn trong kỳ này.',
              );
            }

            transaction.set(reference, values);
          });
        } else {
          await service.collection(kind).add(values);
        }
      },
    );

    if (saved && context.mounted) {
      AppUi.message(context, 'Đã lưu dữ liệu.');
    }

    return saved;
  }
}