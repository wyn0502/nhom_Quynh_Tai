import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

import 'record_editor.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final service = FirestoreService();

  String search = '';
  String filter = 'all';

  Future<void> _editProfile(User user) async {
    final saved = await AppUi.form(
      context,
      title: 'Cập nhật hồ sơ',
      fields: [
        InputSpec(
          'phone',
          'Điện thoại',
          value: user.phone,
          required: false,
        ),
        InputSpec(
          'class_name',
          'Lớp',
          value: user.className,
          required: false,
        ),
        InputSpec(
          'hometown',
          'Quê quán',
          value: user.hometown,
          required: false,
        ),
      ],
      onSave: (values) {
        return service.updateUserProfile(
          user.id!,
          phone: values['phone'],
          className: values['class_name'],
          hometown: values['hometown'],
        );
      },
    );

    if (saved && mounted) {
      AppUi.message(context, 'Đã cập nhật hồ sơ.');
    }
  }

  Future<void> _changeStatus(
    User user,
    RoomStatus status,
  ) async {
    final confirmed = await AppUi.confirm(
      context,
      status == RoomStatus.approved
          ? 'Duyệt phòng cho ${user.displayName}?'
          : status == RoomStatus.rejected
              ? 'Từ chối yêu cầu của ${user.displayName}?'
              : 'Trả phòng cho ${user.displayName}?',
    );

    if (!confirmed || !mounted) return;

    await AppUi.run(
      context,
      () => service.updateStudentRoomStatus(
        user.id!,
        status,
      ),
      success: 'Đã cập nhật trạng thái phòng.',
    );
  }

  Future<void> _assignRoom(User user) async {
    try {
      final rooms = await service.getRoomsStream().first;

      if (!mounted) return;

      final options = <String, String>{};

      for (final room in rooms) {
        if (room.hasAvailableBeds()) {
          final label = FirestoreService.roomLabel(room);
          options[label] = label;
        }
      }

      if (options.isEmpty) {
        AppUi.message(
          context,
          'Chưa có phòng còn chỗ.',
          error: true,
        );
        return;
      }

      final saved = await AppUi.form(
        context,
        title: 'Xếp phòng cho ${user.displayName}',
        fields: [
          InputSpec(
            'room',
            'Chọn phòng',
            options: options,
          ),
        ],
        onSave: (values) {
          return service.updateStudentRoomStatus(
            user.id!,
            RoomStatus.approved,
            roomName: values['room'],
          );
        },
      );

      if (saved && mounted) {
        AppUi.message(context, 'Đã xếp phòng.');
      }
    } catch (error) {
      if (!mounted) return;

      AppUi.message(
        context,
        AppUi.errorText(error),
        error: true,
      );
    }
  }

  Future<void> _delete(User user) async {
    final confirmed = await AppUi.confirm(
      context,
      'Xóa hồ sơ ${user.displayName}?\n\n'
      'Nếu sinh viên đang ở phòng, sĩ số sẽ được giảm.',
    );

    if (!confirmed || !mounted) return;

    await AppUi.run(
      context,
      () => service.deleteUser(user.id!),
      success: 'Đã xóa hồ sơ sinh viên.',
    );
  }

  Widget _profile(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppUi.card(
          context,
          title: user.displayName,
          icon: Icons.account_circle_rounded,
          badge: user.getRoomStatus(),
          children: [
            AppUi.info('MSSV', user.mssv),
            AppUi.info('Lớp', user.className),
            if (user.pendingRoomName != null)
              AppUi.info(
                user.roomStatus == RoomStatus.pending
                    ? 'Phòng đang chờ duyệt'
                    : 'Phòng cư trú',
                user.pendingRoomName,
              ),
            if (user.roomStatus == RoomStatus.pending)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Vui lòng chờ admin xử lý. '
                  'Bạn chưa thể đăng ký phòng khác.',
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => _editProfile(user),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Cập nhật hồ sơ'),
            ),
          ],
        ),
        AppUi.card(
          context,
          title: 'Thông tin cá nhân',
          icon: Icons.badge_outlined,
          children: [
            AppUi.info('Họ tên', user.displayName),
            AppUi.info('Tên đăng nhập', user.username),
            AppUi.info('Email', user.email),
            AppUi.info('MSSV', user.mssv),
            AppUi.info('Điện thoại', user.phone),
            AppUi.info('Lớp', user.className),
            AppUi.info('Quê quán', user.hometown),
          ],
        ),
        AppUi.card(
          context,
          title: 'Nội quy ký túc xá',
          icon: Icons.rule,
          color: AppUi.orange,
          children: const [
            Text(
              '1. Giữ gìn trật tự và vệ sinh chung.\n\n'
              '2. Bảo quản thiết bị được bàn giao.\n\n'
              '3. Không tự ý chuyển hoặc đổi phòng.\n\n'
              '4. Thanh toán các khoản phí theo thông báo '
              'của ban quản lý.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _studentCard(User user) {
    return AppUi.card(
      context,
      title: user.displayName,
      icon: Icons.person_outline,
      badge: user.getRoomStatus(),
      children: [
        AppUi.info('MSSV', user.mssv),
        AppUi.info('Lớp', user.className),
        AppUi.info('Điện thoại', user.phone),
        if (user.pendingRoomName != null)
          AppUi.info(
            user.roomStatus == RoomStatus.pending
                ? 'Phòng đăng ký'
                : 'Phòng cư trú',
            user.pendingRoomName,
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                RecordEditor.edit(
                  context,
                  'users',
                  id: user.username,
                  data: user.toJson(),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa hồ sơ'),
            ),
            if (user.roomStatus == RoomStatus.pending) ...[
              FilledButton.icon(
                onPressed: () => _changeStatus(
                  user,
                  RoomStatus.approved,
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Duyệt phòng'),
              ),
              TextButton(
                onPressed: () => _changeStatus(
                  user,
                  RoomStatus.rejected,
                ),
                child: const Text('Từ chối'),
              ),
            ] else if (user.roomStatus == RoomStatus.approved)
              OutlinedButton(
                onPressed: () => _changeStatus(
                  user,
                  RoomStatus.none,
                ),
                child: const Text('Trả phòng'),
              )
            else
              OutlinedButton(
                onPressed: () => _assignRoom(user),
                child: const Text('Xếp phòng'),
              ),
            TextButton.icon(
              onPressed: () => _delete(user),
              icon: const Icon(
                Icons.delete_outline,
                color: AppUi.red,
              ),
              label: const Text(
                'Xóa hồ sơ',
                style: TextStyle(color: AppUi.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adminList() {
    return AppUi.data<List<User>>(
      stream: service.getStudentsStream(),
      builder: (students) {
        final keyword = search.trim().toLowerCase();

        final visible = students.where((user) {
          final matchesSearch =
              user.displayName.toLowerCase().contains(keyword) ||
                  (user.mssv ?? '')
                      .toLowerCase()
                      .contains(keyword) ||
                  user.username.toLowerCase().contains(keyword);

          final matchesStatus =
              filter == 'all' || user.roomStatus.name == filter;

          return matchesSearch && matchesStatus;
        }).toList()
          ..sort(
            (a, b) => a.displayName.compareTo(b.displayName),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() => search = value);
              },
              decoration: const InputDecoration(
                hintText: 'Tìm họ tên, tài khoản hoặc MSSV',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('Tất cả (${students.length})'),
                  selected: filter == 'all',
                  onSelected: (_) {
                    setState(() => filter = 'all');
                  },
                ),
                ...RoomStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(AppUi.status(status.name)),
                    selected: filter == status.name,
                    onSelected: (_) {
                      setState(() => filter = status.name);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Danh sách sinh viên (${visible.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const Text('Chưa có sinh viên phù hợp.'),
            ...visible.map(_studentCard),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final auth = AuthController.instance;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              auth.isAdmin
                  ? 'Quản lý Sinh viên'
                  : 'Hồ sơ Sinh viên',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              auth.isAdmin
                  ? _adminList()
                  : _profile(auth.currentUser),
            ],
          ),
        );
      },
    );
  }
}