import 'base_entity.dart';

enum UserRole {
  student,
  admin,
  buildingManager,
}

enum ManagerStatus {
  pending,
  approved,
  rejected,
}

enum RoomStatus {
  none,
  pending,
  approved,
  rejected,
}

class User extends BaseEntity<int?> {
  final String username;

  // Giữ để tương thích mã cũ, không lưu mật khẩu vào Firestore.
  String? password;

  String email;
  UserRole role;

  ManagerStatus managerStatus;
  String? managedBuildingId;
  String? rulesVersion;

  String? fullName;
  String? mssv;
  String? phone;
  String? className;
  String? hometown;
  String? cccd;

  String gender;

  int? roomId;
  RoomStatus roomStatus;

  int? pendingRoomId;
  String? pendingRoomName;

  User({
    int? id,
    required this.username,
    required this.email,
    this.password,
    this.role = UserRole.student,
    this.managerStatus = ManagerStatus.pending,
    this.managedBuildingId,
    this.rulesVersion,
    this.fullName,
    this.mssv,
    this.phone,
    this.className,
    this.hometown,
    this.cccd,
    this.gender = 'Nam',
    this.roomId,
    this.roomStatus = RoomStatus.none,
    this.pendingRoomId,
    this.pendingRoomName,
  }) : super(
          id: id,
          name: fullName?.trim().isNotEmpty == true
              ? fullName!.trim()
              : username,
          description: 'Người dùng ký túc xá',
        );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role'] == 'admin'
          ? UserRole.admin
          : json['role'] == 'buildingManager'
              ? UserRole.buildingManager
              : UserRole.student,
      managerStatus: ManagerStatus.values.firstWhere(
        (value) => value.name == json['manager_status'],
        orElse: () => ManagerStatus.pending,
      ),
      managedBuildingId: json['managed_building_id']?.toString(),
      rulesVersion: json['rules_version']?.toString(),
      fullName: json['full_name']?.toString(),
      mssv: json['mssv']?.toString(),
      phone: json['phone']?.toString(),
      className: json['class_name']?.toString(),
      hometown: json['hometown']?.toString(),
      cccd: json['cccd']?.toString(),
      gender: json['gender']?.toString() ?? 'Nam',
      roomId: _parseInt(json['room_id']),
      roomStatus: parseRoomStatus(json['room_status']),
      pendingRoomId: _parseInt(json['pending_room_id']),
      pendingRoomName: json['pending_room_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'email': email,
      'role': role.name,
      'manager_status':
          role == UserRole.buildingManager ? managerStatus.name : null,
      'managed_building_id': managedBuildingId,
      'rules_version': rulesVersion,
      'full_name': fullName,
      'mssv': mssv,
      'phone': phone,
      'class_name': className,
      'hometown': hometown,
      'cccd': cccd,
      'gender': gender,
      'room_id': roomId,
      'room_status': roomStatus.name,
      'pending_room_id': pendingRoomId,
      'pending_room_name': pendingRoomName,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static RoomStatus parseRoomStatus(dynamic value) {
    switch (value?.toString()) {
      case 'pending':
        return RoomStatus.pending;
      case 'approved':
        return RoomStatus.approved;
      case 'rejected':
        return RoomStatus.rejected;
      default:
        return RoomStatus.none;
    }
  }

  bool get isAdmin => role == UserRole.admin;

  bool get isBuildingManager => role == UserRole.buildingManager;

  bool get canManageBuilding =>
      isBuildingManager &&
      managerStatus == ManagerStatus.approved &&
      managedBuildingId?.isNotEmpty == true;

  String get roleLabel => isAdmin
      ? 'Quản trị viên'
      : isBuildingManager
          ? 'Quản lý tòa'
          : 'Sinh viên';

  bool get hasActiveRoom =>
      roomStatus == RoomStatus.approved &&
      pendingRoomName?.trim().isNotEmpty == true;

  bool get hasPendingRoom => roomStatus == RoomStatus.pending;

  bool get canRegisterRoom =>
      role == UserRole.student &&
      (roomStatus == RoomStatus.none ||
          roomStatus == RoomStatus.rejected);

  String get displayName {
    final value = fullName?.trim() ?? '';
    return value.isNotEmpty ? value : username;
  }

  String getRoomStatus() {
    switch (roomStatus) {
      case RoomStatus.pending:
        return 'Đang chờ duyệt';
      case RoomStatus.approved:
        return 'Đã có phòng';
      case RoomStatus.rejected:
        return 'Bị từ chối';
      case RoomStatus.none:
        return 'Chưa đăng ký phòng';
    }
  }

  @override
  String getInfo() {
    return '${super.getInfo()}\n'
        'Tên đăng nhập: $username\n'
        'Họ tên: $displayName\n'
        'MSSV: ${mssv ?? "Chưa cập nhật"}\n'
        'Email: $email\n'
        'Lớp: ${className ?? "Chưa cập nhật"}\n'
        'Điện thoại: ${phone ?? "Chưa cập nhật"}\n'
        'Giới tính: $gender\n'
        'Quê quán: ${hometown ?? "Chưa cập nhật"}\n'
        'Vai trò: $roleLabel\n'
        'Trạng thái phòng: ${getRoomStatus()}';
  }

  void updateFullName(String newName) {
    fullName = newName.trim();
    name = fullName!.isEmpty ? username : fullName!;
  }

  void updateUserDescription(String newDescription) {
    updateDescription(newDescription);
  }

  void showUserData<T>(T data) {
    displayData<T>(data);
  }
}