import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/discipline_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

class ManagerApprovalScreen extends StatefulWidget {
  const ManagerApprovalScreen({super.key});

  @override
  State<ManagerApprovalScreen> createState() =>
      _ManagerApprovalScreenState();
}

class _ManagerApprovalScreenState extends State<ManagerApprovalScreen> {
  final service = DisciplineService();

  late final _managers = service.managers();

  Future<void> _approve(User user) async {
    try {
      final rooms = await FirestoreService().getRoomsStream().first;

      if (!mounted) return;

      final buildings = {
        for (final room in rooms) room.buildingId: room.buildingId,
      };

      if (buildings.isEmpty) {
        throw StateError('Hãy tạo phòng và tòa trước khi duyệt.');
      }

      await AppUi.form(
        context,
        title: 'Duyệt ${user.displayName}',
        fields: [
          InputSpec(
            'building',
            'Tòa phụ trách (tối đa 2 quản lý)',
            options: buildings,
          ),
        ],
        onSave: (values) => service.reviewManager(
          user,
          approve: true,
          building: values['building'] as String,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppUi.message(context, AppUi.errorText(error), error: true);
      }
    }
  }

  Future<void> _reject(User user) async {
    final accepted = await AppUi.confirm(
      context,
      user.canManageBuilding
          ? 'Thu hồi quyền quản lý của ${user.displayName}?'
          : 'Từ chối tài khoản ${user.displayName}?',
    );

    if (!accepted || !mounted) return;

    await AppUi.run(
      context,
      () => service.reviewManager(user, approve: false),
      success: 'Đã cập nhật tài khoản quản lý tòa.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt quản lý tòa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Sinh viên không cần duyệt tài khoản. '
            'Quản lý tòa chỉ được đăng nhập sau khi '
            'admin duyệt và phân công tòa.',
          ),
          const SizedBox(height: 16),
          AppUi.data<List<User>>(
            stream: _managers,
            builder: (users) => Column(
              children: [
                if (users.isEmpty)
                  const Text('Chưa có tài khoản quản lý tòa đăng ký.'),
                for (final user in users)
                  AppUi.card(
                    context,
                    title: user.displayName,
                    icon: Icons.security,
                    badge: user.managerStatus == ManagerStatus.pending
                        ? 'Chờ duyệt'
                        : user.canManageBuilding
                            ? 'Đã duyệt'
                            : 'Bị từ chối / thu hồi',
                    children: [
                      AppUi.info('Tài khoản', user.username),
                      AppUi.info('Điện thoại', user.phone),
                      AppUi.info('Nơi sinh sống', user.hometown),
                      if (user.canManageBuilding)
                        AppUi.info('Tòa phụ trách', user.managedBuildingId),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!user.canManageBuilding)
                            FilledButton(
                              onPressed: () => _approve(user),
                              child: const Text('Duyệt và phân công tòa'),
                            ),
                          if (user.managerStatus != ManagerStatus.rejected)
                            OutlinedButton(
                              onPressed: () => _reject(user),
                              child: Text(
                                user.canManageBuilding
                                    ? 'Thu hồi quyền'
                                    : 'Từ chối',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}