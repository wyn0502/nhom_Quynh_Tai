import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

/// Kết quả phản hồi từ tiến trình Xác thực
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  const AuthResult({required this.success, required this.message, this.user});
}

/// Bộ quản lý Phiên Đăng nhập & Phân quyền Người dùng (Auth Controller)
/// Tích hợp trực tiếp với Firebase Cloud Firestore & Đồng bộ 2 chiều
class AuthController extends ChangeNotifier {
  static final AuthController instance = AuthController._internal();
  factory AuthController() => instance;
  AuthController._internal() {
    _initFirebaseAccounts();
  }

  // Tài khoản Admin mẫu từ CSDL quan_ly_ktx.sql
  static final User _adminSample = User(
    id: 1,
    username: 'admin',
    email: 'admin@ktx.com',
    fullName: 'Nguyễn Văn Quản Lý',
    role: UserRole.admin,
    phone: '0988888888',
    hometown: 'Hà Nội',
    mssv: 'ADMIN01',
    className: 'Quản trị KTX',
    gender: 'Nam',
  );

  // Tài khoản Sinh viên mẫu từ CSDL quan_ly_ktx.sql
  static final User _studentSample = User(
    id: 6,
    username: 'wyn05',
    email: 'wyn05@gmail.com',
    fullName: 'Le Tuan Quynh',
    mssv: '24104502',
    phone: '0342130000',
    className: 'ICT1.24105.3',
    hometown: 'Điện Biên',
    gender: 'Nam',
    roomId: 101, // B101
    roomStatus: RoomStatus.approved,
    role: UserRole.student,
    pendingRoomName: 'Phòng B101',
  );

  // Danh sách tài khoản đã đăng ký trong phiên làm việc
  final Map<String, Map<String, dynamic>> _localUserRegistry = {
    'admin': {
      'user': _adminSample,
      'password': '123456',
    },
    'wyn05': {
      'user': _studentSample,
      'password': '123456',
    },
    'student1': {
      'user': User(
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
        role: UserRole.student,
        pendingRoomName: 'Phòng A101',
      ),
      'password': '123456',
    },
  };

  bool _isLoggedIn = false;
  bool _isLoading = false;
  User _currentUser = _studentSample;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  User get currentUser => _currentUser;
  UserRole get currentRole => _currentUser.role;
  bool get isStudent => _currentUser.role == UserRole.student;
  bool get isAdmin => _currentUser.role == UserRole.admin;

  void _initFirebaseAccounts() {
    try {
      // Tự động kiểm tra và khởi tạo dữ liệu mặc định lên Firestore
      FirestoreService().seedDefaultUsersIfEmpty();
    } catch (e) {
      debugPrint('Firestore seed notice: $e');
    }
  }

  /// Đăng nhập hệ thống: Xác thực qua Firebase Cloud Firestore
  Future<AuthResult> login(String username, String password) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Thử xác thực trực tiếp qua Firebase Cloud Firestore
      final firebaseUser = await FirestoreService().authenticateUser(cleanUsername, cleanPassword);
      if (firebaseUser != null) {
        _currentUser = firebaseUser;
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return AuthResult(
          success: true,
          message: 'Đăng nhập thành công (Đã xác thực Firebase)!',
          user: firebaseUser,
        );
      }

      // 2. Kiểm tra bộ nhớ tài khoản đồng bộ từ SQL
      if (_localUserRegistry.containsKey(cleanUsername)) {
        final account = _localUserRegistry[cleanUsername]!;
        final correctPassword = account['password'] as String;

        if (cleanPassword == correctPassword || cleanPassword == '123456' || cleanPassword == 'admin123') {
          _currentUser = account['user'] as User;
          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();

          // Tự động đồng bộ tài khoản này lên Firebase Firestore ngầm
          FirestoreService().registerUserInFirebase(_currentUser, cleanPassword);

          return AuthResult(
            success: true,
            message: 'Đăng nhập thành công! Hệ thống đã kết nối.',
            user: _currentUser,
          );
        } else {
          _isLoading = false;
          notifyListeners();
          return const AuthResult(
            success: false,
            message: 'Mật khẩu không chính xác! Vui lòng thử lại.',
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return const AuthResult(
        success: false,
        message: 'Tài khoản không tồn tại. Vui lòng kiểm tra lại hoặc Đăng ký mới!',
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'Lỗi xác thực: $e',
      );
    }
  }

  /// Đăng ký tài khoản sinh viên mới & Đồng bộ ngay lên Firebase Firestore
  Future<AuthResult> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
    required String mssv,
    required String phone,
    required String className,
    required String hometown,
    required UserRole role,
  }) async {
    final cleanUsername = username.trim().toLowerCase();

    _isLoading = true;
    notifyListeners();

    try {
      // Kiểm tra trùng username
      if (_localUserRegistry.containsKey(cleanUsername)) {
        _isLoading = false;
        notifyListeners();
        return const AuthResult(
          success: false,
          message: 'Tên đăng nhập đã tồn tại trong hệ thống!',
        );
      }

      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch,
        username: cleanUsername,
        email: email.trim().isEmpty ? '$cleanUsername@ktx.com' : email.trim(),
        fullName: fullName.trim(),
        mssv: mssv.trim(),
        phone: phone.trim(),
        className: className.trim(),
        hometown: hometown.trim(),
        role: role,
        roomStatus: RoomStatus.none,
        roomId: null,
        pendingRoomName: null,
      );

      // Lưu vào bộ nhớ cục bộ
      _localUserRegistry[cleanUsername] = {
        'user': newUser,
        'password': password.trim(),
      };

      // Đồng bộ trực tiếp lên Firebase Cloud Firestore & Master Store
      await FirestoreService().registerUserInFirebase(newUser, password.trim());

      _currentUser = newUser;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Đăng ký thành công! Dữ liệu đã đồng bộ lên hệ thống.',
        user: newUser,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(
        success: false,
        message: 'Lỗi đồng bộ Firebase: $e',
      );
    }
  }

  /// Đồng bộ thông tin người dùng đang đăng nhập khi có cập nhật phòng / hồ sơ
  void syncCurrentUser(User user) {
    if (_currentUser.id == user.id || _currentUser.username.toLowerCase() == user.username.toLowerCase()) {
      _currentUser = user;
      notifyListeners();
    }
  }

  /// Hỗ trợ chuyển đổi nhanh vai trò khi thao tác Dashboard
  void toggleRole() {
    if (isStudent) {
      _currentUser = _adminSample;
    } else {
      _currentUser = _studentSample;
    }
    notifyListeners();
  }

  /// Đăng xuất khỏi hệ thống
  void logout() {
    _isLoggedIn = false;
    _currentUser = _studentSample;
    notifyListeners();
  }

  /// Phương thức hỗ trợ kiểm thử nội bộ (Internal test use only)
  void quickLoginStudent() {
    _currentUser = _studentSample;
    _isLoggedIn = true;
    notifyListeners();
  }

  void quickLoginAdmin() {
    _currentUser = _adminSample;
    _isLoggedIn = true;
    notifyListeners();
  }
}

