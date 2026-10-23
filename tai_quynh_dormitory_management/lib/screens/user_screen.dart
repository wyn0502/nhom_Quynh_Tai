import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

/// Màn hình Quản lý Sinh viên & Hồ sơ nội trú
/// Phân quyền chặt chẽ:
/// - Sinh viên: Xem & Chỉnh sửa hồ sơ cá nhân (SĐT, Quê quán, Lớp), theo dõi trạng thái duyệt phòng KTX
/// - Admin: Xem danh sách sinh viên thời gian thực qua Firebase, Duyệt / Từ chối đơn đăng ký, Xếp phòng & Xóa sinh viên
class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  // Dữ liệu mẫu dự phòng ban đầu đồng bộ với quan_ly_ktx.sql
  final List<User> _mockFallbackStudents = [
    User(
      id: 6,
      username: 'wyn05',
      email: 'wyn05@gmail.com',
      fullName: 'Le Tuan Quynh',
      mssv: '24104502',
      phone: '0342130000',
      className: 'ICT1.24105.3',
      hometown: 'Điện Biên',
      gender: 'Nam',
      roomId: 101,
      roomStatus: RoomStatus.approved,
      pendingRoomName: 'Phòng B101',
    ),
    User(
      id: 2,
      username: 'student1',
      email: 'student1@ktx.com',
      fullName: 'Trần Thị Quỳnh',
      mssv: 'SV202401',
      phone: '0977777777',
      className: 'CNTT01',
      hometown: 'Hải Phòng',
      gender: 'Nữ',
      roomId: 101,
      roomStatus: RoomStatus.approved,
      pendingRoomName: 'Phòng A101',
    ),
    User(
      id: 3,
      username: 'student2',
      email: 'student2@ktx.com',
      fullName: 'Lê Văn Đông',
      mssv: 'SV202402',
      phone: '0966666666',
      className: 'Kế Toán 02',
      hometown: 'Đà Nẵng',
      gender: 'Nam',
      roomId: 102,
      roomStatus: RoomStatus.approved,
      pendingRoomName: 'Phòng A102',
    ),
    User(
      id: 4,
      username: 'student3',
      email: 'student3@ktx.com',
      fullName: 'Đặng Đức Tài',
      mssv: 'SV202403',
      phone: '0912345678',
      className: 'CNTT02',
      hometown: 'Hà Nội',
      gender: 'Nam',
      roomStatus: RoomStatus.pending,
      pendingRoomName: 'Phòng A201',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color brandNavy = Color(0xFF1E3A8A);
    const Color brandOrange = Color(0xFFF97316);
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
            title: Row(
              children: [
                Icon(
                  isStudent ? Icons.badge_rounded : Icons.manage_accounts_rounded,
                  color: isStudent ? brandNavy : brandOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isStudent ? 'Hồ sơ Sinh viên KTX' : 'Quản lý Danh sách Sinh viên',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: isStudent
                ? _buildStudentProfile(isDark, cardBg, textPrimary, textSecondary, borderColor, brandNavy)
                : _buildAdminStudentList(isDark, cardBg, textPrimary, textSecondary, borderColor, brandNavy),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. GIAO DIỆN HỒ SƠ SINH VIÊN (Dành cho Sinh viên)
  // ===========================================================================
  Widget _buildStudentProfile(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
  ) {
    final student = AuthController.instance.currentUser;
    final bool isApproved = student.roomStatus == RoomStatus.approved;
    final bool isPending = student.roomStatus == RoomStatus.pending;
    final bool isRejected = student.roomStatus == RoomStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thẻ thông tin định danh
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
                radius: 28,
                backgroundColor: brandNavy,
                child: Text(
                  student.fullName?.isNotEmpty == true ? student.fullName![0].toUpperCase() : 'S',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName?.isNotEmpty == true ? student.fullName! : student.username,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MSSV: ${student.mssv?.isNotEmpty == true ? student.mssv : "Chưa có"} • ${student.className?.isNotEmpty == true ? student.className : "Chưa phân lớp"}',
                      style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chỉnh sửa thông tin liên hệ',
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E3A8A), size: 20),
                onPressed: () => _showEditProfileDialog(student),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Trạng thái cư trú phòng
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isApproved
                ? const Color(0xFFECFDF5)
                : (isPending ? const Color(0xFFFEF3C7) : (isRejected ? const Color(0xFFFEF2F2) : cardBg)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isApproved
                  ? const Color(0xFFA7F3D0)
                  : (isPending ? const Color(0xFFFDE68A) : (isRejected ? const Color(0xFFFECACA) : borderColor)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_rounded
                            : (isPending ? Icons.pending_actions_rounded : (isRejected ? Icons.cancel_rounded : Icons.info_outline)),
                        color: isApproved
                            ? const Color(0xFF059669)
                            : (isPending ? const Color(0xFFD97706) : (isRejected ? const Color(0xFFDC2626) : const Color(0xFF64748B))),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Trạng thái cư trú KTX',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isApproved
                              ? const Color(0xFF065F46)
                              : (isPending ? const Color(0xFF92400E) : (isRejected ? const Color(0xFF991B1B) : textPrimary)),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFF10B981)
                          : (isPending ? const Color(0xFFF59E0B) : (isRejected ? const Color(0xFFEF4444) : Colors.grey)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isApproved
                          ? 'ĐÃ DUYỆT PHÒNG'
                          : (isPending ? 'ĐANG CHỜ DUYỆT' : (isRejected ? 'TỪ CHỐI' : 'CHƯA ĐĂNG KÝ')),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isApproved) ...[
                Text(
                  'Bạn hiện đang cư trú tại ${student.pendingRoomName ?? "phòng KTX"}. Mọi khoản phí dịch vụ và quy chế KTX được đồng bộ trên hệ thống.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF065F46)),
                ),
              ] else if (isPending) ...[
                Text(
                  'Yêu cầu đăng ký ${student.pendingRoomName ?? "Phòng KTX"} của bạn đã được chuyển tới ban quản lý KTX để phê duyệt.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    FirestoreService().updateStudentRoomStatus(student.id ?? 6, RoomStatus.none, roomName: '');
                    setState(() {
                      student.roomStatus = RoomStatus.none;
                      student.pendingRoomName = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã hủy yêu cầu đăng ký phòng.')),
                    );
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Hủy yêu cầu đăng ký'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF92400E),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                  ),
                ),
              ] else ...[
                Text(
                  'Bạn chưa có phòng nội trú. Hãy truy cập tab "Phòng KTX" để chọn phòng và nhấn "Đăng ký phòng này".',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Khối Thông tin tài khoản
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
                    'Thông tin tài khoản & Liên hệ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFFD97706)),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditProfileDialog(student),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildProfileRow('Họ và Tên', student.fullName?.isNotEmpty == true ? student.fullName! : student.username, textPrimary, textSecondary),
              _buildProfileRow('Tên đăng nhập', student.username, textPrimary, textSecondary),
              _buildProfileRow('Email', student.email.isNotEmpty ? student.email : 'Chưa cập nhật', textPrimary, textSecondary),
              _buildProfileRow('Số điện thoại', student.phone?.isNotEmpty == true ? student.phone! : 'Chưa cập nhật', textPrimary, textSecondary),
              _buildProfileRow('Địa chỉ thường trú', student.hometown?.isNotEmpty == true ? student.hometown! : 'Chưa cập nhật', textPrimary, textSecondary),
              _buildProfileRow('Lớp sinh viên', student.className?.isNotEmpty == true ? student.className! : 'Chưa cập nhật', textPrimary, textSecondary),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Khối Quy chế & Nội quy KTX
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
                children: const [
                  Icon(Icons.gavel_rounded, color: Color(0xFF1E3A8A), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Nội quy sinh viên nội trú KTX',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRuleItem('1. Giữ gìn trật tự và vệ sinh chung khu vực phòng ở và hành lang.'),
              _buildRuleItem('2. Giờ mở cửa: 05:00 - Giờ đóng cửa: 23:00 hàng ngày.'),
              _buildRuleItem('3. Tuyệt đối không đun nấu bằng bếp điện công suất lớn trái quy định.'),
              _buildRuleItem('4. Thanh toán tiền phòng và hóa đơn điện nước trước ngày 20 hàng tháng.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
      ),
    );
  }

  // ===========================================================================
  // 2. GIAO DIỆN QUẢN LÝ SINH VIÊN (Admin - Có liên kết Firebase & CRUD)
  // ===========================================================================
  Widget _buildAdminStudentList(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
  ) {
    return StreamBuilder<List<User>>(
      stream: FirestoreService().getStudentsStream(),
      builder: (context, snapshot) {
        // Sử dụng dữ liệu trực tiếp từ Centralized Reactive Store & Firestore
        final List<User> students = snapshot.data ?? [];

        final filtered = students.where((s) {
          final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s.mssv?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
              (s.hometown?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

          if (_filterStatus == 'approved') return matchesSearch && s.roomStatus == RoomStatus.approved;
          if (_filterStatus == 'pending') return matchesSearch && s.roomStatus == RoomStatus.pending;
          if (_filterStatus == 'none') return matchesSearch && (s.roomStatus == RoomStatus.none || s.roomStatus == RoomStatus.rejected);
          return matchesSearch;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh tìm kiếm
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: textSecondary, size: 20),
                  border: InputBorder.none,
                  hintText: 'Tìm theo tên, MSSV, quê quán...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            const SizedBox(height: 12),

            // Tabs lọc trạng thái
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả (${students.length})', 'all', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đã có phòng', 'approved', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chờ duyệt', 'pending', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chưa xếp phòng', 'none', isDark),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách Sinh viên (${filtered.length})',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary),
                ),
                Text(
                  snapshot.hasData ? 'Đồng bộ Firebase' : 'Dữ liệu cục bộ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: snapshot.hasData ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded, size: 48, color: textSecondary),
                    const SizedBox(height: 8),
                    Text('Không tìm thấy sinh viên phù hợp', style: TextStyle(color: textSecondary, fontSize: 13)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final s = filtered[index];
                  final bool isApproved = s.roomStatus == RoomStatus.approved;
                  final bool isPending = s.roomStatus == RoomStatus.pending;
                  final bool isRejected = s.roomStatus == RoomStatus.rejected;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
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
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: brandNavy,
                                  child: Text(
                                    s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                                    Text('MSSV: ${s.mssv ?? "N/A"} • Lớp: ${s.className ?? "N/A"}', style: TextStyle(fontSize: 11, color: textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? const Color(0xFFECFDF5)
                                    : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFFEF2F2)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isApproved ? 'ĐÃ CÓ PHÒNG' : (isPending ? 'CHỜ DUYỆT' : (isRejected ? 'TỪ CHỐI' : 'CHƯA XẾP')),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isApproved
                                      ? const Color(0xFF059669)
                                      : (isPending ? const Color(0xFFD97706) : const Color(0xFFEF4444)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.meeting_room_outlined, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Phòng: ${s.pendingRoomName ?? (isApproved ? "Đã xếp" : "Chưa xếp")}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                            const Spacer(),
                            Icon(Icons.phone_outlined, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              s.phone ?? 'N/A',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Các nút hành động Quản trị
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Nút xóa sinh viên
                            IconButton(
                              tooltip: 'Xóa sinh viên',
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                              onPressed: () => _confirmDeleteStudent(s),
                            ),
                            const SizedBox(width: 4),

                            if (isPending) ...[
                              // Nút Từ chối
                              OutlinedButton(
                                onPressed: () {
                                  FirestoreService().updateStudentRoomStatus(s.id ?? 0, RoomStatus.rejected);
                                  setState(() {
                                    s.roomStatus = RoomStatus.rejected;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã từ chối đơn đăng ký của ${s.name}')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Từ chối'),
                              ),
                              const SizedBox(width: 8),

                              // Nút Duyệt phòng
                              ElevatedButton.icon(
                                onPressed: () {
                                  FirestoreService().updateStudentRoomStatus(s.id ?? 0, RoomStatus.approved);
                                  setState(() {
                                    s.roomStatus = RoomStatus.approved;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF059669),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Đã duyệt phòng cho sinh viên ${s.name}!'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check, size: 14),
                                label: const Text('Duyệt phòng'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ] else ...[
                              // Nút Xếp / Đổi phòng cho sinh viên
                              OutlinedButton.icon(
                                onPressed: () => _showAssignRoomDialog(s),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                                label: const Text('Xếp phòng'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: brandNavy,
                                  side: BorderSide(color: brandNavy),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // DIALOGS & ACTIONS
  // ===========================================================================

  // Chỉnh sửa thông tin cá nhân sinh viên
  void _showEditProfileDialog(User student) {
    final phoneCtrl = TextEditingController(text: student.phone ?? '');
    final hometownCtrl = TextEditingController(text: student.hometown ?? '');
    final classCtrl = TextEditingController(text: student.className ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chỉnh sửa thông tin cá nhân', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone, size: 18)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hometownCtrl,
              decoration: const InputDecoration(labelText: 'Quê quán / Địa chỉ', prefixIcon: Icon(Icons.home, size: 18)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: classCtrl,
              decoration: const InputDecoration(labelText: 'Lớp quản lý', prefixIcon: Icon(Icons.school, size: 18)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final newPhone = phoneCtrl.text.trim();
              final newHometown = hometownCtrl.text.trim();
              final newClass = classCtrl.text.trim();

              setState(() {
                student.phone = newPhone;
                student.hometown = newHometown;
                student.className = newClass;
              });

              FirestoreService().updateUserProfile(
                student.id ?? 6,
                phone: newPhone,
                hometown: newHometown,
                className: newClass,
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF059669),
                  content: Text('Đã cập nhật thông tin hồ sơ lên hệ thống!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: const Text('Lưu thông tin'),
          ),
        ],
      ),
    );
  }

  // Admin xếp phòng trực tiếp cho sinh viên
  void _showAssignRoomDialog(User student) {
    String selectedRoom = 'Phòng 101 - Tòa A';
    final rooms = ['Phòng 101 - Tòa A', 'Phòng 102 - Tòa A', 'Phòng 201 - Tòa A', 'Phòng B101 - Tòa B'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xếp phòng cho: ${student.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn phòng nội trú muốn phân bổ:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: rooms.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedRoom = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  student.pendingRoomName = selectedRoom;
                  student.roomStatus = RoomStatus.approved;
                });
                FirestoreService().updateStudentRoomStatus(student.id ?? 0, RoomStatus.approved, roomName: selectedRoom);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    content: Text('Đã xếp sinh viên ${student.name} vào $selectedRoom!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
              child: const Text('Xác nhận xếp phòng'),
            ),
          ],
        ),
      ),
    );
  }

  // Admin xác nhận xóa sinh viên
  void _confirmDeleteStudent(User s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa sinh viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản sinh viên ${s.name} (${s.mssv}) khỏi danh mục KTX không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _mockFallbackStudents.removeWhere((item) => item.id == s.id);
              });
              FirestoreService().deleteUser(s.id ?? 0);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa sinh viên ${s.name} khỏi hệ thống.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final bool isSelected = _filterStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = value),
      selectedColor: const Color(0xFF1E3A8A),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary)),
        ],
      ),
    );
  }
}
