import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/user.dart';

class AuthResult {
  final bool success;
  final String message;
  final User? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthController extends ChangeNotifier {
  static final AuthController instance = AuthController._();

  factory AuthController() => instance;

  AuthController._();

  bool _isLoggedIn = false;
  bool _isLoading = false;

  User _currentUser = User(
    username: '',
    email: '',
  );

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  User get currentUser => _currentUser;
  UserRole get currentRole => _currentUser.role;

  bool get isAdmin {
    return _isLoggedIn &&
        _currentUser.role == UserRole.admin;
  }

  bool get isStudent => !isAdmin;

  static String accountEmail(String username) {
    final normalized = username.trim().toLowerCase();
    return '$normalized@domitory.local';
  }

  DocumentReference<Map<String, dynamic>> _profile(
    String username,
  ) {
    return FirebaseFirestore.instance
        .collection('v2_users')
        .doc(username);
  }

  Future<AuthResult> login(
    String username,
    String password,
  ) async {
    if (_isLoading) {
      return const AuthResult(
        success: false,
        message: 'Đang xử lý. Vui lòng chờ.',
      );
    }

    final normalized = username.trim().toLowerCase();

    if (normalized.isEmpty || password.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Vui lòng nhập tên đăng nhập và mật khẩu.',
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      final credential =
          await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: accountEmail(normalized),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw StateError('Không thể đăng nhập.');
      }

      final token = await firebaseUser.getIdTokenResult(true);

      final hasAdminPermission =
          normalized == 'admin' &&
              token.claims?['admin'] == true;

      if (normalized == 'admin' && !hasAdminPermission) {
        throw StateError(
          'Tài khoản admin chưa được cấu hình.',
        );
      }

      final profileSnapshot = await _profile(normalized).get();
      final profileData = profileSnapshot.data();

      if (!profileSnapshot.exists ||
          profileData == null ||
          profileData['owner_uid'] != firebaseUser.uid) {
        throw StateError(
          'Không tìm thấy hồ sơ hợp lệ. '
          'Vui lòng liên hệ quản trị viên.',
        );
      }

      final user = User.fromJson(profileData);

      if ((user.role == UserRole.admin) !=
          hasAdminPermission) {
        throw StateError('Quyền tài khoản không hợp lệ.');
      }

      await _profileSubscription?.cancel();

      _currentUser = user;
      _isLoggedIn = true;

      _profileSubscription =
          _profile(normalized).snapshots().listen(
        (document) {
          final data = document.data();

          if (!document.exists || data == null) {
            logout();
            return;
          }

          syncCurrentUser(User.fromJson(data));
        },
        onError: (Object error) {
          debugPrint(
            'Không thể cập nhật hồ sơ người dùng: $error',
          );
        },
      );

      return AuthResult(
        success: true,
        message: 'Đăng nhập thành công!',
        user: user,
      );
    } catch (error) {
      await _profileSubscription?.cancel();
      _profileSubscription = null;

      _isLoggedIn = false;

      _currentUser = User(
        username: '',
        email: '',
      );

      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {
        // Trạng thái giao diện vẫn được đưa về đăng xuất.
      }

      return AuthResult(
        success: false,
        message: _errorMessage(error),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    final normalized = username.trim().toLowerCase();

    if (role != UserRole.student ||
        normalized == 'admin') {
      return const AuthResult(
        success: false,
        message:
            'Chỉ cho phép đăng ký tài khoản sinh viên.',
      );
    }

    if (!RegExp(r'^[a-z0-9_]{3,40}$')
        .hasMatch(normalized)) {
      return const AuthResult(
        success: false,
        message:
            'Tên đăng nhập gồm 3–40 ký tự: '
            'chữ thường, số hoặc dấu gạch dưới.',
      );
    }

    if (password.length < 6) {
      return const AuthResult(
        success: false,
        message: 'Mật khẩu phải có ít nhất 6 ký tự.',
      );
    }

    if (fullName.trim().isEmpty ||
        mssv.trim().isEmpty) {
      return const AuthResult(
        success: false,
        message:
            'Vui lòng nhập họ tên và mã số sinh viên.',
      );
    }

    if (_isLoading) {
      return const AuthResult(
        success: false,
        message: 'Đang xử lý. Vui lòng chờ.',
      );
    }

    if (_isLoggedIn) {
      return const AuthResult(
        success: false,
        message:
            'Vui lòng đăng xuất trước khi đăng ký tài khoản mới.',
      );
    }

    _isLoading = true;
    notifyListeners();

    fb.User? createdUser;
    bool profileSaved = false;

    try {
      final credential =
          await fb.FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: accountEmail(normalized),
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw StateError('Không thể tạo tài khoản.');
      }

      final student = User(
        id: DateTime.now().microsecondsSinceEpoch,
        username: normalized,
        email: email.trim(),
        fullName: fullName.trim(),
        mssv: mssv.trim(),
        phone: phone.trim(),
        className: className.trim(),
        hometown: hometown.trim(),
        role: UserRole.student,
        roomStatus: RoomStatus.none,
        roomId: null,
        pendingRoomId: null,
        pendingRoomName: null,
      );

      await _profile(normalized).set({
        ...student.toJson(),
        'owner_uid': createdUser.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      profileSaved = true;

      return const AuthResult(
        success: true,
        message:
            'Đăng ký thành công. Vui lòng đăng nhập.',
      );
    } catch (error) {
      if (createdUser != null && !profileSaved) {
        try {
          await createdUser.delete();
        } catch (_) {
          debugPrint(
            'Tài khoản đăng ký chưa hoàn tất. '
            'Có thể cần xử lý trong Firebase Console.',
          );
        }
      }

      return AuthResult(
        success: false,
        message: _errorMessage(error),
      );
    } finally {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {
        // Không đổi kết quả tạo hồ sơ đã hoàn tất.
      }

      _isLoggedIn = false;
      _isLoading = false;

      _currentUser = User(
        username: '',
        email: '',
      );

      notifyListeners();
    }
  }

  void syncCurrentUser(User user) {
    if (!_isLoggedIn) return;

    if (user.username != _currentUser.username) {
      return;
    }

    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;

    _isLoggedIn = false;

    _currentUser = User(
      username: '',
      email: '',
    );

    notifyListeners();

    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (error) {
      debugPrint('Không thể hoàn tất đăng xuất: $error');
    }
  }

  String _errorMessage(Object error) {
    if (error is fb.FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Tên đăng nhập đã tồn tại.';

        case 'weak-password':
          return 'Mật khẩu chưa đủ mạnh.';

        case 'network-request-failed':
          return 'Không thể kết nối. '
              'Vui lòng kiểm tra mạng.';

        case 'operation-not-allowed':
          return 'Cần bật Email/Password '
              'trong Firebase Authentication.';

        case 'too-many-requests':
          return 'Quá nhiều lần thử. '
              'Vui lòng thử lại sau.';

        case 'user-disabled':
          return 'Tài khoản đã bị vô hiệu hóa.';

        default:
          return 'Tên đăng nhập hoặc mật khẩu không đúng, '
              'hoặc tài khoản không khả dụng.';
      }
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Không thể xử lý tài khoản. '
        'Kiểm tra kết nối và cấu hình Firebase.';
  }
}