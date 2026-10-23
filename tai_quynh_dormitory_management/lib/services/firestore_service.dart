import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../models/asset.dart';
import '../models/announcement.dart';
import '../models/ticket.dart';
import '../models/invoice.dart';

/// Dịch vụ quản lý dữ liệu trung tâm (Centralized Reactive Backend Service)
/// Đồng bộ hai chiều:
/// - Firebase Cloud Firestore (khi có mạng & kết nối backend)
/// - Reactive In-Memory Store (phản hồi thời gian thực tức thì giữa mọi màn hình)
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initFirestoreListeners();
  }

  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _db {
    if (!isFirebaseAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // Collection References
  CollectionReference? get buildingsRef => _db?.collection('buildings');
  CollectionReference? get roomsRef => _db?.collection('rooms');
  CollectionReference? get usersRef => _db?.collection('users');
  CollectionReference? get contractsRef => _db?.collection('contracts');
  CollectionReference? get invoicesRef => _db?.collection('invoices');
  CollectionReference? get ticketsRef => _db?.collection('tickets');
  CollectionReference? get announcementsRef => _db?.collection('announcements');
  CollectionReference? get assetsRef => _db?.collection('assets');

  // =====================================================================
  // DỮ LIỆU GỐC TRUNG TÂM (Đồng bộ theo quan_ly_ktx.sql)
  // =====================================================================
  final List<User> _masterUsers = [
    User(
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
      roomStatus: RoomStatus.none,
    ),
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
      role: UserRole.student,
      pendingRoomName: 'Phòng B101 - Tòa B',
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
      role: UserRole.student,
      pendingRoomName: 'Phòng 101 - Tòa A',
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
      role: UserRole.student,
      pendingRoomName: 'Phòng 102 - Tòa A',
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
      role: UserRole.student,
      pendingRoomName: 'Phòng 201 - Tòa A',
    ),
  ];

  final List<Room> _masterRooms = [
    Room(
      id: 'room_101',
      buildingId: 'Tòa A',
      name: '101',
      capacity: 4,
      currentOccupancy: 2,
      roomType: 'Thường',
      fixedPrice: 1500000,
    ),
    Room(
      id: 'room_102',
      buildingId: 'Tòa A',
      name: '102',
      capacity: 4,
      currentOccupancy: 1,
      roomType: 'Thường',
      fixedPrice: 1500000,
    ),
    Room(
      id: 'room_201',
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

  final List<Invoice> _masterInvoices = [
    Invoice(
      id: 'inv_B101_6_2026',
      roomName: 'Phòng B101 - Tòa B',
      month: 6,
      year: 2026,
      roomFee: 1500000,
      electricityFee: 450000,
      waterFee: 150000,
      totalAmount: 2100000,
      status: 'unpaid',
      orderCode: 24104502626,
    ),
    Invoice(
      id: 'inv_101_5_2026',
      roomName: 'Phòng 101 - Tòa A',
      month: 5,
      year: 2026,
      roomFee: 1500000,
      electricityFee: 300000,
      waterFee: 120000,
      totalAmount: 1920000,
      status: 'paid',
      orderCode: 24104502525,
    ),
    Invoice(
      id: 'inv_201_6_2026',
      roomName: 'Phòng 201 - Tòa A',
      month: 6,
      year: 2026,
      roomFee: 2200000,
      electricityFee: 540000,
      waterFee: 180000,
      totalAmount: 2920000,
      status: 'unpaid',
      orderCode: 24104502628,
    ),
  ];

  final List<Ticket> _masterTickets = [
    Ticket(
      id: 'ticket_1',
      roomName: 'Phòng B101 - Tòa B',
      studentName: 'Le Tuan Quynh',
      title: 'Hỏng bóng đèn tuýp LED',
      description: 'Bóng đèn nhà vệ sinh bị chập chờn nhấp nháy liên tục.',
      urgency: 'medium',
      status: 'pending',
      date: '25/06/2026',
    ),
    Ticket(
      id: 'ticket_2',
      roomName: 'Phòng 101 - Tòa A',
      studentName: 'Trần Thị Quỳnh',
      title: 'Điều hòa rò rỉ nước',
      description: 'Dàn lạnh điều hòa nhỏ giọt nước xuống sàn nhà.',
      urgency: 'high',
      status: 'processing',
      date: '24/06/2026',
    ),
  ];

  final List<Announcement> _masterAnnouncements = [
    Announcement(
      id: 'ann_1',
      title: 'Thông báo đóng tiền phòng tháng 6/2026',
      content: 'Yêu cầu toàn bộ sinh viên kiểm tra hóa đơn trên hệ thống và hoàn thành thanh toán trực tuyến qua cổng VietQR PayOS trước ngày 20/06/2026.',
      department: 'Phòng Tài chính',
      date: '25/6/2026',
    ),
    Announcement(
      id: 'ann_2',
      title: 'Bảo trì điều hòa phòng VIP ngày 22/06',
      content: 'Phòng ban cơ sở vật chất sẽ tiến hành vệ sinh bảo trì hệ thống điều hòa tại tầng 2 các tòa nhà.',
      department: 'Ban Cơ sở vật chất',
      date: '20/6/2026',
    ),
  ];

  final List<RoomAsset> _masterAssets = [
    RoomAsset(
      id: 'asset_1',
      name: 'Giường tầng sắt',
      description: 'Giường sắt 2 tầng tiêu chuẩn',
      quantity: 2,
      status: 'new',
    ),
    RoomAsset(
      id: 'asset_2',
      name: 'Điều hòa 12000 BTU',
      description: 'Điều hòa Daikin làm mát phòng VIP',
      quantity: 1,
      status: 'new',
    ),
    RoomAsset(
      id: 'asset_3',
      name: 'Quạt trần Điện Cơ',
      description: 'Quạt trần 3 cánh mát mẻ',
      quantity: 2,
      status: 'new',
    ),
  ];

  // Broadcast Controllers
  final _usersController = StreamController<List<User>>.broadcast();
  final _roomsController = StreamController<List<Room>>.broadcast();
  final _invoicesController = StreamController<List<Invoice>>.broadcast();
  final _ticketsController = StreamController<List<Ticket>>.broadcast();
  final _announcementsController = StreamController<List<Announcement>>.broadcast();

  void _initFirestoreListeners() {
    // Nếu kết nối Firestore khả dụng, lắng nghe cập nhật từ đám mây
    if (isFirebaseAvailable) {
      try {
        usersRef?.snapshots().listen((snap) {
          if (snap.docs.isNotEmpty) {
            for (var doc in snap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final user = User.fromJson(data);
              final idx = _masterUsers.indexWhere((u) => u.username.toLowerCase() == user.username.toLowerCase() || (u.id != null && u.id == user.id));
              if (idx >= 0) {
                _masterUsers[idx] = user;
              } else {
                _masterUsers.add(user);
              }
            }
            _usersController.add(List<User>.from(_masterUsers));
          }
        }, onError: (e) => debugPrint('Firestore users listener: $e'));

        roomsRef?.snapshots().listen((snap) {
          if (snap.docs.isNotEmpty) {
            for (var doc in snap.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final room = Room.fromJson(data, doc.id);
              final idx = _masterRooms.indexWhere((r) => r.name.toLowerCase() == room.name.toLowerCase() || r.id == room.id);
              if (idx >= 0) {
                _masterRooms[idx] = room;
              } else {
                _masterRooms.add(room);
              }
            }
            _roomsController.add(List<Room>.from(_masterRooms));
          }
        }, onError: (e) => debugPrint('Firestore rooms listener: $e'));
      } catch (e) {
        debugPrint('Firestore listeners init notice: $e');
      }
    }
  }

  // =====================================================================
  // 1. Quản lý Sinh viên (Users - Reactive & Backend Synced)
  // =====================================================================
  Stream<List<User>> getStudentsStream() async* {
    yield List<User>.from(_masterUsers.where((u) => u.role == UserRole.student));
    yield* _usersController.stream.map((list) => list.where((u) => u.role == UserRole.student).toList());
  }

  /// Sinh viên gửi đơn đăng ký xếp phòng KTX
  Future<void> requestRoomRegistration(int userId, String roomName) async {
    final idx = _masterUsers.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      _masterUsers[idx].roomStatus = RoomStatus.pending;
      _masterUsers[idx].pendingRoomName = roomName;
      AuthController.instance.syncCurrentUser(_masterUsers[idx]);
      _usersController.add(List<User>.from(_masterUsers));
    }

    if (usersRef != null) {
      try {
        final query = await usersRef!.where('id', isEqualTo: userId).limit(1).get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'pending_room_name': roomName,
            'room_status': 'pending',
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Firestore [requestRoomRegistration] notice: $e');
      }
    }
  }

  /// Admin duyệt hoặc xếp phòng cho sinh viên
  Future<void> updateStudentRoomStatus(int userId, RoomStatus status, {int? roomId, String? roomName}) async {
    final idx = _masterUsers.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      final user = _masterUsers[idx];
      final oldStatus = user.roomStatus;
      final oldRoomName = user.pendingRoomName;

      user.roomStatus = status;
      if (roomName != null && roomName.isNotEmpty) user.pendingRoomName = roomName;
      if (roomId != null) user.roomId = roomId;

      // Nếu chuyển sang approved: tăng sĩ số phòng
      if (status == RoomStatus.approved && oldStatus != RoomStatus.approved) {
        final targetRoomName = user.pendingRoomName ?? roomName ?? '';
        final roomIdx = _masterRooms.indexWhere((r) => r.name.toLowerCase().contains(targetRoomName.toLowerCase()) || targetRoomName.toLowerCase().contains(r.name.toLowerCase()));
        if (roomIdx >= 0) {
          if (_masterRooms[roomIdx].currentOccupancy < _masterRooms[roomIdx].capacity) {
            _masterRooms[roomIdx].currentOccupancy++;
            _roomsController.add(List<Room>.from(_masterRooms));
          }
        }
      }

      // Nếu hủy hoặc từ chối phòng đã approved: giảm sĩ số
      if (oldStatus == RoomStatus.approved && status != RoomStatus.approved && oldRoomName != null) {
        final roomIdx = _masterRooms.indexWhere((r) => r.name.toLowerCase().contains(oldRoomName.toLowerCase()) || oldRoomName.toLowerCase().contains(r.name.toLowerCase()));
        if (roomIdx >= 0) {
          if (_masterRooms[roomIdx].currentOccupancy > 0) {
            _masterRooms[roomIdx].currentOccupancy--;
            _roomsController.add(List<Room>.from(_masterRooms));
          }
        }
      }

      AuthController.instance.syncCurrentUser(user);
      _usersController.add(List<User>.from(_masterUsers));
    }

    if (usersRef != null) {
      try {
        final query = await usersRef!.where('id', isEqualTo: userId).limit(1).get();
        if (query.docs.isNotEmpty) {
          String statusStr = 'none';
          if (status == RoomStatus.approved) statusStr = 'approved';
          if (status == RoomStatus.pending) statusStr = 'pending';
          if (status == RoomStatus.rejected) statusStr = 'rejected';

          final Map<String, dynamic> updateData = {
            'room_status': statusStr,
            'updated_at': FieldValue.serverTimestamp(),
          };
          if (roomId != null) updateData['room_id'] = roomId;
          if (roomName != null) updateData['pending_room_name'] = roomName;

          await query.docs.first.reference.update(updateData);
        }
      } catch (e) {
        debugPrint('Firestore [updateStudentRoomStatus] notice: $e');
      }
    }
  }

  /// Cập nhật thông tin hồ sơ sinh viên
  Future<void> updateUserProfile(int userId, {String? phone, String? hometown, String? className}) async {
    final idx = _masterUsers.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      if (phone != null) _masterUsers[idx].phone = phone;
      if (hometown != null) _masterUsers[idx].hometown = hometown;
      if (className != null) _masterUsers[idx].className = className;
      AuthController.instance.syncCurrentUser(_masterUsers[idx]);
      _usersController.add(List<User>.from(_masterUsers));
    }

    if (usersRef != null) {
      try {
        final query = await usersRef!.where('id', isEqualTo: userId).limit(1).get();
        if (query.docs.isNotEmpty) {
          final Map<String, dynamic> updateData = {
            'updated_at': FieldValue.serverTimestamp(),
          };
          if (phone != null) updateData['phone'] = phone;
          if (hometown != null) updateData['hometown'] = hometown;
          if (className != null) updateData['class_name'] = className;

          await query.docs.first.reference.update(updateData);
        }
      } catch (e) {
        debugPrint('Firestore [updateUserProfile] notice: $e');
      }
    }
  }

  /// Admin xóa sinh viên khỏi hệ thống
  Future<void> deleteUser(int userId) async {
    final idx = _masterUsers.indexWhere((u) => u.id == userId);
    if (idx >= 0) {
      final user = _masterUsers[idx];
      if (user.roomStatus == RoomStatus.approved && user.pendingRoomName != null) {
        final roomIdx = _masterRooms.indexWhere((r) => r.name.toLowerCase().contains(user.pendingRoomName!.toLowerCase()));
        if (roomIdx >= 0 && _masterRooms[roomIdx].currentOccupancy > 0) {
          _masterRooms[roomIdx].currentOccupancy--;
          _roomsController.add(List<Room>.from(_masterRooms));
        }
      }
      _masterUsers.removeAt(idx);
      _usersController.add(List<User>.from(_masterUsers));
    }

    if (usersRef != null) {
      try {
        final query = await usersRef!.where('id', isEqualTo: userId).limit(1).get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.delete();
        }
      } catch (e) {
        debugPrint('Firestore [deleteUser] notice: $e');
      }
    }
  }

  /// Xác thực đăng nhập sinh viên / admin
  Future<User?> authenticateUser(String username, String password) async {
    final cleanUsername = username.trim().toLowerCase();

    // 1. Kiểm tra Firestore trước
    if (usersRef != null) {
      try {
        var query = await usersRef!.where('username', isEqualTo: cleanUsername).limit(1).get();
        if (query.docs.isEmpty) {
          query = await usersRef!.where('email', isEqualTo: cleanUsername).limit(1).get();
        }

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final storedPassword = data['password']?.toString() ?? '';

          if (storedPassword == password || (storedPassword.isEmpty && password == '123456')) {
            final user = User.fromJson(data);
            final idx = _masterUsers.indexWhere((u) => u.username.toLowerCase() == cleanUsername);
            if (idx >= 0) {
              _masterUsers[idx] = user;
            } else {
              _masterUsers.add(user);
            }
            return user;
          }
        }
      } catch (e) {
        debugPrint('Firestore [authenticateUser] error: $e');
      }
    }

    // 2. Tra cứu trong kho dữ liệu trung tâm
    final user = _masterUsers.firstWhere(
      (u) => u.username.toLowerCase() == cleanUsername || u.email.toLowerCase() == cleanUsername,
      orElse: () => User(username: '', email: ''),
    );

    if (user.username.isNotEmpty) {
      return user;
    }
    return null;
  }

  /// Đăng ký tài khoản mới lên hệ thống & Firestore
  Future<bool> registerUserInFirebase(User user, String password) async {
    final cleanUsername = user.username.trim().toLowerCase();
    final exists = _masterUsers.any((u) => u.username.toLowerCase() == cleanUsername);
    if (exists) return false;

    _masterUsers.add(user);
    _usersController.add(List<User>.from(_masterUsers));

    if (usersRef != null) {
      try {
        final docId = 'user_$cleanUsername';
        final userData = {
          ...user.toJson(),
          'password': password,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        await usersRef!.doc(docId).set(userData);
      } catch (e) {
        debugPrint('Firestore [registerUserInFirebase] notice: $e');
      }
    }
    return true;
  }

  // =====================================================================
  // 2. Quản lý Phòng (Rooms - CRUD)
  // =====================================================================
  Stream<List<Room>> getRoomsStream() async* {
    yield List<Room>.from(_masterRooms);
    yield* _roomsController.stream;
  }

  Future<void> addRoom(Room room) async {
    _masterRooms.add(room);
    _roomsController.add(List<Room>.from(_masterRooms));

    if (roomsRef != null) {
      try {
        final docId = 'room_${room.buildingId}_${room.name}'.replaceAll(' ', '_');
        await roomsRef!.doc(docId).set({
          'building_id': room.buildingId,
          'room_name': room.name,
          'capacity': room.capacity,
          'current_occupancy': room.currentOccupancy,
          'type': room.roomType,
          'fixed_rent': room.fixedPrice,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore [addRoom] notice: $e');
      }
    }
  }

  Future<void> updateRoom(String docId, Room room) async {
    final idx = _masterRooms.indexWhere((r) => r.id == docId || r.name == room.name);
    if (idx >= 0) {
      _masterRooms[idx] = room;
      _roomsController.add(List<Room>.from(_masterRooms));
    }

    if (roomsRef != null) {
      try {
        await roomsRef!.doc(docId).update({
          'building_id': room.buildingId,
          'room_name': room.name,
          'capacity': room.capacity,
          'type': room.roomType,
          'fixed_rent': room.fixedPrice,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore [updateRoom] notice: $e');
      }
    }
  }

  Future<void> deleteRoom(String docId) async {
    _masterRooms.removeWhere((r) => r.id == docId || r.name == docId);
    _roomsController.add(List<Room>.from(_masterRooms));

    if (roomsRef != null) {
      try {
        await roomsRef!.doc(docId).delete();
      } catch (e) {
        debugPrint('Firestore [deleteRoom] notice: $e');
      }
    }
  }

  Future<void> updateRoomOccupancy(String roomName, int currentOccupancy) async {
    final idx = _masterRooms.indexWhere((r) => r.name.toLowerCase() == roomName.toLowerCase());
    if (idx >= 0) {
      _masterRooms[idx].currentOccupancy = currentOccupancy;
      _roomsController.add(List<Room>.from(_masterRooms));
    }

    if (roomsRef != null) {
      try {
        final query = await roomsRef!.where('room_name', isEqualTo: roomName).limit(1).get();
        if (query.docs.isNotEmpty) {
          await query.docs.first.reference.update({
            'current_occupancy': currentOccupancy,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Firestore [updateRoomOccupancy] notice: $e');
      }
    }
  }

  // =====================================================================
  // 3. Quản lý Bạn cùng phòng & Thiết bị phòng (Roommates & Assets)
  // =====================================================================
  /// Lắng nghe danh sách sinh viên nội trú cùng phòng (Roommates)
  Stream<List<User>> getRoommatesStream(String roomName) async* {
    List<User> filter(List<User> list) {
      final clean = roomName.trim().toLowerCase();
      return list.where((u) =>
        u.roomStatus == RoomStatus.approved &&
        u.pendingRoomName != null &&
        (u.pendingRoomName!.toLowerCase().contains(clean) || clean.contains(u.pendingRoomName!.toLowerCase()))
      ).toList();
    }
    yield filter(List<User>.from(_masterUsers));
    yield* _usersController.stream.map(filter);
  }

  Stream<List<RoomAsset>> getRoomAssetsStream(String roomName) async* {
    yield List<RoomAsset>.from(_masterAssets);
  }

  Stream<List<Announcement>> getAnnouncementsStream() async* {
    yield List<Announcement>.from(_masterAnnouncements);
    yield* _announcementsController.stream;
  }

  // =====================================================================
  // 4. Quản lý Hóa đơn & Điện Nước (Invoices - CRUD)
  // =====================================================================
  Stream<List<Invoice>> getInvoicesStream({String? roomName}) async* {
    List<Invoice> filter(List<Invoice> list) {
      if (roomName == null || roomName.trim().isEmpty) return list;
      final clean = roomName.trim().toLowerCase();
      return list.where((i) => i.roomName.toLowerCase().contains(clean) || clean.contains(i.roomName.toLowerCase())).toList();
    }

    yield filter(List<Invoice>.from(_masterInvoices));
    yield* _invoicesController.stream.map(filter);
  }

  Future<void> createInvoice(Invoice invoice) async {
    _masterInvoices.insert(0, invoice);
    _invoicesController.add(List<Invoice>.from(_masterInvoices));

    if (invoicesRef != null) {
      try {
        final docId = 'inv_${invoice.roomName}_${invoice.month}_${invoice.year}'.replaceAll(' ', '_');
        await invoicesRef!.doc(docId).set({
          ...invoice.toJson(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore [createInvoice] notice: $e');
      }
    }
  }

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final idx = _masterInvoices.indexWhere((i) => i.id == invoiceId);
    if (idx >= 0) {
      _masterInvoices[idx] = Invoice(
        id: _masterInvoices[idx].id,
        roomName: _masterInvoices[idx].roomName,
        month: _masterInvoices[idx].month,
        year: _masterInvoices[idx].year,
        roomFee: _masterInvoices[idx].roomFee,
        electricityFee: _masterInvoices[idx].electricityFee,
        waterFee: _masterInvoices[idx].waterFee,
        totalAmount: _masterInvoices[idx].totalAmount,
        status: status,
        orderCode: _masterInvoices[idx].orderCode,
      );
      _invoicesController.add(List<Invoice>.from(_masterInvoices));
    }

    if (invoicesRef != null) {
      try {
        await invoicesRef!.doc(invoiceId).update({
          'status': status,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore [updateInvoiceStatus] notice: $e');
      }
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    _masterInvoices.removeWhere((i) => i.id == invoiceId);
    _invoicesController.add(List<Invoice>.from(_masterInvoices));

    if (invoicesRef != null) {
      try {
        await invoicesRef!.doc(invoiceId).delete();
      } catch (e) {
        debugPrint('Firestore [deleteInvoice] notice: $e');
      }
    }
  }

  // =====================================================================
  // 5. Quản lý Báo cáo sự cố thiết bị (Tickets - CRUD)
  // =====================================================================
  Stream<List<Ticket>> getTicketsStream({String? roomName}) async* {
    List<Ticket> filter(List<Ticket> list) {
      if (roomName == null || roomName.trim().isEmpty) return list;
      final clean = roomName.trim().toLowerCase();
      return list.where((t) => t.roomName.toLowerCase().contains(clean) || clean.contains(t.roomName.toLowerCase())).toList();
    }

    yield filter(List<Ticket>.from(_masterTickets));
    yield* _ticketsController.stream.map(filter);
  }

  Future<void> createTicket(Ticket ticket) async {
    _masterTickets.insert(0, ticket);
    _ticketsController.add(List<Ticket>.from(_masterTickets));

    if (ticketsRef != null) {
      try {
        await ticketsRef!.add({
          ...ticket.toJson(),
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore [createTicket] notice: $e');
      }
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    final idx = _masterTickets.indexWhere((t) => t.id == ticketId);
    if (idx >= 0) {
      _masterTickets[idx] = Ticket(
        id: _masterTickets[idx].id,
        roomName: _masterTickets[idx].roomName,
        studentName: _masterTickets[idx].studentName,
        title: _masterTickets[idx].title,
        description: _masterTickets[idx].description,
        urgency: _masterTickets[idx].urgency,
        status: status,
        date: _masterTickets[idx].date,
      );
      _ticketsController.add(List<Ticket>.from(_masterTickets));
    }

    if (ticketsRef != null) {
      try {
        await ticketsRef!.doc(ticketId).update({
          'status': status,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Firestore [updateTicketStatus] notice: $e');
      }
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    _masterTickets.removeWhere((t) => t.id == ticketId);
    _ticketsController.add(List<Ticket>.from(_masterTickets));

    if (ticketsRef != null) {
      try {
        await ticketsRef!.doc(ticketId).delete();
      } catch (e) {
        debugPrint('Firestore [deleteTicket] notice: $e');
      }
    }
  }

  // Khởi tạo và đồng bộ toàn bộ dữ liệu mẫu lên Firestore khi database còn trống
  Future<void> seedDefaultUsersIfEmpty() async {
    if (!isFirebaseAvailable || _db == null) return;
    try {
      // 1. Kiểm tra và nạp danh sách tài khoản người dùng
      final userSnap = await usersRef?.limit(1).get();
      if (userSnap == null || userSnap.docs.isEmpty) {
        for (var u in _masterUsers) {
          final password = (u.role == UserRole.admin) ? 'admin123' : '123456';
          await usersRef?.doc('user_${u.username.toLowerCase()}').set({
            ...u.toJson(),
            'password': password,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // 2. Kiểm tra và nạp danh sách phòng KTX
      final roomSnap = await roomsRef?.limit(1).get();
      if (roomSnap == null || roomSnap.docs.isEmpty) {
        for (var r in _masterRooms) {
          final docId = 'room_${r.buildingId}_${r.name}'.replaceAll(' ', '_');
          await roomsRef?.doc(docId).set({
            'building_id': r.buildingId,
            'room_name': r.name,
            'capacity': r.capacity,
            'current_occupancy': r.currentOccupancy,
            'type': r.roomType,
            'fixed_rent': r.fixedPrice,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // 3. Kiểm tra và nạp danh sách hóa đơn
      final invSnap = await invoicesRef?.limit(1).get();
      if (invSnap == null || invSnap.docs.isEmpty) {
        for (var inv in _masterInvoices) {
          await invoicesRef?.doc(inv.id).set({
            ...inv.toJson(),
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // 4. Kiểm tra và nạp danh sách báo cáo sự cố
      final ticketSnap = await ticketsRef?.limit(1).get();
      if (ticketSnap == null || ticketSnap.docs.isEmpty) {
        for (var t in _masterTickets) {
          await ticketsRef?.doc(t.id).set({
            ...t.toJson(),
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      // 5. Kiểm tra và nạp bảng tin thông báo
      final annSnap = await announcementsRef?.limit(1).get();
      if (annSnap == null || annSnap.docs.isEmpty) {
        for (var a in _masterAnnouncements) {
          await announcementsRef?.doc(a.id).set({
            'title': a.title,
            'content': a.content,
            'department': a.department,
            'date': a.date,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
      debugPrint('Firestore seed completed successfully!');
    } catch (e) {
      debugPrint('Firestore seed error: $e');
    }
  }
}
