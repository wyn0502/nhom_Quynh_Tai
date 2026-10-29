import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/asset.dart';
import '../models/announcement.dart';
import '../models/invoice.dart';
import '../models/ticket.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

import 'main_navigator.dart';
import 'management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = FirestoreService();

  void _manage(String kind) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagementScreen(
          initialKind: kind,
        ),
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTicket() async {
    final student = AuthController.instance.currentUser;

    if (student.roomStatus != RoomStatus.approved ||
        student.pendingRoomName == null) {
      AppUi.message(
        context,
        'Bạn cần được duyệt phòng trước khi báo sự cố.',
        error: true,
      );
      return;
    }

    final saved = await AppUi.form(
      context,
      title: 'Báo cáo sự cố',
      fields: const [
        InputSpec('title', 'Tiêu đề'),
        InputSpec(
          'description',
          'Mô tả sự cố',
          lines: 4,
        ),
        InputSpec(
          'urgency',
          'Mức độ',
          value: 'medium',
          options: {
            'low': 'Thấp',
            'medium': 'Trung bình',
            'high': 'Khẩn cấp',
          },
        ),
      ],
      onSave: (values) {
        return service.createTicket(
          Ticket(
            id: 'ticket_${DateTime.now().microsecondsSinceEpoch}',
            roomName: student.pendingRoomName!,
            studentName: student.displayName,
            title: values['title'],
            description: values['description'],
            urgency: values['urgency'],
            status: 'pending',
            date: AppUi.today(),
          ),
        );
      },
    );

    if (saved && mounted) {
      AppUi.message(context, 'Đã gửi báo cáo sự cố.');
    }
  }

  Widget _announcements() {
    return AppUi.card(
      context,
      title: 'Bảng tin Ký túc xá',
      icon: Icons.campaign_rounded,
      color: AppUi.orange,
      children: [
        AppUi.data<List<Announcement>>(
          stream: service.getAnnouncementsStream(),
          builder: (items) {
            if (items.isEmpty) {
              return const Text('Chưa có thông báo.');
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            AppUi.badge(item.department),
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(item.content),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _tickets({String? roomName}) {
    final admin = AuthController.instance.isAdmin;

    return AppUi.card(
      context,
      title: admin
          ? 'Xử lý sự cố & Bảo trì'
          : 'Báo sự cố & Sửa chữa KTX',
      icon: Icons.handyman_outlined,
      color: AppUi.orange,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (admin)
              OutlinedButton.icon(
                onPressed: () => _manage('tickets'),
                icon: const Icon(Icons.edit_note),
                label: const Text('Quản lý sự cố'),
              )
            else
              FilledButton.icon(
                onPressed:
                    AuthController.instance.currentUser.hasActiveRoom
                        ? _createTicket
                        : null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Báo sự cố'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppUi.data<List<Ticket>>(
          stream: service.getTicketsStream(
            roomName: admin ? null : roomName,
          ),
          builder: (items) {
            if (items.isEmpty) {
              return const Text('Chưa có báo cáo sự cố.');
            }

            return Column(
              children: items.map((ticket) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppUi.navy.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          AppUi.badge(
                            AppUi.status(ticket.status),
                          ),
                          AppUi.badge(
                            AppUi.status(ticket.urgency),
                            color: ticket.urgency == 'high'
                                ? AppUi.red
                                : AppUi.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(ticket.description),
                      const SizedBox(height: 6),
                      Text(
                        '${ticket.roomName} • ${ticket.date}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _studentView() {
    final student = AuthController.instance.currentUser;
    final approved = student.hasActiveRoom;
    final roomName = student.pendingRoomName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppUi.card(
          context,
          title: 'Xin chào, ${student.displayName}! 👋',
          icon: Icons.account_circle_rounded,
          badge: approved
              ? roomName
              : student.getRoomStatus(),
          children: [
            Text(
              'MSSV: ${student.mssv ?? ""}'
              ' • ${student.className ?? ""}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        AppUi.grid(
          [
            _quickAction(
              'Đăng ký phòng',
              Icons.meeting_room_outlined,
              const Color(0xFF2563EB),
              () => MainNavigator.switchToTab(context, 1),
            ),
            _quickAction(
              'Hóa đơn',
              Icons.receipt_long_outlined,
              AppUi.orange,
              () => MainNavigator.switchToTab(context, 3),
            ),
            _quickAction(
              'Hồ sơ cá nhân',
              Icons.badge_outlined,
              AppUi.green,
              () => MainNavigator.switchToTab(context, 2),
            ),
            _quickAction(
              'Báo sự cố',
              Icons.build_circle_outlined,
              AppUi.red,
              approved ? _createTicket : null,
            ),
          ],
          minWidth: 60,
        ),
        const SizedBox(height: 18),
        if (!approved)
          AppUi.card(
            context,
            title: student.roomStatus == RoomStatus.pending
                ? 'Đang chờ duyệt phòng'
                : 'Chưa có phòng nội trú',
            icon: Icons.home_work_outlined,
            color: AppUi.orange,
            children: [
              Text(
                student.roomStatus == RoomStatus.pending
                    ? 'Bạn đã đăng ký $roomName. '
                        'Vui lòng chờ admin duyệt. '
                        'Trong thời gian này bạn không thể chọn phòng khác.'
                    : student.roomStatus == RoomStatus.rejected
                        ? 'Yêu cầu trước đã bị từ chối. '
                            'Bạn có thể chọn phòng khác.'
                        : 'Bạn chưa đăng ký phòng ở KTX.',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    MainNavigator.switchToTab(context, 1),
                child: Text(
                  student.roomStatus == RoomStatus.pending
                      ? 'Xem phòng đã đăng ký'
                      : 'Đăng ký phòng ngay',
                ),
              ),
            ],
          ),
        if (approved) ...[
          AppUi.card(
            context,
            title: 'Thành viên trong phòng',
            icon: Icons.group_rounded,
            badge: roomName,
            children: [
              AppUi.data<List<User>>(
                stream: service.getRoommatesStream(roomName),
                builder: (members) {
                  if (members.isEmpty) {
                    return const Text(
                      'Chưa tải được danh sách thành viên.',
                    );
                  }

                  return Column(
                    children: members.map((member) {
                      final isMe =
                          member.username == student.username;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: isMe
                                  ? AppUi.green
                                  : const Color(0xFF3B82F6),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'MSSV: ${member.mssv ?? ""}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  if (isMe)
                                    const Text(
                                      '★ Bạn',
                                      style: TextStyle(
                                        color: AppUi.green,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          AppUi.card(
            context,
            title: 'Thiết bị trong phòng',
            icon: Icons.inventory_2_outlined,
            color: AppUi.orange,
            children: [
              AppUi.data<List<RoomAsset>>(
                stream: service.getRoomAssetsStream(roomName),
                builder: (assets) {
                  if (assets.isEmpty) {
                    return const Text(
                      'Chưa có thiết bị được cấp cho phòng.',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: assets.map((asset) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              asset.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                AppUi.badge(
                                  asset.statusLabel,
                                  color: AppUi.green,
                                ),
                                AppUi.badge(
                                  'Số lượng: ${asset.quantity}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
        _announcements(),
        _tickets(roomName: roomName),
      ],
    );
  }

  Widget _stat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return AppUi.card(
      context,
      title: label,
      icon: icon,
      color: color,
      children: [
        Text(
          value,
          softWrap: true,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _adminView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppUi.card(
          context,
          title: 'Tổng quan hệ thống KTX',
          icon: Icons.admin_panel_settings_rounded,
          color: AppUi.orange,
          children: const [
            Text(
              'Doanh thu và tình trạng phòng '
              'được tính từ dữ liệu thực.',
            ),
          ],
        ),
        AppUi.grid(
          [
            _quickAction(
              'Phòng KTX',
              Icons.meeting_room_rounded,
              AppUi.navy,
              () => MainNavigator.switchToTab(context, 1),
            ),
            _quickAction(
              'Sinh viên',
              Icons.people_rounded,
              AppUi.green,
              () => MainNavigator.switchToTab(context, 2),
            ),
            _quickAction(
              'Hóa đơn',
              Icons.receipt_long_rounded,
              AppUi.orange,
              () => MainNavigator.switchToTab(context, 3),
            ),
            _quickAction(
              'Quản lý dữ liệu',
              Icons.settings_outlined,
              AppUi.navy,
              () => _manage('announcements'),
            ),
          ],
          minWidth: 70,
        ),
        const SizedBox(height: 18),
        AppUi.data<List<Invoice>>(
          stream: service.getInvoicesStream(),
          builder: (invoices) {
            return AppUi.data<List<Room>>(
              stream: service.getRoomsStream(),
              builder: (rooms) {
                final paid = invoices
                    .where((invoice) => invoice.isPaid)
                    .fold<double>(
                      0,
                      (sum, invoice) =>
                          sum + invoice.totalAmount,
                    );

                final unpaid = invoices
                    .where((invoice) => !invoice.isPaid)
                    .fold<double>(
                      0,
                      (sum, invoice) =>
                          sum + invoice.totalAmount,
                    );

                final capacity = rooms.fold<int>(
                  0,
                  (sum, room) => sum + room.capacity,
                );

                final occupancy = rooms.fold<int>(
                  0,
                  (sum, room) => sum + room.currentOccupancy,
                );

                return Column(
                  children: [
                    AppUi.grid([
                      _stat(
                        'Tổng doanh thu',
                        AppUi.money(paid),
                        Icons.payments_outlined,
                        AppUi.green,
                      ),
                      _stat(
                        'Chưa thanh toán',
                        AppUi.money(unpaid),
                        Icons.hourglass_top,
                        AppUi.orange,
                      ),
                      _stat(
                        'Tổng hóa đơn',
                        '${invoices.length}',
                        Icons.receipt_long,
                        const Color(0xFF3B82F6),
                      ),
                      _stat(
                        'Tổng số phòng',
                        '${rooms.length}',
                        Icons.apartment,
                        const Color(0xFF8B5CF6),
                      ),
                    ]),
                    AppUi.card(
                      context,
                      title: 'Doanh thu 6 tháng gần đây',
                      icon: Icons.bar_chart,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: List.generate(6, (index) {
                              final now = DateTime.now();

                              final month = DateTime(
                                now.year,
                                now.month - 5 + index,
                              );

                              final amount = invoices
                                  .where(
                                    (invoice) =>
                                        invoice.isPaid &&
                                        invoice.month ==
                                            month.month &&
                                        invoice.year ==
                                            month.year,
                                  )
                                  .fold<double>(
                                    0,
                                    (sum, invoice) =>
                                        sum + invoice.totalAmount,
                                  );

                              return SizedBox(
                                width: 86,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        AppUi.money(amount),
                                        textAlign:
                                            TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 24,
                                        height: paid == 0
                                            ? 0
                                            : 110 * amount / paid,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF93C5FD,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${month.month}/${month.year}',
                                        textAlign:
                                            TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    AppUi.card(
                      context,
                      title: 'Trạng thái phòng KTX',
                      icon: Icons.holiday_village_outlined,
                      badge: capacity == 0
                          ? '0% lấp đầy'
                          : '${(occupancy * 100 / capacity).round()}% lấp đầy',
                      children: [
                        if (rooms.isEmpty)
                          const Text('Chưa có phòng.'),
                        ...rooms.map((room) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 14,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${FirestoreService.roomLabel(room)}'
                                  ' — ${room.currentOccupancy}/${room.capacity}',
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: room.capacity <= 0
                                      ? 0
                                      : (room.currentOccupancy /
                                              room.capacity)
                                          .clamp(0.0, 1.0)
                                          .toDouble(),
                                  color: AppUi.green,
                                  backgroundColor:
                                      AppUi.green.withValues(
                                    alpha: 0.10,
                                  ),
                                  minHeight: 6,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
        _announcements(),
        _tickets(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final admin = AuthController.instance.isAdmin;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'DOMITORY',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppUi.navy,
                    ),
                  ),
                  TextSpan(
                    text: ' •',
                    style: TextStyle(
                      color: AppUi.orange,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              if (admin)
                IconButton(
                  tooltip: 'Quản lý dữ liệu',
                  onPressed: () => _manage('announcements'),
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 21,
                  ),
                ),
              IconButton(
                tooltip: 'Đổi giao diện',
                onPressed: () =>
                    ThemeController.instance.toggleTheme(),
                icon: const Icon(
                  Icons.brightness_6_outlined,
                  size: 21,
                ),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () =>
                    AuthController.instance.logout(),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppUi.red,
                  size: 21,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              admin ? _adminView() : _studentView(),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}