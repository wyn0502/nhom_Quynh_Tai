
## 1. Giới thiệu tổng quan đối tượng

Trong hệ thống quản lý ký túc xá, đối tượng **`User`** đóng vai trò hạt nhân, đại diện cho người dùng đăng nhập vào ứng dụng di động gồm 2 phân quyền chính:
* **Sinh viên (`student`):** Đăng ký tài khoản, xem/cập nhật hồ sơ cá nhân, nộp hồ sơ xin phòng ký túc xá và theo dõi trạng thái duyệt phòng.
* **Quản trị viên (`admin`):** Quản lý hồ sơ toàn bộ sinh viên, tiếp nhận và tiến hành xét duyệt (`approve`) hoặc từ chối (`reject`) yêu cầu thuê phòng.

Đối tượng `User` được chuẩn hóa bằng ngôn ngữ **Dart**, kế thừa và đồng bộ các ràng buộc dữ liệu từ dịch vụ Backend (`UsersService`, TypeORM, PostgreSQL/MySQL).

---

## 2. Đặc tả chi tiết lớp (Class Specification)

### 2.1. Danh sách thuộc tính (Attributes)

| Tên thuộc tính | Kiểu dữ liệu (Dart) | Kiểu dữ liệu (Backend DTO) | Mô tả chi tiết |
| :--- | :--- | :--- | :--- |
| `id` | `int?` | `number` | ID định danh duy nhất (Khóa chính tự tăng trên DB). |
| `username` | `String` | `string` | Tên đăng nhập hệ thống (Duy nhất, bắt buộc). |
| `password` | `String?` | `string` | Mật khẩu (Client gửi lên để băm Bcrypt, DB ẩn khi trả về). |
| `email` | `String` | `string` | Địa chỉ email người dùng (Duy nhất, bắt buộc). |
| `role` | `UserRole` | `'student' \| 'admin'` | Phân quyền: `student` (mặc định) hoặc `admin`. |
| `fullName` | `String?` | `string (full_name)` | Họ và tên đầy đủ. |
| `mssv` | `String?` | `string (mssv)` | Mã số sinh viên (Duy nhất trên toàn hệ thống). |
| `phone` | `String?` | `string (phone)` | Số điện thoại liên lạc. |
| `className` | `String?` | `string (class_name)`| Lớp sinh hoạt chuyên ngành tại trường. |
| `hometown` | `String?` | `string (hometown)` | Quê quán / Địa chỉ thường trú. |
| `cccd` | `String?` | `string (cccd)` | Căn cước công dân (Duy nhất, dùng đối soát hồ sơ). |
| `gender` | `String` | `string (gender)` | Giới tính (Giá trị: 'Nam' hoặc 'Nữ'). |
| `roomId` | `int?` | `number (room_id)` | ID phòng đã được duyệt ở chính thức. |
| `roomStatus` | `RoomStatus` | `string (room_status)` | Trạng thái phòng: `none`, `pending`, `approved`, `rejected`. |
| `pendingRoomId`| `int?` | `number (pending_room_id)` | ID phòng sinh viên gửi yêu cầu đăng ký đang chờ duyệt. |
| `pendingRoomName`| `String?` | `string` | Tên phòng đang chờ duyệt (hiển thị giao diện di động). |

---

### 2.2. Danh sách phương thức (Methods)

* **`User(...)`**: Hàm khởi tạo (Constructor) với các giá trị mặc định (`gender = 'Nam'`, `roomStatus = RoomStatus.none`, `role = UserRole.student`).
* **`factory User.fromJson(Map<String, dynamic> json)`**: Phân tích cú pháp chuỗi JSON từ API Backend (`GET /api/users`, `GET /api/users/pending-rooms`) thành thực thể `User` trên Flutter.
* **`Map<String, dynamic> toJson()`**: Đóng gói đối tượng `User` thành định dạng JSON chuẩn `snake_case` gửi qua HTTP request (`POST /api/users`, `PUT /api/users/:id`).
* **`bool get isAdmin`**: Getter kiểm tra nhanh quyền Admin của phiên đăng nhập hiện tại.
* **`bool get hasActiveRoom`**: Getter kiểm tra sinh viên đã có phòng hợp lệ hay chưa (`roomStatus == RoomStatus.approved && roomId != null`).

---

## 3. Mã nguồn triển khai (Dart Source Code)

File được đặt tại đường dẫn: `lib/models/user.dart`

```dart
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

  // Chuyển đổi JSON từ API Backend sang Object User
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
      roomStatus: _parseRoomStatus(json['room_status'] as String?),
      pendingRoomId: json['pending_room_id'] != null 
          ? int.tryParse(json['pending_room_id'].toString()) 
          : null,
      pendingRoomName: json['pending_room_name'] as String?,
    );
  }

  // Chuyển đổi Object User sang JSON để gửi Request lên Backend
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

  // Tiện ích logic nghiệp vụ
  bool get isAdmin => role == UserRole.admin;
  bool get hasActiveRoom => roomStatus == RoomStatus.approved && roomId != null;
}
```

---

## 4. Sơ đồ thiết kế hệ thống (UML Diagrams)

### 4.1. Sơ đồ lớp (Class Diagram)

Mối quan hệ giữa thực thể `User` và phòng ký túc xá `Room`:

```
+-------------------------------------------------------------+
|                            User                             |
+-------------------------------------------------------------+
| + id: INT                                                   |
| + username: STRING                                          |
| - password: STRING                                          |
| + email: STRING                                             |
| + role: UserRole {student, admin}                           |
| + fullName: STRING                                          |
| + mssv: STRING                                              |
| + phone: STRING                                             |
| + className: STRING                                         |
| + hometown: STRING                                          |
| + cccd: STRING                                              |
| + gender: STRING                                            |
| + roomId: INT                                               |
| + roomStatus: RoomStatus {none, pending, approved, rejected}|
| + pendingRoomId: INT                                        |
| + pendingRoomName: STRING                                   |
+-------------------------------------------------------------+
| + fromJson(json: MAP): User                                 |
| + toJson(): MAP                                             |
| + isAdmin(): BOOLEAN                                        |
| + hasActiveRoom(): BOOLEAN                                  |
+-------------------------------------------------------------+
                            | 0..*
                            |
                     stays in / pending
                            |
                            v 0..1
+-------------------------------------------------------------+
|                            Room                             |
+-------------------------------------------------------------+
| + id: INT                                                   |
| + roomName: STRING                                          |
| + capacity: INT                                             |
| + currentOccupancy: INT                                     |
+-------------------------------------------------------------+
```

---

### 4.2. Sơ đồ trình tự thuật toán (Sequence Diagram)

Mô tả thuật toán xử lý luồng **Đăng ký tài khoản & Giữ chỗ phòng** (`POST /api/auth/register`) tương thích với kiến trúc NestJS/TypeORM:

```
Client             AuthController            AuthService             UserRepo                RoomRepo
  |                      |                        |                      |                      |
  |-- POST /register --->|                        |                      |                      |
  |   (Data + room_id)   |-- register(dto) ------>|                      |                      |
  |                      |                        |-- findOne(dup_data)->|                      |
  |                      |                        |<-- check kết quả ----|                      |
  |                      |                        |                      |                      |
  |                      |<-- [409 Conflict] -----| (Nếu trùng lặp User)                        |
  |<-- 409 Báo lỗi trùng |                        |                      |                      |
  |                      |                        |-- findOne(room_id) ------------------------>|
  |                      |                        |<-- room details (capacity, occupancy) ------|
  |                      |                        |                      |                      |
  |                      |<-- [409 Conflict] -----| (Nếu occupancy >= capacity)                 |
  |<-- 409 Phòng đầy ----|                        |                      |                      |
  |                      |                        |-- [Băm mật khẩu Bcrypt]                     |
  |                      |                        |-- save(newUser) ---->|                      |
  |                      |                        |<-- Entity đã lưu ----|                      |
  |                      |                        |-- save(occupancy + 1) --------------------->|
  |                      |                        |<-- Cập nhật xong ---------------------------|
  |                      |<-- User Data (ẩn pass)-|                      |                      |
  |<-- 201 Created ------|                        |                      |                      |
```

---

## 5. Hướng dẫn kiểm thử và Commit

### 5.1. Thao tác Commit mã nguồn
Chạy lệnh Git trên Terminal của VS Code / Codespaces:
```bash
git add lib/models/user.dart README_Assignment2_User_Model.md
git commit -m "feat(user-model): implement User OOP model, JSON mapping and sequence diagram documentation"
git push origin main
```

### 5.2. Danh sách minh chứng hoàn thành nộp bài
1. **File mã nguồn:** `lib/models/user.dart`.
2. **Ảnh chụp màn hình:**
   - Mã nguồn file `user.dart` mở trên IDE.
   - Sơ đồ Class Diagram và Sequence Diagram được vẽ trên công cụ (diagrams.net/draw.io).
   - Lịch sử Git commit trên GitHub/GitLab.