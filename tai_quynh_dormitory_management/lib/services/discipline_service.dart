import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import 'firestore_service.dart';
import '../models/attendance.dart';
import '../models/user.dart';

class DisciplineService {
  Uint8List? _pendingPhoto;
  String? _pendingRequestId;
  String? _pendingDay;

  bool get hasPendingUpload =>
      _pendingPhoto != null && _pendingDay == AttendanceClock.today;

  final _db = FirebaseFirestore.instance;

  final _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<dynamic>(data);

      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(
        error.message ?? 'Không thể kết nối dịch vụ quản lý ký túc xá.',
      );
    }
  }

  Query<Map<String, dynamic>> _scoped(String name) {
    final auth = AuthController.instance;

    if (auth.isAdmin) {
      return _db.collection(name);
    }

    if (auth.isBuildingManager) {
      return _db.collection(name).where(
        'building_id',
        isEqualTo: auth.currentUser.managedBuildingId,
      );
    }

    if (auth.isStudent && fb.FirebaseAuth.instance.currentUser != null) {
      return _db.collection(name).where(
        'owner_uid',
        isEqualTo: fb.FirebaseAuth.instance.currentUser!.uid,
      );
    }

    throw StateError(
      'Vui lòng đăng nhập bằng tài khoản đã được cấp quyền.',
    );
  }

  Stream<List<AttendanceEntry>> attendance(
    String day, {
    String? building,
  }) {
    var query = _scoped('v2_attendance').where(
      'day',
      isEqualTo: day,
    );

    if (AuthController.instance.isAdmin && building != null) {
      query = query.where('building_id', isEqualTo: building);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AttendanceEntry(doc.id, doc.data()))
          .toList()
        ..sort(
          (a, b) => '${a.roomName} ${a.studentName}'
              .compareTo('${b.roomName} ${b.studentName}'),
        ),
    );
  }

  Stream<List<ViolationEntry>> violations(String monday) {
    return _scoped('v2_violations')
        .where('week_start', isEqualTo: monday)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ViolationEntry(doc.id, doc.data()))
              .toList()
            ..sort((a, b) => b.day.compareTo(a.day)),
        );
  }

  Stream<String?> session(String day) {
    return _db
        .collection('v2_attendance_sessions')
        .doc(day)
        .snapshots()
        .map((doc) => doc.data()?['status']?.toString());
  }

  Stream<List<User>> managers() {
    if (!AuthController.instance.isAdmin) {
      throw StateError('Chỉ admin được duyệt quản lý tòa.');
    }

    return _db
        .collection('v2_users')
        .where('role', isEqualTo: 'buildingManager')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => User.fromJson(doc.data()))
              .toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName)),
        );
  }

  Future<void> reviewManager(
    User user, {
    required bool approve,
    String? building,
  }) async {
    await FirestoreService().reviewBuildingManager(
      user,
      approve: approve,
      building: building,
    );
  }

  Future<List<Map<String, dynamic>>> roomResidents(
    String roomId,
  ) async {
    return FirestoreService().getRoomResidentsStream(roomId).first;
  }

  Future<List<Map<String, dynamic>>> managedResidents() {
    return FirestoreService().managedResidents();
  }

  Future<void> submitPhoto(XFile photo) async {
    final user = fb.FirebaseAuth.instance.currentUser;

    if (user == null || !AuthController.instance.isStudent) {
      throw StateError('Vui lòng đăng nhập sinh viên.');
    }

    if (!AttendanceClock.isOpen) {
      throw StateError(
        'Chỉ nhận ảnh từ 22:00 đến trước 22:10 (giờ Việt Nam).',
      );
    }

    if (await photo.length() > 2 * 1024 * 1024) {
      throw StateError('Vui lòng chọn ảnh tối đa 2 MB.');
    }

    final bytes = await photo.readAsBytes();

    _mime(bytes);

    _pendingPhoto = bytes;
    _pendingDay = AttendanceClock.today;
    _pendingRequestId = 'photo_${DateTime.now().microsecondsSinceEpoch}';

    await retrySubmission();
  }

  Future<void> retrySubmission() async {
    if (!hasPendingUpload) {
      throw StateError('Không có ảnh chờ xác nhận trong ngày này.');
    }

    await call('submitAttendance', {
      'photoBase64': base64Encode(_pendingPhoto!),
      'requestId': _pendingRequestId,
    });

    _pendingPhoto = null;
    _pendingRequestId = null;
    _pendingDay = null;
  }

  String _mime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'image/jpeg';
    }

    if (bytes.length >= 8 &&
        bytes.take(8).join(',') == '137,80,78,71,13,10,26,10') {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }

    throw StateError('Vui lòng chọn ảnh JPEG, PNG hoặc WebP.');
  }

  Future<Uint8List> evidence(String attendanceId) async {
    final result = await call('getAttendanceEvidence', {
      'attendanceId': attendanceId,
    });

    return base64Decode(result['base64'] as String);
  }

  Future<void> reviewEvidence(
    String id, {
    required bool accept,
    String? reason,
  }) async {
    await call('reviewAttendanceEvidence', {
      'attendanceId': id,
      'accept': accept,
      'reason': reason,
    });
  }

  Future<void> recordViolation({
    required String username,
    required String ruleId,
    required String note,
    required String requestId,
  }) async {
    await call('recordDormitoryViolation', {
      'username': username,
      'ruleId': ruleId,
      'note': note,
      'requestId': requestId,
    });
  }
}