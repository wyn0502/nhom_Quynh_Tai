import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/invoice.dart';
import '../models/asset.dart';
import '../models/announcement.dart';
import '../models/ticket.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';
import '../widgets/room_occupancy.dart';

import 'main_navigator.dart';
import 'management_screen.dart';
import 'manager_approval_screen.dart';
import 'room_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = FirestoreService();

  late final _rooms = service.getRoomsStream();

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

  List<Widget> _details(User user) {
    return [
      if (!user.isAdmin && user.hasActiveRoom) ...[
        AppUi.card(
          context,
          title: 'Thành viên trong phòng',
          icon: Icons.group_outlined,
          badge: user.pendingRoomName!,
          children: [
            AppUi.data<List<User>>(
              stream: service.getRoommatesStream(
                user.pendingRoomName!,
              ),
              builder: (members) => Column(
                children: [
                  if (members.isEmpty)
                    const Text('Chưa có thành viên.'),
                  for (final member in members)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(
                        '${member.displayName}'
                        '${member.username == user.username ? " (Bạn)" : ""}',
                      ),
                      subtitle: Text(
                        'MSSV: ${member.mssv ?? ""}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        AppUi.card(
          context,
          title: 'Thiết bị trong phòng',
          icon: Icons.inventory_2_outlined,
          children: [
            AppUi.data<List<RoomAsset>>(
              stream: service.getRoomAssetsStream(
                user.pendingRoomName!,
              ),
              builder: (assets) => Column(
                children: [
                  if (assets.isEmpty)
                    const Text('Chưa có thiết bị được bàn giao.'),
                  for (final asset in assets)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(asset.name),
                      subtitle: Text(
                        '${asset.description} • '
                        '${asset.statusLabel} • '
                        'Số lượng: ${asset.quantity}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
      _announcements(),
      _tickets(
        roomName: user.isAdmin ? null : user.pendingRoomName,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final user = AuthController.instance.currentUser;

        final invoices = !user.isAdmin && !user.hasActiveRoom
            ? Stream.value(<Invoice>[])
            : service.getInvoicesStream(
                roomName: user.isAdmin
                    ? null
                    : user.pendingRoomName,
              );

        return Scaffold(
          backgroundColor:
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF101321)
                  : Colors.white,
          appBar: AppBar(
            title: const Text(
              'DOMITORY •',
              style: TextStyle(
                color: HomeDashboard.purple,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              if (user.isAdmin)
                IconButton(
                  tooltip: 'Quản lý dữ liệu',
                  onPressed: () => _manage('announcements'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              IconButton(
                tooltip: 'Đổi giao diện',
                onPressed: () {
                  ThemeController.instance.toggleTheme();
                },
                icon: const Icon(Icons.brightness_6_outlined),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () {
                  AuthController.instance.logout();
                },
                icon: const Icon(
                  Icons.logout,
                  color: AppUi.red,
                ),
              ),
            ],
          ),
          body: AppUi.data<List<Room>>(
            stream: _rooms,
            builder: (rooms) => AppUi.data<List<Invoice>>(
              stream: invoices,
              builder: (items) => SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 960,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: HomeDashboard(
                        user: user,
                        rooms: rooms,
                        invoices: items,
                        onTab: (index) {
                          MainNavigator.switchToTab(
                            context,
                            index,
                          );
                        },
                        onAddRoom: () {
                          RoomEditor.show(context);
                        },
                        onManagers: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ManagerApprovalScreen(),
                            ),
                          );
                        },
                        onManage: () {
                          _manage('announcements');
                        },
                        onTicket: _createTicket,
                        details: _details(user),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeDashboard extends StatelessWidget {
  static const purple = Color(0xFF5141E8);

  final User user;
  final List<Room> rooms;
  final List<Invoice> invoices;

  final ValueChanged<int> onTab;
  final VoidCallback onAddRoom;
  final VoidCallback onManagers;
  final VoidCallback onManage;
  final VoidCallback onTicket;

  final List<Widget> details;

  const HomeDashboard({
    super.key,
    required this.user,
    required this.rooms,
    required this.invoices,
    required this.onTab,
    required this.onAddRoom,
    required this.onManagers,
    required this.onManage,
    required this.onTicket,
    this.details = const [],
  });

  Widget _task(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? action,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context)
                .dividerColor
                .withValues(alpha: 0.15),
          ),
        ),
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    Widget visual,
    String label,
  ) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1C2034)
            : const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: purple.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          visual,
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = user.isAdmin;

    final sorted = [...rooms]
      ..sort((a, b) {
        if (!admin) {
          final aMine = a.label == user.pendingRoomName;
          final bMine = b.label == user.pendingRoomName;

          if (aMine != bMine) {
            return aMine ? -1 : 1;
          }
        }

        return a.label.compareTo(b.label);
      });

    final own = sorted.where(
      (room) => room.label == user.pendingRoomName,
    ).toList();

    final summary =
        !admin && user.hasActiveRoom ? own : rooms;

    final capacity = summary.fold<int>(
      0,
      (sum, room) => sum + room.capacity,
    );

    final occupied = summary.fold<int>(
      0,
      (sum, room) => sum + room.currentOccupancy,
    );

    final ratio = capacity <= 0
        ? 0.0
        : (occupied / capacity)
            .clamp(0.0, 1.0)
            .toDouble();

    final amount = invoices.where(
      (invoice) => admin
          ? invoice.isPaid
          : !invoice.isPaid,
    ).fold<double>(
      0,
      (sum, invoice) => sum + invoice.totalAmount,
    );

    final unpaid = invoices.where(
      (invoice) => !invoice.isPaid,
    ).length;

    final ring = SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 8,
              color: purple,
              backgroundColor:
                  purple.withValues(alpha: 0.10),
            ),
          ),
          Text(
            '${(ratio * 100).round()}%',
            style: const TextStyle(
              color: purple,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );

    final money = Column(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFE7E3FF),
          child: Icon(
            Icons.payments_outlined,
            color: purple,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppUi.money(amount),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              'Chào ${user.displayName}! 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Chip(
              avatar: const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: purple,
              ),
              label: Text(user.roleLabel),
            ),
          ],
        ),
        Text(
          admin
              ? 'Cùng quản lý ký túc xá hôm nay nhé!'
              : 'Chúc bạn một ngày sinh hoạt thật tốt!',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            final single =
                constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context)
                        .scale(14) >
                    20;

            final left = _stat(
              context,
              ring,
              '${!admin && user.hasActiveRoom ? "Phòng của bạn" : "Lấp đầy toàn KTX"}'
              '\n$occupied/$capacity người',
            );

            final right = _stat(
              context,
              money,
              admin
                  ? 'Doanh thu đã thu'
                  : 'Hóa đơn chưa trả',
            );

            if (single) {
              return Column(
                children: [
                  left,
                  const SizedBox(height: 14),
                  right,
                ],
              );
            }

            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 16),
                Expanded(child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        const Text(
          'Tiếp theo là gì?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: purple,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: admin
                ? onAddRoom
                : () => onTab(
                      user.hasActiveRoom ? 4 : 1,
                    ),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DOMITORY • HÔM NAY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          admin
                              ? 'Thêm phòng KTX'
                              : user.hasActiveRoom
                                  ? 'Điểm danh tối nay'
                                  : 'Tìm phòng của bạn',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          admin
                              ? 'Tạo tòa, số phòng và sức chứa'
                              : user.hasActiveRoom
                                  ? '22:00–22:10 • Gửi ảnh tại phòng'
                                  : user.getRoomStatus(),
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(
                      admin
                          ? Icons.add
                          : Icons.arrow_forward,
                      color: purple,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'Công việc hôm nay',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        _task(
          context,
          'Phòng KTX',
          '${rooms.length} phòng • Xem sĩ số và chỗ trống',
          Icons.meeting_room_outlined,
          () => onTab(1),
        ),
        if (admin) ...[
          _task(
            context,
            'Sinh viên',
            'Duyệt phòng, xếp phòng và trả phòng',
            Icons.people_outline,
            () => onTab(2),
          ),
          _task(
            context,
            'Quản lý tòa',
            'Duyệt tài khoản và phân công tòa',
            Icons.security,
            onManagers,
          ),
        ],
        _task(
          context,
          'Hóa đơn',
          '$unpaid hóa đơn chưa thanh toán',
          Icons.receipt_long_outlined,
          () => onTab(3),
        ),
        _task(
          context,
          'Điểm danh & Tiền phạt',
          'Kiểm tra minh chứng và vi phạm trong tuần',
          Icons.fact_check_outlined,
          () => onTab(4),
        ),
        if (admin)
          _task(
            context,
            'Quản lý dữ liệu',
            'Thông báo, thiết bị và sự cố',
            Icons.settings_outlined,
            onManage,
          )
        else ...[
          _task(
            context,
            'Hồ sơ cá nhân',
            'Cập nhật thông tin và xem nội quy',
            Icons.badge_outlined,
            () => onTab(2),
          ),
          _task(
            context,
            'Báo sự cố',
            user.hasActiveRoom
                ? 'Gửi yêu cầu sửa chữa phòng'
                : 'Cần được duyệt phòng trước',
            Icons.build_outlined,
            user.hasActiveRoom ? onTicket : null,
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const Text(
              'Tình trạng phòng',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextButton(
              onPressed: () => onTab(1),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rooms.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              admin
                  ? 'Chưa có phòng. Bấm “Thêm phòng KTX” '
                      'ở thẻ tím để tạo phòng đầu tiên.'
                  : 'Chưa có phòng được công bố.',
            ),
          ),
        for (final room in sorted.take(4))
          AppUi.card(
            context,
            title: room.label,
            color: RoomOccupancy.color(room),
            icon: Icons.apartment_outlined,
            children: [
              RoomOccupancy(room: room),
            ],
          ),
        ...details,
      ],
    );
  }
}