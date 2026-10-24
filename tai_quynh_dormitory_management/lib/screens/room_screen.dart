
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final FirestoreService _service = FirestoreService();

  String _selectedBuildingFilter = 'all';
  String _searchQuery = '';

  static const Color navy = Color(0xFF1E3A8A);
  static const Color green = Color(0xFF059669);
  static const Color orange = Color(0xFFF97316);
  static const Color red = Color(0xFFDC2626);

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? red : green,
        content: Text(message),
      ),
    );
  }

  // ==========================================
  // KIỂM TRA PHÒNG CỦA SINH VIÊN
  // ==========================================

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('phòng', '')
        .replaceAll('tòa', '')
        .replaceAll(RegExp(r'[\s\-_]'), '');
  }

  bool _isStudentRoom(Room room, User user) {
    final roomName =
        user.pendingRoomName?.trim() ?? '';

    if (roomName.isEmpty) {
      return false;
    }

    final registered = _normalize(roomName);
    final name = _normalize(room.name);
    final building = _normalize(room.buildingId);

    // Ưu tiên so sánh cả tên phòng và tòa nhà.
    if (registered == '$name$building' ||
        registered == '$building$name') {
      return true;
    }

    // Hỗ trợ dữ liệu cũ chỉ lưu "Phòng 101".
    // Chỉ chấp nhận nếu tên phòng thực sự giống nhau.
    return registered == name;
  }

  bool _hasRegisteredRoom(User user) {
    return user.roomStatus == RoomStatus.pending ||
        user.roomStatus == RoomStatus.approved;
  }

  List<Room> _getVisibleRooms(
    List<Room> rooms,
    User user,
    bool isAdmin,
  ) {
    // Admin được xem tất cả phòng.
    if (isAdmin) {
      return _filterRooms(rooms);
    }

    // Sinh viên đã đăng ký hoặc đang cư trú:
    // Chỉ được xem phòng liên quan.
    if (_hasRegisteredRoom(user)) {
      return rooms.where((room) {
        return _isStudentRoom(room, user);
      }).toList();
    }

    // Sinh viên chưa đăng ký hoặc đã bị từ chối.
    return _filterRooms(rooms);
  }

  List<Room> _filterRooms(List<Room> rooms) {
    return rooms.where((room) {
      final matchBuilding =
          _selectedBuildingFilter == 'all' ||
          room.buildingId == _selectedBuildingFilter;

      final keyword = _searchQuery.trim().toLowerCase();

      final matchSearch = keyword.isEmpty ||
          room.name.toLowerCase().contains(keyword) ||
          room.buildingId.toLowerCase().contains(keyword);

      return matchBuilding && matchSearch;
    }).toList();
  }

  // ==========================================
  // MÀN HÌNH CHÍNH
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final background =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2F8);

    final cardColor =
        isDark ? const Color(0xFF1E293B) : Colors.white;

    final primaryText =
        isDark ? Colors.white : const Color(0xFF1E293B);

    final secondaryText =
        isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B);

    return AnimatedBuilder(
      animation: AuthController.instance,
      builder: (context, _) {
        final auth = AuthController.instance;
        final isAdmin = auth.isAdmin;
        final currentUser = auth.currentUser;

        final hasRegistered =
            !isAdmin && _hasRegisteredRoom(currentUser);

        return Scaffold(
          backgroundColor: background,

          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            title: Text(
              isAdmin
                  ? 'Quản lý Phòng KTX (Admin)'
                  : 'Quản lý Phòng KTX',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  tooltip: 'Thêm phòng',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showRoomDialog(),
                ),
            ],
          ),

          body: StreamBuilder<List<Room>>(
            stream: _service.getRoomsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Không thể tải phòng: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final allRooms = snapshot.data!;

              final visibleRooms = _getVisibleRooms(
                allRooms,
                currentUser,
                isAdmin,
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Trạng thái cư trú của sinh viên.
                  if (!isAdmin) ...[
                    _buildResidencyCard(
                      currentUser,
                      cardColor,
                      primaryText,
                      secondaryText,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Admin: thống kê toàn bộ phòng.
                  if (isAdmin) ...[
                    _buildAdminSummary(
                      allRooms,
                      cardColor,
                      primaryText,
                      secondaryText,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Chỉ hiển thị tìm kiếm khi được xem danh sách.
                  if (!hasRegistered) ...[
                    _buildSearchBar(cardColor),
                    const SizedBox(height: 12),
                    _buildBuildingFilters(),
                    const SizedBox(height: 18),
                  ],

                  Text(
                    hasRegistered
                        ? 'Phòng của bạn'
                        : isAdmin
                            ? 'Danh sách tất cả phòng'
                            : 'Danh sách phòng ký túc xá',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (visibleRooms.isEmpty)
                    _buildEmptyState(
                      hasRegistered
                          ? 'Không tìm thấy thông tin phòng đã đăng ký. Vui lòng liên hệ ban quản lý.'
                          : 'Chưa có phòng phù hợp.',
                      cardColor,
                      secondaryText,
                    )
                  else
                    ...visibleRooms.map(
                      (room) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildRoomCard(
                          room,
                          currentUser,
                          isAdmin,
                          isDark,
                          cardColor,
                          primaryText,
                          secondaryText,
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // TRẠNG THÁI CƯ TRÚ
  // ==========================================

  Widget _buildResidencyCard(
    User user,
    Color cardColor,
    Color primaryText,
    Color secondaryText,
  ) {
    final approved =
        user.roomStatus == RoomStatus.approved;

    final pending =
        user.roomStatus == RoomStatus.pending;

    final rejected =
        user.roomStatus == RoomStatus.rejected;

    final Color statusColor = approved
        ? green
        : pending
            ? orange
            : rejected
                ? red
                : const Color(0xFF64748B);

    String title;
    String description;

    if (approved) {
      title =
          'Phòng đang cư trú: ${user.pendingRoomName ?? "Chưa xác định"}';
      description = 'Trạng thái: Đã được duyệt cư trú';
    } else if (pending) {
      title =
          'Đang chờ duyệt: ${user.pendingRoomName ?? "Phòng KTX"}';
      description =
          'Yêu cầu đã gửi đến ban quản lý ký túc xá.';
    } else if (rejected) {
      title = 'Yêu cầu đăng ký bị từ chối';
      description = 'Bạn có thể lựa chọn phòng khác.';
    } else {
      title = 'Chưa đăng ký phòng nội trú';
      description =
          'Hãy lựa chọn một phòng còn chỗ để đăng ký.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                statusColor.withValues(alpha: 0.12),
            child: Icon(
              approved
                  ? Icons.home_work_rounded
                  : pending
                      ? Icons.hourglass_top_rounded
                      : Icons.info_outline,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // THỐNG KÊ ADMIN
  // ==========================================

  Widget _buildAdminSummary(
    List<Room> rooms,
    Color cardColor,
    Color primaryText,
    Color secondaryText,
  ) {
    final total = rooms.length;

    final available =
        rooms.where((room) => room.hasAvailableBeds()).length;

    final full = total - available;

    final totalCapacity = rooms.fold<int>(
      0,
      (sum, room) => sum + room.capacity,
    );

    final totalOccupancy = rooms.fold<int>(
      0,
      (sum, room) => sum + room.currentOccupancy,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan phòng KTX',
            style: TextStyle(
              color: primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _statItem('Tổng phòng', '$total', navy),
              _statItem('Còn chỗ', '$available', green),
              _statItem('Đã đầy', '$full', red),
              _statItem(
                'Tổng sĩ số',
                '$totalOccupancy/$totalCapacity',
                orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      width: 135,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TÌM KIẾM VÀ LỌC
  // ==========================================

  Widget _buildSearchBar(Color cardColor) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Tìm theo số phòng, tòa nhà...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBuildingFilters() {
    return Wrap(
      spacing: 8,
      children: [
        _filterChip('Tất cả', 'all'),
        _filterChip('Tòa A', 'Tòa A'),
        _filterChip('Tòa B', 'Tòa B'),
      ],
    );
  }

  Widget _filterChip(String title, String value) {
    final selected = _selectedBuildingFilter == value;

    return ChoiceChip(
      label: Text(title),
      selected: selected,
      selectedColor: navy.withValues(alpha: 0.15),
      onSelected: (_) {
        setState(() {
          _selectedBuildingFilter = value;
        });
      },
    );
  }

  // ==========================================
  // DANH SÁCH PHÒNG
  // ==========================================

  Widget _buildRoomCard(
    Room room,
    User user,
    bool isAdmin,
    bool isDark,
    Color cardColor,
    Color primaryText,
    Color secondaryText,
  ) {
    final ratio = room.capacity > 0
        ? (room.currentOccupancy / room.capacity)
            .clamp(0.0, 1.0)
        : 0.0;

    final percent = (ratio * 100).round();

    final isFull = !room.hasAvailableBeds();

    final isOwnRoom =
        !isAdmin && _isStudentRoom(room, user);

    final approved =
        isOwnRoom && user.roomStatus == RoomStatus.approved;

    final pending =
        isOwnRoom && user.roomStatus == RoomStatus.pending;

    final highlight = approved
        ? green
        : pending
            ? orange
            : Colors.transparent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight == Colors.transparent
              ? (isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0))
              : highlight,
          width: approved || pending ? 1.5 : 1,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${room.name} - ${room.buildingId}',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.fixedPrice.toStringAsFixed(0)} đ/tháng • ${room.roomType}',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  isFull
                      ? 'HẾT CHỖ'
                      : '${room.availableBeds}/${room.capacity} CÒN CHỖ',
                  style: TextStyle(
                    color: isFull ? red : green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: isFull
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sĩ số hiện tại: ${room.currentOccupancy}/${room.capacity} người',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: isFull ? red : green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                isFull ? red : const Color(0xFF10B981),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (isAdmin)
            _buildAdminActions(room)
          else if (approved)
            _statusButton(
              'Phòng của bạn',
              Icons.check_circle,
              green,
            )
          else if (pending)
            _statusButton(
              'Đang chờ duyệt',
              Icons.hourglass_top,
              orange,
            )
          else if (isFull)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: null,
                child: const Text('Phòng đã đầy'),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _registerRoom(room, user),
                icon: const Icon(Icons.app_registration),
                label: const Text('Đăng ký phòng này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusButton(
    String title,
    IconData icon,
    Color color,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ĐĂNG KÝ PHÒNG
  // ==========================================

  Future<void> _registerRoom(Room room, User user) async {
    if (_hasRegisteredRoom(user)) {
      _showMessage(
        'Bạn đã đăng ký hoặc đang cư trú ở một phòng khác.',
        error: true,
      );
      return;
    }

    if (user.id == null) {
      _showMessage(
        'Không tìm thấy mã sinh viên. Vui lòng đăng nhập lại.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận đăng ký phòng'),
        content: Text(
          'Bạn có muốn đăng ký Phòng ${room.name} - ${room.buildingId}?\n\n'
          'Giá: ${room.fixedPrice.toStringAsFixed(0)} đ/tháng\n'
          'Chỗ trống: ${room.availableBeds}',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Lưu tên phòng kèm tòa để phân biệt.
      final selectedRoom =
          'Phòng ${room.name} - ${room.buildingId}';

      await _service.requestRoomRegistration(
        user.id!,
        selectedRoom,
      );

      _showMessage(
        'Đã gửi yêu cầu đăng ký phòng ${room.name}.',
      );
    } catch (error) {
      _showMessage(
        'Không thể đăng ký phòng: $error',
        error: true,
      );
    }
  }

  // ==========================================
  // ADMIN - CÁC NÚT QUẢN LÝ
  // ==========================================

  Widget _buildAdminActions(Room room) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showRoomDialog(room: room),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa'),
        ),
        OutlinedButton.icon(
          onPressed: () => _deleteRoom(room),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Xóa'),
        ),
        OutlinedButton.icon(
          onPressed: room.currentOccupancy > 0
              ? () => _updateOccupancy(room, -1)
              : null,
          icon: const Icon(Icons.remove),
          label: const Text('Bớt SV'),
        ),
        FilledButton.icon(
          onPressed: room.hasAvailableBeds()
              ? () => _updateOccupancy(room, 1)
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Xếp chỗ'),
        ),
      ],
    );
  }

  Future<void> _updateOccupancy(
    Room room,
    int change,
  ) async {
    final newOccupancy =
        room.currentOccupancy + change;

    if (newOccupancy < 0 ||
        newOccupancy > room.capacity) {
      _showMessage('Sĩ số không hợp lệ.', error: true);
      return;
    }

    try {
      await _service.updateRoomOccupancy(
        room.name,
        newOccupancy,
      );

      _showMessage('Đã cập nhật sĩ số phòng.');
    } catch (error) {
      _showMessage(
        'Không thể cập nhật sĩ số: $error',
        error: true,
      );
    }
  }

  // ==========================================
  // ADMIN - THÊM / SỬA PHÒNG
  // ==========================================

  Future<void> _showRoomDialog({Room? room}) async {
    final nameCtrl =
        TextEditingController(text: room?.name ?? '');

    final priceCtrl = TextEditingController(
      text: room?.fixedPrice.toStringAsFixed(0) ?? '',
    );

    String building = room?.buildingId ?? 'Tòa A';
    String roomType = room?.roomType ?? 'Thường';
    int capacity = room?.capacity ?? 4;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              room == null
                  ? 'Thêm phòng KTX'
                  : 'Sửa phòng ${room.name}',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    enabled: room == null,
                    decoration: const InputDecoration(
                      labelText: 'Tên phòng',
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: building,
                    decoration: const InputDecoration(
                      labelText: 'Tòa nhà',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tòa A',
                        child: Text('Tòa A'),
                      ),
                      DropdownMenuItem(
                        value: 'Tòa B',
                        child: Text('Tòa B'),
                      ),
                    ],
                    onChanged: room != null
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() {
                                building = value;
                              });
                            }
                          },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    initialValue: capacity,
                    decoration: const InputDecoration(
                      labelText: 'Sức chứa',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 4,
                        child: Text('4 người'),
                      ),
                      DropdownMenuItem(
                        value: 6,
                        child: Text('6 người'),
                      ),
                      DropdownMenuItem(
                        value: 8,
                        child: Text('8 người'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          capacity = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: roomType,
                    decoration: const InputDecoration(
                      labelText: 'Loại phòng',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Thường',
                        child: Text('Thường'),
                      ),
                      DropdownMenuItem(
                        value: 'Dịch vụ VIP',
                        child: Text('Dịch vụ VIP'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          roomType = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá phòng (VNĐ/tháng)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price =
                      double.tryParse(priceCtrl.text.trim());

                  if (name.isEmpty ||
                      price == null ||
                      price < 0) {
                    _showMessage(
                      'Vui lòng nhập thông tin hợp lệ.',
                      error: true,
                    );
                    return;
                  }

                  if (room != null &&
                      capacity < room.currentOccupancy) {
                    _showMessage(
                      'Sức chứa không thể nhỏ hơn sĩ số.',
                      error: true,
                    );
                    return;
                  }

                  try {
                    if (room == null) {
                      final newRoom = Room(
                        buildingId: building,
                        name: name,
                        capacity: capacity,
                        currentOccupancy: 0,
                        roomType: roomType,
                        fixedPrice: price,
                      );

                      await _service.addRoom(newRoom);
                    } else {
                      final updatedRoom = Room(
                        id: room.id,
                        buildingId: room.buildingId,
                        name: room.name,
                        capacity: capacity,
                        currentOccupancy:
                            room.currentOccupancy,
                        roomType: roomType,
                        fixedPrice: price,
                      );

                      await _service.updateRoom(
                        room.id!,
                        updatedRoom,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    _showMessage('Lưu thông tin phòng thành công.');
                  } catch (error) {
                    _showMessage(
                      'Không thể lưu phòng: $error',
                      error: true,
                    );
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
  }

  // ==========================================
  // ADMIN - XÓA PHÒNG
  // ==========================================

  Future<void> _deleteRoom(Room room) async {
    if (room.id == null) {
      _showMessage('Không tìm thấy mã phòng.', error: true);
      return;
    }

    if (room.currentOccupancy > 0) {
      _showMessage(
        'Phòng đang có sinh viên, không thể xóa.',
        error: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa phòng'),
        content: Text(
          'Bạn chắc chắn muốn xóa phòng ${room.name} - ${room.buildingId}?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteRoom(room.id!);
      _showMessage('Đã xóa phòng thành công.');
    } catch (error) {
      _showMessage(
        'Không thể xóa phòng: $error',
        error: true,
      );
    }
  }

  // ==========================================
  // TRẠNG THÁI KHÔNG CÓ PHÒNG
  // ==========================================

  Widget _buildEmptyState(
    String message,
    Color cardColor,
    Color secondaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 44,
            color: secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryText),
          ),
        ],
      ),
    );
  }
}
