enum UserRole { student, admin }
enum RoomStatus { none, pending, approved, rejected }

class User {
  final int? id;
  final String username;
  String? password;
  String email;
  UserRole role;
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
    this.id,
    required this.username,
    this.password,
    required this.email,
    this.role = UserRole.student,
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
  });

  // Chuyển đổi JSON nhận từ NestJS backend (GET api/users)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.student,
      fullName: json['full_name'] as String?,
      mssv: json['mssv'] as String?,
      phone: json['phone'] as String?,
      className: json['class_name'] as String?,
      hometown: json['hometown'] as String?,
      cccd: json['cccd'] as String?,
      gender: json['gender'] as String? ?? 'Nam',
      roomId: json['room_id'] != null ? int.tryParse(json['room_id'].toString()) : null,
      roomStatus: _parseRoomStatus(json['room_status']),
      pendingRoomId: json['pending_room_id'] != null ? int.tryParse(json['pending_room_id'].toString()) : null,
      pendingRoomName: json['pending_room_name'] as String?,
    );
  }

  // Chuyển đối tượng thành JSON để gửi lên Backend (POST/PUT api/users)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      if (password != null && password!.isNotEmpty) 'password': password,
      'email': email,
      'role': role.name,
      'full_name': fullName,
      'mssv': mssv,
      'phone': phone,
      'class_name': className,
      'hometown': hometown,
      'cccd': cccd,
      'gender': gender,
      'room_id': roomId,
      'room_status': roomStatus.name,
      if (pendingRoomId != null) 'pending_room_id': pendingRoomId,
    };
  }

  static RoomStatus _parseRoomStatus(String? status) {
    switch (status) {
      case 'approved':
        return RoomStatus.approved;
      case 'pending':
        return RoomStatus.pending;
      case 'rejected':
        return RoomStatus.rejected;
      default:
        return RoomStatus.none;
    }
  }

  // Kiểm tra quyền quản trị viên
  bool get isAdmin => role == UserRole.admin;

  // Kiểm tra trạng thái phòng
  bool get hasActiveRoom => roomStatus == RoomStatus.approved && roomId != null;
}