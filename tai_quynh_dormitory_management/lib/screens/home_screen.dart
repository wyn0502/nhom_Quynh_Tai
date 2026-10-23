import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import 'main_navigator.dart';

/// Màn hình Trang chủ KTX - Bản sắc nguyên bản từ website DomitoryManagement-main
/// Sử dụng 100% Vector Icon (không dùng icon dạng text/emoji)
/// Phân quyền Sinh viên (Student) & Quản trị viên (Admin)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Màu sắc nhận diện từ website gốc
    final Color brandNavy = const Color(0xFF1E3A8A);
    final Color brandOrange = const Color(0xFFF97316);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final Color textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final bool isStudent = AuthController.instance.isStudent;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2F8),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            titleSpacing: 12,
            centerTitle: false,
            // Header thương hiệu DOMITORY với icon vector chống tràn tuyệt đối
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: brandNavy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'DOMITORY',
                  style: TextStyle(
                    color: isDark ? Colors.white : brandNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: brandOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            actions: [
              // Nút chuyển vai trò nhanh (Sinh viên <-> Admin)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: isStudent ? 'Chuyển sang Admin' : 'Chuyển sang Sinh viên',
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isStudent
                        ? const Color(0xFFEEF2FF)
                        : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isStudent ? Icons.school_rounded : Icons.admin_panel_settings_rounded,
                    color: isStudent ? brandNavy : const Color(0xFFD97706),
                    size: 17,
                  ),
                ),
                onPressed: () {
                  AuthController.instance.toggleRole();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1400),
                      backgroundColor: isStudent ? brandNavy : const Color(0xFF059669),
                      content: Row(
                        children: [
                          Icon(
                            isStudent ? Icons.admin_panel_settings_rounded : Icons.school_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isStudent
                                ? 'Đã chuyển sang: Quản trị viên (Admin)'
                                : 'Đã chuyển sang: Sinh viên (Le Tuan Quynh)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Nút Light / Dark mode
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Chuyển giao diện',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF475569),
                  size: 20,
                ),
                onPressed: () => ThemeController.instance.toggleTheme(),
              ),

              // Nút Đăng xuất hệ thống
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Đăng xuất',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                onPressed: () {
                  AuthController.instance.logout();
                },
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: isStudent
                ? _buildStudentView(context, isDark, cardBg, textPrimary, textSecondary, borderColor, brandNavy, brandOrange)
                : _buildAdminView(context, isDark, cardBg, textPrimary, textSecondary, borderColor, brandNavy, brandOrange),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. PHÂN HỆ GIAO DIỆN SINH VIÊN (Student Portal - Ảnh 3)
  // ===========================================================================
  Widget _buildStudentView(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
    Color brandOrange,
  ) {
    final student = AuthController.instance.currentUser;
    final bool hasApprovedRoom = student.roomStatus == RoomStatus.approved && student.pendingRoomName != null;
    final bool isPendingRoom = student.roomStatus == RoomStatus.pending;
    final String currentRoomName = student.pendingRoomName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1.1 Banner chào mừng sinh viên (Không tràn màn hình & động theo tài khoản)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: brandNavy,
                child: Text(
                  student.fullName?.isNotEmpty == true ? student.fullName![0].toUpperCase() : 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Xin chào, ${student.fullName?.isNotEmpty == true ? student.fullName : student.username}!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.waving_hand_rounded, color: Color(0xFFF59E0B), size: 15),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MSSV: ${student.mssv ?? "N/A"} • ${student.className ?? "Sinh viên"}',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasApprovedRoom
                      ? const Color(0xFFECFDF5)
                      : (isPendingRoom ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasApprovedRoom
                        ? const Color(0xFFA7F3D0)
                        : (isPendingRoom ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasApprovedRoom
                          ? Icons.check_circle_rounded
                          : (isPendingRoom ? Icons.hourglass_top_rounded : Icons.info_outline_rounded),
                      color: hasApprovedRoom
                          ? const Color(0xFF059669)
                          : (isPendingRoom ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasApprovedRoom
                          ? currentRoomName
                          : (isPendingRoom ? 'Chờ duyệt' : 'Chưa có phòng'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: hasApprovedRoom
                            ? const Color(0xFF059669)
                            : (isPendingRoom ? const Color(0xFFD97706) : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 1.2 Bốn nút thao tác nhanh liên kết các phân hệ
        Row(
          children: [
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.meeting_room_outlined,
                label: 'Đăng ký phòng',
                color: const Color(0xFF2563EB),
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => MainNavigator.switchToTab(context, 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.payments_outlined,
                label: 'Hóa đơn KTX',
                color: brandOrange,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => MainNavigator.switchToTab(context, 3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.badge_outlined,
                label: 'Hồ sơ cá nhân',
                color: const Color(0xFF059669),
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => MainNavigator.switchToTab(context, 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.build_circle_outlined,
                label: 'Báo sự cố',
                color: const Color(0xFFDC2626),
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => _showCreateTicketDialog(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 1.3 Khối Bạn cùng phòng / Trạng thái cư trú
        if (!hasApprovedRoom) ...[
          // Sinh viên chưa có phòng hoặc đang chờ duyệt -> Hiển thị thẻ thông báo & CTA rõ ràng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPendingRoom ? const Color(0xFFFDE68A) : borderColor,
                width: isPendingRoom ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPendingRoom
                            ? const Color(0xFFFEF3C7)
                            : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEEF2FF)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPendingRoom ? Icons.hourglass_top_rounded : Icons.meeting_room_outlined,
                        color: isPendingRoom ? const Color(0xFFD97706) : brandNavy,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPendingRoom
                                ? 'Đang chờ duyệt: ${student.pendingRoomName ?? "Phòng KTX"}'
                                : 'Bạn chưa đăng ký phòng ở KTX',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPendingRoom
                                ? 'Đơn xin đăng ký chỗ ở của bạn đang được Ban Quản lý KTX xem xét.'
                                : 'Vui lòng vào danh sách phòng để chọn phòng còn trống và gửi đơn đăng ký.',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => MainNavigator.switchToTab(context, 1),
                    icon: Icon(
                      isPendingRoom ? Icons.visibility_rounded : Icons.app_registration_rounded,
                      size: 16,
                    ),
                    label: Text(
                      isPendingRoom ? 'Xem tiến độ duyệt phòng' : 'Đăng ký phòng ngay',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPendingRoom ? const Color(0xFFD97706) : brandNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Sinh viên ĐÃ ĐƯỢC DUYỆT PHÒNG -> Hiển thị danh sách bạn cùng phòng thời gian thực
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group_rounded, color: brandNavy, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Thành viên trong phòng',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentRoomName.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<User>>(
                  stream: FirestoreService().getRoommatesStream(currentRoomName),
                  builder: (context, snapshot) {
                    final roommates = snapshot.data ?? [];
                    if (roommates.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildRoommateItem(
                          student.fullName?.isNotEmpty == true ? student.fullName! : student.username,
                          'MSSV: ${student.mssv ?? "N/A"}',
                          true,
                          isDark,
                          textPrimary,
                          textSecondary,
                        ),
                      );
                    }
                    return Column(
                      children: roommates.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final r = entry.value;
                        final bool isMe = (r.id == student.id) || (r.username.toLowerCase() == student.username.toLowerCase());
                        return Column(
                          children: [
                            if (idx > 0) const Divider(height: 16),
                            _buildRoommateItem(
                              r.fullName?.isNotEmpty == true ? r.fullName! : r.username,
                              'MSSV: ${r.mssv ?? "N/A"}',
                              isMe,
                              isDark,
                              textPrimary,
                              textSecondary,
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 1.4 Thiết bị trong phòng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: brandOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Thiết bị trong phòng',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '4 THIẾT BỊ',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: brandNavy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAssetItem('Giường tầng sắt', 'Giường sắt 2 tầng tiêu chuẩn', 2, 'MỚI', textPrimary, textSecondary),
                const Divider(height: 16),
                _buildAssetItem('Điều hòa 12000 BTU', 'Điều hòa Daikin làm mát phòng VIP', 1, 'MỚI', textPrimary, textSecondary),
                const Divider(height: 16),
                _buildAssetItem('Quạt trần Điện Cơ', 'Quạt trần 3 cánh mát mẻ', 2, 'MỚI', textPrimary, textSecondary),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        // 1.5 Bảng tin Ký túc xá (Ảnh 3)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Bảng tin Ký túc xá',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thẻ thông báo 1
              _buildAnnouncementCard(
                title: 'Thông báo đóng tiền phòng tháng 6/2026',
                department: 'Phòng Tài chính',
                date: '25/6/2026',
                content: 'Yêu cầu toàn bộ sinh viên kiểm tra hóa đơn trên hệ thống và hoàn thành thanh toán trực tuyến qua cổng VietQR PayOS trước ngày 20/06/2026.',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: 10),

              // Thẻ thông báo 2
              _buildAnnouncementCard(
                title: 'Bảo trì điều hòa phòng VIP ngày 22/06',
                department: 'Ban Cơ sở vật chất',
                date: '20/6/2026',
                content: 'Phòng ban cơ sở vật chất sẽ tiến hành vệ sinh bảo trì hệ thống điều hòa tại tầng 2 các tòa nhà.',
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 1.6 Báo cáo sự cố & Sửa chữa thiết bị
        _buildStudentTicketsCard(
          isDark,
          cardBg,
          textPrimary,
          textSecondary,
          borderColor,
          brandNavy,
          brandOrange,
          roomName: hasApprovedRoom ? currentRoomName : (isPendingRoom ? student.pendingRoomName : null),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ===========================================================================
  // 2. PHÂN HỆ GIAO DIỆN QUẢN TRỊ VIÊN (Admin Dashboard - Ảnh 4 & 5)
  // ===========================================================================
  Widget _buildAdminView(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
    Color brandOrange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2.1 Tiêu đề Dashboard
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF59E0B),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan hệ thống KTX',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chào mừng Admin, đây là tổng quan doanh thu và tình trạng KTX.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Thao tác quản trị nhanh
        Row(
          children: [
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.meeting_room_rounded,
                label: 'Xếp phòng KTX',
                color: brandNavy,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => MainNavigator.switchToTab(context, 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.how_to_reg_rounded,
                label: 'Duyệt sinh viên',
                color: const Color(0xFF059669),
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => MainNavigator.switchToTab(context, 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionBtn(
                icon: Icons.receipt_long_rounded,
                label: 'Lập hóa đơn',
                color: brandOrange,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                onTap: () => MainNavigator.switchToTab(context, 3),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 2.2 BỐN THẺ CHỈ SỐ TỔNG QUAN (Theo đúng giao diện Web Ảnh 4)
        Row(
          children: [
            Expanded(
              child: _buildAdminStatCard(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
                title: 'TỔNG DOANH THU',
                value: '3.789.000 đ',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAdminStatCard(
                icon: Icons.hourglass_top_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFEF3C7),
                title: 'CHƯA THANH TOÁN',
                value: '8.389.000 đ',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildAdminStatCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBg: const Color(0xFFEFF6FF),
                title: 'TỔNG HÓA ĐƠN',
                value: '9',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAdminStatCard(
                icon: Icons.holiday_village_rounded,
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF5F3FF),
                title: 'TỔNG SỐ PHÒNG',
                value: '4',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 2.3 Biểu đồ doanh thu mô phỏng Chart.js (Ảnh 4)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Doanh Thu Theo Tháng (Chart.js)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Tháng 7/2026',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: brandNavy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildChartBar('Tháng 5', 40, isDark),
                  _buildChartBar('Tháng 6', 70, isDark),
                  _buildChartBar('Tháng 7', 120, isDark, isHighlight: true),
                  _buildChartBar('Tháng 8', 30, isDark),
                  _buildChartBar('Tháng 9', 85, isDark),
                  _buildChartBar('Tháng 10', 95, isDark),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2.4 Quản lý nhanh Phòng KTX & Sức chứa (Ảnh 5)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trạng thái phòng KTX',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Tỷ lệ lấp đầy: 70%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRoomOccupancyRow('Phòng A101 (Tòa A)', '2/4 CÒN CHỖ', 0.5, textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildRoomOccupancyRow('Phòng A102 (Tòa A)', '1/4 CÒN CHỖ', 0.25, textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildRoomOccupancyRow('Phòng A201 (VIP)', '1/6 CÒN CHỖ', 0.17, textPrimary, textSecondary),
              const SizedBox(height: 10),
              _buildRoomOccupancyRow('Phòng B101 (Tòa B)', '2/4 CÒN CHỖ', 0.5, textPrimary, textSecondary),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2.5 Quản lý Báo cáo sự cố KTX (Tickets từ quan_ly_ktx.sql)
        _buildAdminTicketsCard(isDark, cardBg, textPrimary, textSecondary, borderColor, brandNavy, brandOrange),

        const SizedBox(height: 20),
      ],
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoommateItem(String name, String mssv, bool isMe, bool isDark, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isMe ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              Text(mssv, style: TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ),
        ),
        if (isMe)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star_rounded, color: Color(0xFF059669), size: 12),
                SizedBox(width: 2),
                Text(
                  'BẠN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAssetItem(String name, String desc, int quantity, String status, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              Text(desc, style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF059669), size: 11),
              const SizedBox(width: 3),
              Text(
                status,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'x$quantity',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String department,
    required String date,
    required String content,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: department.contains('Tài chính') ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  department,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: department.contains('Tài chính') ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(date, style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAdminStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String month, double height, bool isDark, {bool isHighlight = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFF1E3A8A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFF93C5FD)),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: TextStyle(fontSize: 9, color: isHighlight ? const Color(0xFF1E3A8A) : Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildRoomOccupancyRow(String roomName, String badgeText, double ratio, Color textPrimary, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(roomName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      ],
    );
  }

  // Dữ liệu mẫu sự cố KTX đồng bộ quan_ly_ktx.sql
  final List<Ticket> _fallbackTickets = [
    Ticket(
      id: 'ticket_1',
      roomName: 'Phòng B101',
      studentName: 'Le Tuan Quynh',
      title: 'Hỏng bóng đèn tuýp LED',
      description: 'Bóng đèn nhà vệ sinh bị chập chờn nhấp nháy liên tục.',
      urgency: 'medium',
      status: 'pending',
      date: '25/06/2026',
    ),
    Ticket(
      id: 'ticket_2',
      roomName: 'Phòng A101',
      studentName: 'Trần Thị Quỳnh',
      title: 'Điều hòa rò rỉ nước',
      description: 'Dàn lạnh điều hòa nhỏ giọt nước xuống sàn nhà.',
      urgency: 'high',
      status: 'processing',
      date: '24/06/2026',
    ),
  ];

  // ===========================================================================
  // BÁO CÁO SỰ CỐ & SỬA CHỮA THIẾT BỊ (Sinh viên)
  // ===========================================================================
  Widget _buildStudentTicketsCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
    Color brandOrange, {
    String? roomName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.build_circle_rounded, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Báo sự cố & Sửa chữa KTX',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateTicketDialog(context),
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Báo sự cố'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Ticket>>(
            stream: FirestoreService().getTicketsStream(roomName: roomName),
            builder: (context, snapshot) {
              final tickets = snapshot.data ?? [];

              if (tickets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa có báo cáo sự cố nào.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                );
              }

              return Column(
                children: tickets.map((t) => _buildTicketItem(t, textPrimary, textSecondary, isDark, borderColor)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // QUẢN LÝ BÁO CÁO SỰ CỐ (Admin)
  // ===========================================================================
  Widget _buildAdminTicketsCard(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
    Color brandOrange,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.handyman_rounded, color: Color(0xFFEA580C), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Xử lý Sự cố & Bảo trì',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'BẢO TRÌ KTX',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Ticket>>(
            stream: FirestoreService().getTicketsStream(),
            builder: (context, snapshot) {
              final tickets = (snapshot.hasData && snapshot.data!.isNotEmpty)
                  ? snapshot.data!
                  : _fallbackTickets;

              if (tickets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('Không có sự cố nào cần xử lý!', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ),
                );
              }

              return Column(
                children: tickets.map((t) => _buildAdminTicketItem(t, textPrimary, textSecondary, isDark, borderColor)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(Ticket t, Color textPrimary, Color textSecondary, bool isDark, Color borderColor) {
    final bool isDone = t.status == 'completed';
    final bool isProcessing = t.status == 'processing';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : (isProcessing ? Icons.pending_rounded : Icons.report_problem_rounded),
            color: isDone ? const Color(0xFF10B981) : (isProcessing ? const Color(0xFF3B82F6) : const Color(0xFFEF4444)),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFFECFDF5)
                            : (isProcessing ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDone ? 'ĐÃ XỬ LÝ' : (isProcessing ? 'ĐANG XỬ LÝ' : 'CHỜ TIẾP NHẬN'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDone
                              ? const Color(0xFF059669)
                              : (isProcessing ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(t.description, style: TextStyle(fontSize: 11, color: textSecondary)),
                const SizedBox(height: 4),
                Text('${t.roomName} • ${t.date}', style: TextStyle(fontSize: 10, color: textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTicketItem(Ticket t, Color textPrimary, Color textSecondary, bool isDark, Color borderColor) {
    final bool isDone = t.status == 'completed';
    final bool isProcessing = t.status == 'processing';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t.roomName} – ${t.studentName}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFFECFDF5)
                      : (isProcessing ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isDone ? 'HOÀN THÀNH' : (isProcessing ? 'ĐANG SỬA' : 'CHƯA XỬ LÝ'),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isDone
                        ? const Color(0xFF059669)
                        : (isProcessing ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(t.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 2),
          Text(t.description, style: TextStyle(fontSize: 11, color: textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gửi lúc: ${t.date}', style: TextStyle(fontSize: 10, color: textSecondary)),
              Row(
                children: [
                  if (!isDone)
                    ElevatedButton(
                      onPressed: () {
                        final nextStatus = isProcessing ? 'completed' : 'processing';
                        FirestoreService().updateTicketStatus(t.id, nextStatus);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã cập nhật trạng thái sự cố: ${isProcessing ? "Hoàn thành" : "Đang xử lý"}')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isProcessing ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      child: Text(isProcessing ? 'Hoàn thành' : 'Tiếp nhận'),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Xóa phiếu sự cố',
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
                    onPressed: () {
                      FirestoreService().deleteTicket(t.id);
                      setState(() {
                        _fallbackTickets.removeWhere((item) => item.id == t.id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa phiếu sự cố.')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialog báo sự cố mới cho sinh viên
  void _showCreateTicketDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String urgency = 'medium';
    final student = AuthController.instance.currentUser;
    String roomName = student.pendingRoomName ?? (student.roomId != null ? 'Phòng ${student.roomId}' : 'KTX');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 8),
              Text('Báo cáo sự cố KTX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề sự cố *',
                    hintText: 'VD: Hỏng bóng đèn, Rò rỉ nước...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết *',
                    hintText: 'Vị trí sự cố trong phòng và hiện tượng...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: urgency,
                  decoration: const InputDecoration(labelText: 'Mức độ khẩn cấp'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Thấp - Chờ bảo trì định kỳ')),
                    DropdownMenuItem(value: 'medium', child: Text('Trung bình - Sửa trong tuần')),
                    DropdownMenuItem(value: 'high', child: Text('Khẩn cấp - Sửa trong ngày')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => urgency = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                if (title.isEmpty || desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin sự cố.')),
                  );
                  return;
                }

                final newTicket = Ticket(
                  id: 'ticket_${DateTime.now().millisecondsSinceEpoch}',
                  roomName: roomName,
                  studentName: AuthController.instance.currentUser.fullName ?? 'Sinh viên',
                  title: title,
                  description: desc,
                  urgency: urgency,
                  status: 'pending',
                  date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                );

                FirestoreService().createTicket(newTicket);
                setState(() {
                  _fallbackTickets.insert(0, newTicket);
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF059669),
                    content: Text('Đã gửi báo cáo sự cố thành công tới Ban Quản lý!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Gửi báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}
