import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

/// Màn hình Quản lý & Đăng ký Phòng KTX
/// - Phân quyền rõ rệt: Sinh viên (Xem & Đăng ký phòng) vs Admin (Toàn quyền CRUD: Thêm, Sửa, Xóa, Xếp chỗ)
/// - Đồng bộ trực tiếp với Firebase Firestore & CSDL quan_ly_ktx.sql
class RoomScreen extends StatefulWidget {
  const RoomScreen({Key? key}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String _selectedBuildingFilter = 'all'; // 'all', 'Tòa A', 'Tòa B'
  String _searchQuery = '';

  // Dữ liệu phòng mặc định từ quan_ly_ktx.sql làm fallback
  final List<Room> _fallbackRooms = [
    Room(
      id: 'room_A101',
      buildingId: 'Tòa A',
      name: '101',
      capacity: 4,
      currentOccupancy: 2,
      roomType: 'Thường',
      fixedPrice: 1500000,
    ),
    Room(
      id: 'room_A102',
      buildingId: 'Tòa A',
      name: '102',
      capacity: 4,
      currentOccupancy: 1,
      roomType: 'Thường',
      fixedPrice: 1500000,
    ),
    Room(
      id: 'room_A201',
      buildingId: 'Tòa A',
      name: '201',
      capacity: 6,
      currentOccupancy: 1,
      roomType: 'Dịch vụ VIP',
      fixedPrice: 2200000,
    ),
    Room(
      id: 'room_B101',
      buildingId: 'Tòa B',
      name: 'B101',
      capacity: 4,
      currentOccupancy: 2,
      roomType: 'Thường',
      fixedPrice: 1500000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color brandNavy = const Color(0xFF1E3A8A);
    final Color brandOrange = const Color(0xFFF97316);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final Color textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final bool isAdmin = AuthController.instance.isAdmin;
        final User currentUser = AuthController.instance.currentUser;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2F8),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            title: Text(
              isAdmin ? 'Quản lý Phòng KTX (Admin)' : 'Quản lý Phòng KTX',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'Thêm phòng mới',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: brandNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                  onPressed: () => _showAddRoomDialog(context, isDark, brandNavy, borderColor),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<Room>>(
            stream: FirestoreService().getRoomsStream(),
            builder: (context, snapshot) {
              List<Room> rooms = _fallbackRooms;
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                rooms = snapshot.data!;
              }

              // Lọc theo tòa nhà & tìm kiếm
              final filteredRooms = rooms.where((r) {
                final matchBuilding = _selectedBuildingFilter == 'all' || r.buildingId == _selectedBuildingFilter;
                final matchSearch = _searchQuery.isEmpty ||
                    r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    r.buildingId.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchBuilding && matchSearch;
              }).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Thẻ trạng thái phòng riêng của sinh viên
                    if (!isAdmin)
                      _buildStudentResidencyStatusCard(
                        currentUser,
                        isDark,
                        cardBg,
                        textPrimary,
                        textSecondary,
                        borderColor,
                        brandNavy,
                        brandOrange,
                      ),

                    // 2. Thẻ thống kê tổng quan của Admin (CRUD stats)
                    if (isAdmin)
                      _buildAdminRoomsSummary(
                        rooms,
                        isDark,
                        cardBg,
                        textPrimary,
                        textSecondary,
                        borderColor,
                        brandNavy,
                      ),

                    const SizedBox(height: 14),

                    // 3. Thanh tìm kiếm và bộ lọc tòa nhà
                    _buildFilterBar(isDark, cardBg, textPrimary, textSecondary, borderColor, brandNavy),

                    const SizedBox(height: 14),

                    // 4. Danh sách các phòng
                    if (filteredRooms.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'Không tìm thấy phòng phù hợp.',
                            style: TextStyle(color: textSecondary, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRooms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final room = filteredRooms[index];
                          return _buildRoomCard(
                            room: room,
                            isAdmin: isAdmin,
                            currentUser: currentUser,
                            isDark: isDark,
                            cardBg: cardBg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            borderColor: borderColor,
                            brandNavy: brandNavy,
                            brandOrange: brandOrange,
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. THẺ TÌNH TRẠNG CƯ TRÚ CỦA SINH VIÊN (Student Portal)
  // ===========================================================================
  Widget _buildStudentResidencyStatusCard(
    User user,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
    Color brandOrange,
  ) {
    final bool hasApprovedRoom = user.roomStatus == RoomStatus.approved && user.pendingRoomName != null;
    final bool isPending = user.roomStatus == RoomStatus.pending;

    Color statusColor = hasApprovedRoom
        ? const Color(0xFF059669)
        : (isPending ? brandOrange : const Color(0xFF64748B));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasApprovedRoom ? const Color(0xFFA7F3D0) : (isPending ? const Color(0xFFFED7AA) : borderColor),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasApprovedRoom
                      ? Icons.home_work_rounded
                      : (isPending ? Icons.hourglass_top_rounded : Icons.info_outline_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasApprovedRoom
                          ? 'Phòng đang cư trú: ${user.pendingRoomName}'
                          : (isPending
                              ? 'Đang chờ Admin duyệt: ${user.pendingRoomName ?? "Phòng KTX"}'
                              : 'Chưa đăng ký phòng nội trú'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasApprovedRoom
                          ? 'Hợp đồng cư trú có hiệu lực • Hạn 31/12/2026'
                          : (isPending
                              ? 'Hồ sơ đã gửi lên Ban Quản lý, vui lòng chờ duyệt.'
                              : 'Vui lòng chọn phòng còn trống bên dưới và bấm "Đăng ký".'),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. BỐN THỐNG KÊ NHANH CHO ADMIN (CRUD Overview)
  // ===========================================================================
  Widget _buildAdminRoomsSummary(
    List<Room> rooms,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
  ) {
    final int totalRooms = rooms.length;
    final int availableRooms = rooms.where((r) => r.hasAvailableBeds()).length;
    final int fullRooms = totalRooms - availableRooms;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatMini('TỔNG SỐ PHÒNG', '$totalRooms', const Color(0xFF2563EB), textSecondary),
          Container(width: 1, height: 32, color: borderColor),
          _buildStatMini('CÒN CHỖ TRỐNG', '$availableRooms', const Color(0xFF059669), textSecondary),
          Container(width: 1, height: 32, color: borderColor),
          _buildStatMini('ĐÃ ĐẦY CHỖ', '$fullRooms', const Color(0xFFDC2626), textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatMini(String title, String value, Color color, Color textSecondary) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textSecondary)),
      ],
    );
  }

  // ===========================================================================
  // 3. BỘ LỌC TÒA NHÀ & TÌM KIẾM
  // ===========================================================================
  Widget _buildFilterBar(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    Color brandNavy,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 13, color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo số phòng, tòa...',
                      hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildChipFilter('Tất cả', 'all', brandNavy, isDark),
        const SizedBox(width: 4),
        _buildChipFilter('Tòa A', 'Tòa A', brandNavy, isDark),
        const SizedBox(width: 4),
        _buildChipFilter('Tòa B', 'Tòa B', brandNavy, isDark),
      ],
    );
  }

  Widget _buildChipFilter(String label, String value, Color brandNavy, bool isDark) {
    final bool isSelected = _selectedBuildingFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedBuildingFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandNavy : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? brandNavy : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. THẺ PHÒNG CHI TIẾT (Phân quyền Sinh viên vs Admin CRUD)
  // ===========================================================================
  Widget _buildRoomCard({
    required Room room,
    required bool isAdmin,
    required User currentUser,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color brandNavy,
    required Color brandOrange,
  }) {
    final double ratio = room.capacity > 0 ? (room.currentOccupancy / room.capacity) : 0;
    final int percent = (ratio * 100).toInt();
    final bool isFull = !room.hasAvailableBeds();

    // Kiểm tra xem sinh viên có đang ở phòng này hoặc đang chờ duyệt không
    final bool isApprovedInThisRoom = !isAdmin &&
        currentUser.roomStatus == RoomStatus.approved &&
        currentUser.pendingRoomName != null &&
        (currentUser.pendingRoomName!.toLowerCase().contains(room.name.toLowerCase()) ||
            room.name.toLowerCase().contains(currentUser.pendingRoomName!.toLowerCase()));

    final bool isPendingInThisRoom = !isAdmin &&
        currentUser.roomStatus == RoomStatus.pending &&
        currentUser.pendingRoomName != null &&
        (currentUser.pendingRoomName!.toLowerCase().contains(room.name.toLowerCase()) ||
            room.name.toLowerCase().contains(currentUser.pendingRoomName!.toLowerCase()));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApprovedInThisRoom
              ? const Color(0xFF10B981)
              : (isPendingInThisRoom ? const Color(0xFFF59E0B) : borderColor),
          width: (isApprovedInThisRoom || isPendingInThisRoom) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề phòng + Badge còn chỗ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.apartment_rounded, color: brandNavy, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${room.name} - ${room.buildingId}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${room.fixedPrice.toInt()} đ / tháng • ${room.roomType}',
                      style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFull ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Text(
                  isFull ? 'HẾT CHỖ' : '${room.availableBeds}/${room.capacity} CÒN CHỖ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isFull ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Thanh tiến trình sĩ số
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sĩ số hiện tại: ${room.currentOccupancy}/${room.capacity} người',
                style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isFull ? const Color(0xFFDC2626) : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? const Color(0xFFDC2626) : const Color(0xFF10B981),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ===================================================================
          // PHÂN QUYỀN HÀNH ĐỘNG
          // ===================================================================
          if (!isAdmin)
            // Giao diện Sinh viên: Đăng ký phòng
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isApprovedInThisRoom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                        SizedBox(width: 4),
                        Text('Phòng của bạn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                      ],
                    ),
                  )
                else if (isPendingInThisRoom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 14),
                        SizedBox(width: 4),
                        Text('Đang chờ duyệt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                      ],
                    ),
                  )
                else if (isFull)
                  OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Phòng đã đầy', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _handleStudentRegisterRoom(context, room, currentUser),
                    icon: const Icon(Icons.app_registration_rounded, size: 16),
                    label: const Text('Đăng ký phòng này', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            )
          else
            // Giao diện Admin: Đầy đủ CRUD (Sửa, Xóa, Bớt SV, Xếp chỗ)
            Row(
              children: [
                // Nút Sửa thông tin phòng
                IconButton(
                  tooltip: 'Sửa thông tin phòng',
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                  onPressed: () => _showEditRoomDialog(context, room, isDark, brandNavy, borderColor),
                ),
                // Nút Xóa phòng
                IconButton(
                  tooltip: 'Xóa phòng',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                  onPressed: () => _confirmDeleteRoom(context, room),
                ),
                const Spacer(),
                // Nút Bớt SV (-)
                OutlinedButton.icon(
                  onPressed: () {
                    if (room.removeOccupant()) {
                      setState(() {});
                      FirestoreService().updateRoomOccupancy(room.name, room.currentOccupancy);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phòng hiện đang trống!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.remove, size: 14),
                  label: const Text('Bớt SV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút Xếp chỗ (+)
                ElevatedButton.icon(
                  onPressed: () {
                    if (room.addOccupant()) {
                      setState(() {});
                      FirestoreService().updateRoomOccupancy(room.name, room.currentOccupancy);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phòng đã đạt tối đa sức chứa!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Xếp chỗ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. CÁC HỘP THOẠI CRUD DÀNH CHO ADMIN & SINH VIÊN
  // ===========================================================================

  // Sinh viên gửi yêu cầu đăng ký phòng
  void _handleStudentRegisterRoom(BuildContext context, Room room, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.app_registration_rounded, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Đăng ký phòng KTX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn gửi đơn xin đăng ký cư trú tại Phòng ${room.name} - ${room.buildingId} (Giá thuê: ${room.fixedPrice.toInt()} đ/tháng)?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().requestRoomRegistration(user.id ?? 6, 'Phòng ${room.name}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF059669),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Đã gửi yêu cầu đăng ký Phòng ${room.name} thành công!'),
                    ],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
            child: const Text('Xác nhận đăng ký'),
          ),
        ],
      ),
    );
  }

  // Admin thêm phòng mới (CRUD - Create)
  void _showAddRoomDialog(BuildContext context, bool isDark, Color brandNavy, Color borderColor) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '1500000');
    String selectedBuilding = 'Tòa A';
    int selectedCapacity = 4;
    String selectedType = 'Thường';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Thêm phòng KTX mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên/Số phòng (Ví dụ: 103, 202)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedBuilding,
                  decoration: const InputDecoration(labelText: 'Tòa nhà'),
                  items: const [
                    DropdownMenuItem(value: 'Tòa A', child: Text('Tòa A (Nam)')),
                    DropdownMenuItem(value: 'Tòa B', child: Text('Tòa B (Nữ)')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedBuilding = val ?? 'Tòa A'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: selectedCapacity,
                  decoration: const InputDecoration(labelText: 'Sức chứa tối đa'),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text('4 Giường')),
                    DropdownMenuItem(value: 6, child: Text('6 Giường')),
                    DropdownMenuItem(value: 8, child: Text('8 Giường')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedCapacity = val ?? 4),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loại phòng'),
                  items: const [
                    DropdownMenuItem(value: 'Thường', child: Text('Thường')),
                    DropdownMenuItem(value: 'Dịch vụ VIP', child: Text('Dịch vụ VIP')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedType = val ?? 'Thường'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá tiền thuê (VNĐ/tháng)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final newRoom = Room(
                  buildingId: selectedBuilding,
                  name: nameCtrl.text.trim(),
                  capacity: selectedCapacity,
                  roomType: selectedType,
                  fixedPrice: double.tryParse(priceCtrl.text.trim()) ?? 1500000,
                  currentOccupancy: 0,
                );
                await FirestoreService().addRoom(newRoom);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    content: Text('Đã thêm thành công Phòng ${newRoom.name} - ${newRoom.buildingId}!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: brandNavy, foregroundColor: Colors.white),
              child: const Text('Lưu phòng'),
            ),
          ],
        ),
      ),
    );
  }

  // Admin sửa phòng (CRUD - Update)
  void _showEditRoomDialog(BuildContext context, Room room, bool isDark, Color brandNavy, Color borderColor) {
    final priceCtrl = TextEditingController(text: room.fixedPrice.toInt().toString());
    int selectedCapacity = room.capacity;
    String selectedType = room.roomType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Sửa Phòng ${room.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCapacity,
                  decoration: const InputDecoration(labelText: 'Sức chứa tối đa'),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text('4 Giường')),
                    DropdownMenuItem(value: 6, child: Text('6 Giường')),
                    DropdownMenuItem(value: 8, child: Text('8 Giường')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedCapacity = val ?? 4),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Loại phòng'),
                  items: const [
                    DropdownMenuItem(value: 'Thường', child: Text('Thường')),
                    DropdownMenuItem(value: 'Dịch vụ VIP', child: Text('Dịch vụ VIP')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedType = val ?? 'Thường'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá tiền thuê (VNĐ/tháng)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                room.capacity = selectedCapacity;
                room.roomType = selectedType;
                room.fixedPrice = double.tryParse(priceCtrl.text.trim()) ?? room.fixedPrice;

                final docId = room.id ?? 'room_${room.buildingId}_${room.name}'.replaceAll(' ', '_');
                await FirestoreService().updateRoom(docId, room);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF059669),
                    content: Text('Đã cập nhật thông tin Phòng ${room.name}!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: brandNavy, foregroundColor: Colors.white),
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  // Admin xóa phòng (CRUD - Delete)
  void _confirmDeleteRoom(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa phòng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
        content: Text('Bạn có chắc chắn muốn xóa Phòng ${room.name} (${room.buildingId}) khỏi hệ thống? Dữ liệu không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final docId = room.id ?? 'room_${room.buildingId}_${room.name}'.replaceAll(' ', '_');
              await FirestoreService().deleteRoom(docId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFDC2626),
                  content: Text('Đã xóa Phòng ${room.name} khỏi hệ thống!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }
}
