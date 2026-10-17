
import 'base_entity.dart';

// Phân quyền người dùng
enum UserRole {
  student,
  admin
}

// Trạng thái đăng ký phòng
enum RoomStatus {
  none,
  pending,
  approved,
  rejected
}

// Generic Entity: User kế thừa BaseEntity<int?>
class User extends BaseEntity<int?> {

  // Các thuộc tính riêng của User
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

  // Constructor
  User({
    int? id,
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
  }) : super(
          id: id,
          name: fullName ?? username,
          description: 'Người dùng ký túc xá',
        );

  // Chuyển dữ liệu JSON từ Backend thành User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] == null
          ? null
          : int.tryParse(json['id'].toString()),

      username: json['username'] as String? ?? '',

      email: json['email'] as String? ?? '',

      role: json['role'] == 'admin'
          ? UserRole.admin
          : UserRole.student,

      fullName: json['full_name'] as String?,
      mssv: json['mssv'] as String?,
      phone: json['phone'] as String?,
      className: json['class_name'] as String?,
      hometown: json['hometown'] as String?,
      cccd: json['cccd'] as String?,

      gender: json['gender'] as String? ?? 'Nam',

      roomId: json['room_id'] == null
          ? null
          : int.tryParse(json['room_id'].toString()),

      roomStatus: parseRoomStatus(json['room_status']),

      pendingRoomId: json['pending_room_id'] == null
          ? null
          : int.tryParse(json['pending_room_id'].toString()),

      pendingRoomName: json['pending_room_name'] as String?,
    );
  }

  // Chuyển User thành JSON để gửi lên Backend
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,

      'username': username,

      if (password != null && password!.isNotEmpty)
        'password': password,

      'email': email,

      // Sửa lỗi enum.name trên Dart cũ
      'role': role.toString().split('.').last,

      'full_name': fullName,
      'mssv': mssv,
      'phone': phone,
      'class_name': className,
      'hometown': hometown,
      'cccd': cccd,
      'gender': gender,
      'room_id': roomId,

      // Sửa lỗi enum.name trên Dart cũ
      'room_status': roomStatus.toString().split('.').last,

      if (pendingRoomId != null)
        'pending_room_id': pendingRoomId,
    };
  }

  // Chuyển String thành RoomStatus
  static RoomStatus parseRoomStatus(dynamic status) {
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
  bool get isAdmin {
    return role == UserRole.admin;
  }

  // Kiểm tra sinh viên đã có phòng hay chưa
  bool get hasActiveRoom {
    return roomStatus == RoomStatus.approved &&
        roomId != null;
  }

  // Ghi đè phương thức kế thừa từ Generic BaseEntity
  @override
  String getInfo() {
    return '${super.getInfo()}\n'
        'Username: $username\n'
        'MSSV: ${mssv ?? "Chưa có"}\n'
        'Email: $email\n'
        'Lớp: ${className ?? "Chưa có"}\n'
        'Số điện thoại: ${phone ?? "Chưa có"}\n'
        'Giới tính: $gender\n'
        'Quê quán: ${hometown ?? "Chưa có"}\n'
        'Vai trò: ${isAdmin ? "Quản trị viên" : "Sinh viên"}\n'
        'Trạng thái phòng: ${getRoomStatus()}';
  }

  // Lấy trạng thái phòng bằng tiếng Việt
  String getRoomStatus() {
    switch (roomStatus) {
      case RoomStatus.approved:
        return 'Đã có phòng';

      case RoomStatus.pending:
        return 'Đang chờ duyệt';

      case RoomStatus.rejected:
        return 'Bị từ chối';

      default:
        return 'Chưa đăng ký phòng';
    }
  }

  // Cập nhật họ tên
  void updateFullName(String newName) {
    fullName = newName;
    name = newName;
  }

  // Cập nhật mô tả bằng phương thức kế thừa
  void updateUserDescription(String newDescription) {
    updateDescription(newDescription);
  }

  // Sử dụng Generic Method từ BaseEntity
  void showUserData<T>(T data) {
    displayData<T>(data);
  }
}
