import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/auth_controller.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/invoice.dart';
import '../models/ticket.dart';
import '../models/asset.dart';
import '../models/announcement.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();

  factory FirestoreService() => _instance;

  FirestoreService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String name) {
    return db.collection('v2_$name');
  }

  void requireAdmin() {
    if (!AuthController.instance.isAdmin) {
      throw StateError(
        'Chỉ quản trị viên được thực hiện thao tác này.',
      );
    }
  }

  static String roomLabel(Room room) {
    return 'Phòng ${room.name} - ${room.buildingId}';
  }

  Stream<List<Room>> getRoomsStream() {
    final auth = AuthController.instance;

    Query<Map<String, dynamic>> rooms = collection('rooms');

    if (auth.isBuildingManager) {
      rooms = rooms.where(
        'building_id',
        isEqualTo: auth.currentUser.managedBuildingId,
      );
    }

    return rooms.snapshots().map(
      (snapshot) => snapshot.docs.map((document) {
        return Room.fromJson(
          document.data(),
          document.id,
        );
      }).toList(),
    );
  }

  Stream<List<User>> getStudentsStream() {
    return collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            return User.fromJson(document.data());
          }).toList(),
        );
  }

  Stream<List<User>> getRoommatesStream(String roomName) {
    return collection('users')
        .where('role', isEqualTo: 'student')
        .where('room_status', isEqualTo: 'approved')
        .where('pending_room_name', isEqualTo: roomName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            return User.fromJson(document.data());
          }).toList(),
        );
  }


  // Public, minimal roster. Never expose the private v2_users documents.
  Stream<List<Map<String, dynamic>>> getRoomResidentsStream(
    String roomId,
  ) {
    return collection('room_rosters').doc(roomId).snapshots().map(
      (document) => _rosterMembers(document.data())
        ..sort((a, b) => a['full_name'].toString()
            .compareTo(b['full_name'].toString())),
    );
  }

  static List<Map<String, dynamic>> _rosterMembers(
    Map<String, dynamic>? data,
  ) {
    final values = data?['members'];
    if (values is! List) return <Map<String, dynamic>>[];
    return values
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  static Map<String, dynamic> _rosterData(
    String id,
    Map<String, dynamic> room,
    List<Map<String, dynamic>> members,
  ) {
    return {
      'room_id': id,
      'room_name': room['label'],
      'building_id': room['building_id'],
      'members': members,
    };
  }

  // One-time migration for records approved before Spark support.
  // Admin invokes this explicitly when residents are not yet indexed.
  Future<void> syncRoomRosters() async {
    requireAdmin();
    final rooms = await collection('rooms').get();
    final users = await collection('users')
        .where('role', isEqualTo: 'student')
        .where('room_status', isEqualTo: 'approved')
        .get();

    final rosters = <String, List<Map<String, dynamic>>>{
      for (final room in rooms.docs) room.id: <Map<String, dynamic>>[],
    };
    final roomByLabel = {
      for (final room in rooms.docs)
        room.data()['label']?.toString() ?? '': room.id,
    };

    for (final document in users.docs) {
      final user = document.data();
      final docId = user['pending_room_doc']?.toString();
      final fallback = roomByLabel[user['pending_room_name']?.toString()];
      final id = rosters.containsKey(docId) ? docId : fallback;
      if (id == null) continue;

      rosters[id]!.add({
        'username': document.id,
        'full_name': user['full_name']?.toString() ?? document.id,
        'mssv': user['mssv']?.toString() ?? '',
      });
    }

    // One-time snapshot rebuild. Do not approve/return rooms concurrently:
    // this intentionally replaces any old, incomplete roster snapshot.
    for (final room in rooms.docs) {
      final ref = collection('room_rosters').doc(room.id);
      final members = rosters[room.id]!;
      // Only run once during migration when no approval is in progress.
      await ref.set(_rosterData(room.id, room.data(), members));
    }
  }

  Future<List<Map<String, dynamic>>> managedResidents() async {
    final user = AuthController.instance.currentUser;
    if (!user.canManageBuilding) {
      throw StateError('Bạn chưa được phân công quản lý tòa.');
    }

    final rooms = await getRoomsStream().first;
    final rosters = await Future.wait(rooms.map((room) =>
        collection('room_rosters').doc(room.id!).get()));

    final result = <Map<String, dynamic>>[];
    for (var index = 0; index < rooms.length; index++) {
      final room = rooms[index];
      for (final member in _rosterMembers(rosters[index].data())) {
        result.add({
          ...member,
          'room_name': roomLabel(room),
          'building_id': room.buildingId,
        });
      }
    }
    return result
      ..sort((a, b) => '${a['room_name']} ${a['full_name']}'
          .compareTo('${b['room_name']} ${b['full_name']}'));
  }

  // Runs entirely on Firestore (Spark): all manager privileges are
  // checked again by firestore.rules. The assignment doc is a shared
  // transaction contention point enforcing at most two managers.
  Future<void> reviewBuildingManager(
    User manager, {
    required bool approve,
    String? building,
  }) async {
    requireAdmin();
    if (!manager.isBuildingManager) {
      throw StateError('Tài khoản không phải quản lý tòa.');
    }
    final target = building?.trim();
    if (approve) {
      if (target == null || target.isEmpty) {
        throw StateError('Hãy chọn tòa quản lý.');
      }
      final validRoom = await collection('rooms')
          .where('building_id', isEqualTo: target)
          .limit(1)
          .get();
      if (validRoom.docs.isEmpty) {
        throw StateError('Tòa chưa có phòng hợp lệ.');
      }
    }

    // Include pre-existing approved managers before the assignments
    // collection was introduced; do not silently grant a third slot.
    final allManagers = await collection('users')
        .where('role', isEqualTo: 'buildingManager')
        .get();
    final legacy = allManagers.docs
        .where((doc) => doc.data()['manager_status'] == 'approved')
        .toList();

    final ref = collection('users').doc(manager.username);
    await db.runTransaction((tx) async {
      final current = (await tx.get(ref)).data();
      if (current == null || current['role'] != 'buildingManager') {
        throw StateError('Không tìm thấy tài khoản quản lý tòa.');
      }
      if (approve && current['manager_status'] == 'approved') {
        throw StateError('Tài khoản đã được duyệt.');
      }

      final assigned = approve
          ? target!
          : (current['managed_building_id']?.toString() ?? '');
      final assignment = assigned.isEmpty
          ? null
          : collection('manager_assignments')
              .doc(Uri.encodeComponent(assigned));
      final document = assignment == null ? null : await tx.get(assignment);
      final slots = <String>{
        ...((document?.data()?['usernames'] as List?) ?? [])
            .map((value) => value.toString()),
        ...legacy
            .where((doc) => doc.data()['managed_building_id'] == assigned)
            .map((doc) => doc.id),
      };

      if (approve) {
        if (!slots.contains(manager.username) && slots.length >= 2) {
          throw StateError('Tòa đã đủ 2 người quản lý.');
        }
        slots.add(manager.username);
      } else {
        slots.remove(manager.username);
      }

      if (slots.length > 2) {
        throw StateError(
          'Tòa đang có hơn 2 quản lý cũ. Hãy kiểm tra dữ liệu trước.',
        );
      }
      if (assignment != null) {
        tx.set(assignment, {
          'building_id': assigned,
          'usernames': slots.toList()..sort(),
        });
      }
      tx.update(ref, {
        'manager_status': approve ? 'approved' : 'rejected',
        'managed_building_id': approve ? target : null,
        'reviewed_by': 'admin',
        'reviewed_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Invoice>> getInvoicesStream({
    String? roomName,
  }) {
    final auth = AuthController.instance;

    if (!auth.isAdmin &&
        auth.currentUser.roomStatus != RoomStatus.approved) {
      return Stream.value(<Invoice>[]);
    }

    Query<Map<String, dynamic>> query = collection('invoices');

    if (roomName != null) {
      query = query.where('room_name', isEqualTo: roomName);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((document) {
        return Invoice.fromJson(
          document.data(),
          document.id,
        );
      }).toList(),
    );
  }

  Stream<List<Ticket>> getTicketsStream({
    String? roomName,
  }) {
    final auth = AuthController.instance;

    if (!auth.isAdmin &&
        auth.currentUser.roomStatus != RoomStatus.approved) {
      return Stream.value(<Ticket>[]);
    }

    Query<Map<String, dynamic>> query = collection('tickets');

    if (roomName != null) {
      query = query.where('room_name', isEqualTo: roomName);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((document) {
        return Ticket.fromJson(
          document.data(),
          document.id,
        );
      }).toList(),
    );
  }

  Stream<List<Announcement>> getAnnouncementsStream() {
    return collection('announcements').snapshots().map(
      (snapshot) => snapshot.docs.map((document) {
        final data = document.data();

        return Announcement(
          id: document.id,
          title: data['title']?.toString() ?? '',
          content: data['content']?.toString() ?? '',
          department: data['department']?.toString() ?? '',
          date: data['date']?.toString() ?? '',
        );
      }).toList(),
    );
  }

  Stream<List<RoomAsset>> getRoomAssetsStream(String roomName) {
    return collection('assets')
        .where('room_name', isEqualTo: roomName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) {
            final data = document.data();

            return RoomAsset(
              id: document.id,
              name: data['name']?.toString() ?? '',
              description: data['description']?.toString() ?? '',
              quantity: (data['quantity'] as num?)?.toInt() ?? 0,
              status: data['status']?.toString() ?? 'used',
            );
          }).toList(),
        );
  }

  Future<DocumentReference<Map<String, dynamic>>> _user(
    int userId,
  ) async {
    final auth = AuthController.instance;

    if (auth.isLoggedIn && auth.currentUser.id == userId) {
      return collection('users').doc(auth.currentUser.username);
    }

    requireAdmin();

    final snapshot = await collection('users')
        .where('id', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError('Không tìm thấy sinh viên.');
    }

    return snapshot.docs.first.reference;
  }

  Future<DocumentReference<Map<String, dynamic>>> _room(
    String label,
  ) async {
    final snapshot = await collection('rooms')
        .where('label', isEqualTo: label)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError('Phòng không còn tồn tại.');
    }

    return snapshot.docs.first.reference;
  }

  Future<void> _sync(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final snapshot = await reference.get();
    final data = snapshot.data();

    if (data == null) return;

    AuthController.instance.syncCurrentUser(
      User.fromJson(data),
    );
  }

  Future<void> requestRoomRegistration(
    int userId,
    String roomName,
  ) async {
    final auth = AuthController.instance;

    if (!auth.isLoggedIn ||
        !auth.isStudent ||
        auth.currentUser.id != userId) {
      throw StateError('Không có quyền đăng ký phòng.');
    }

    final userReference = collection('users').doc(
      auth.currentUser.username,
    );

    final roomReference = await _room(roomName);

    await db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userReference);
      final roomSnapshot = await transaction.get(roomReference);

      final user = userSnapshot.data();
      final room = roomSnapshot.data();

      if (user == null || room == null) {
        throw StateError('Không tìm thấy hồ sơ hoặc phòng.');
      }

      final status = user['room_status'];

      if (status == 'pending' || status == 'approved') {
        throw StateError(
          'Bạn đã đăng ký phòng. Vui lòng chờ admin xử lý.',
        );
      }

      final occupancy =
          (room['current_occupancy'] as num).toInt();

      final capacity = (room['capacity'] as num).toInt();

      if (occupancy >= capacity) {
        throw StateError('Phòng đã đầy.');
      }

      final requests =
          (room['active_requests'] as num?)?.toInt() ?? 0;

      transaction.update(userReference, {
        'room_status': 'pending',
        'room_id': null,
        'pending_room_name': roomName,
        'pending_room_doc': roomReference.id,
      });

      transaction.update(roomReference, {
        'active_requests': requests + 1,
      });
    });

    await _sync(userReference);
  }

  Future<void> updateStudentRoomStatus(
    int userId,
    RoomStatus status, {
    int? roomId,
    String? roomName,
  }) async {
    requireAdmin();

    if (status == RoomStatus.pending) {
      throw StateError(
        'Trạng thái chờ duyệt được tạo khi sinh viên đăng ký.',
      );
    }

    final userReference = await _user(userId);

    final targetReference =
        roomName != null && roomName.isNotEmpty
            ? await _room(roomName)
            : null;

    await db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userReference);
      final user = userSnapshot.data();

      if (user == null || user['role'] != 'student') {
        throw StateError('Không tìm thấy sinh viên hợp lệ.');
      }

      final oldRoomId = user['pending_room_doc'] as String?;

      final oldRoomReference = oldRoomId == null
          ? null
          : collection('rooms').doc(oldRoomId);

      final newRoomReference =
          targetReference ?? oldRoomReference;

      final oldRoom = oldRoomReference == null
          ? null
          : (await transaction.get(oldRoomReference)).data();

      final newRoom = newRoomReference == null
          ? null
          : (await transaction.get(newRoomReference)).data();

      final oldStatus = user['room_status'];

      final oldRosterRef = oldRoomReference == null
          ? null : collection('room_rosters').doc(oldRoomReference.id);
      final newRosterRef = newRoomReference == null
          ? null : collection('room_rosters').doc(newRoomReference.id);

      final oldRoster = oldRosterRef == null
          ? null : (await transaction.get(oldRosterRef)).data();
      final newRoster = newRosterRef == null
          ? null : oldRosterRef?.path == newRosterRef.path
              ? oldRoster : (await transaction.get(newRosterRef)).data();

      if (status == RoomStatus.approved) {
        if (newRoom == null || newRoomReference == null) {
          throw StateError('Chưa chọn phòng hợp lệ.');
        }

        if (oldStatus == 'approved' &&
            oldRoomReference?.id == newRoomReference.id) {
          return;
        }

        final occupancy =
            (newRoom['current_occupancy'] as num).toInt();

        final capacity =
            (newRoom['capacity'] as num).toInt();

        if (occupancy >= capacity) {
          throw StateError(
            'Phòng đã đầy, không thể duyệt thêm.',
          );
        }
      }

      if (oldRoom != null && oldRoomReference != null) {
        if (oldStatus == 'pending') {
          final requests =
              (oldRoom['active_requests'] as num?)?.toInt() ?? 0;

          if (requests < 1) {
            throw StateError(
              'Số đơn chờ của phòng không hợp lệ.',
            );
          }

          transaction.update(oldRoomReference, {
            'active_requests': requests - 1,
          });
        }

        if (oldStatus == 'approved') {
          final occupancy =
              (oldRoom['current_occupancy'] as num).toInt();

          if (occupancy < 1) {
            throw StateError('Sĩ số phòng không hợp lệ.');
          }

          transaction.update(oldRoomReference, {
            'current_occupancy': occupancy - 1,
          });
        }
      }

      if (status == RoomStatus.approved) {
        final occupancy =
            (newRoom!['current_occupancy'] as num).toInt();

        transaction.update(newRoomReference!, {
          'current_occupancy': occupancy + 1,
        });
      }

      // Keep the sanitized room roster in the same transaction as the
      // user's residence status and the room occupancy.
      final username = userReference.id;
      if (oldStatus == 'approved' &&
          oldRosterRef != null && oldRoom != null) {
        final members = _rosterMembers(oldRoster)
          ..removeWhere((entry) => entry['username'] == username);
        transaction.set(
          oldRosterRef,
          _rosterData(oldRoomReference!.id, oldRoom, members),
        );
      }

      if (status == RoomStatus.approved &&
          newRosterRef != null && newRoom != null) {
        final members = _rosterMembers(newRoster)
          ..removeWhere((entry) => entry['username'] == username);
        members.add({
          'username': username,
          'full_name': user['full_name']?.toString() ?? username,
          'mssv': user['mssv']?.toString() ?? '',
        });
        transaction.set(
          newRosterRef,
          _rosterData(newRoomReference!.id, newRoom, members),
        );
      }

      transaction.update(userReference, {
        'room_status': status.name,
        'room_approved_at': status == RoomStatus.approved
            ? FieldValue.serverTimestamp()
            : null,
        'room_id': status == RoomStatus.approved
            ? (roomId ?? 1)
            : null,
        'pending_room_doc': status == RoomStatus.approved
            ? newRoomReference!.id
            : null,
        'pending_room_name': status == RoomStatus.approved
            ? newRoom!['label']
            : null,
      });
    });

    await _sync(userReference);
  }

  Future<void> updateUserProfile(
    int userId, {
    String? phone,
    String? hometown,
    String? className,
  }) async {
    final reference = await _user(userId);

    await reference.update({
      if (phone != null) 'phone': phone.trim(),
      if (hometown != null) 'hometown': hometown.trim(),
      if (className != null) 'class_name': className.trim(),
    });

    await _sync(reference);
  }

  Future<void> deleteUser(int userId) async {
    requireAdmin();

    final userReference = await _user(userId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userReference);
      final user = snapshot.data();

      if (user == null) return;

      if (user['role'] != 'student') {
        throw StateError('Chỉ được xóa hồ sơ sinh viên.');
      }

      final roomId = user['pending_room_doc'] as String?;

      final roomReference = roomId == null
          ? null
          : collection('rooms').doc(roomId);

      final room = roomReference == null
          ? null
          : (await transaction.get(roomReference)).data();
      final rosterRef = roomReference == null
          ? null : collection('room_rosters').doc(roomReference.id);
      final roster = rosterRef == null
          ? null : (await transaction.get(rosterRef)).data();

      if (room != null && roomReference != null) {
        if (user['room_status'] == 'pending') {
          final requests =
              (room['active_requests'] as num?)?.toInt() ?? 0;

          if (requests < 1) {
            throw StateError(
              'Số đơn chờ của phòng không hợp lệ.',
            );
          }

          transaction.update(roomReference, {
            'active_requests': requests - 1,
          });
        }

        if (user['room_status'] == 'approved') {
          final occupancy =
              (room['current_occupancy'] as num).toInt();

          if (occupancy < 1) {
            throw StateError('Sĩ số phòng không hợp lệ.');
          }

          transaction.update(roomReference, {
            'current_occupancy': occupancy - 1,
          });
        }
      }

      if (user['room_status'] == 'approved' &&
          roomReference != null && room != null) {
        final members = _rosterMembers(roster)
          ..removeWhere((entry) => entry['username'] == userReference.id);
        transaction.set(
          rosterRef,
          _rosterData(roomReference.id, room, members),
        );
      }

      transaction.delete(userReference);
    });
  }

  Map<String, dynamic> _roomData(Room room) {
    return {
      'building_id': room.buildingId.trim(),
      'room_name': room.name.trim(),
      'label': roomLabel(room),
      'capacity': room.capacity,
      'type': room.roomType.trim(),
      'fixed_rent': room.fixedPrice,
    };
  }

  void _validateRoom(Room room) {
    if (room.name.trim().isEmpty ||
        room.buildingId.trim().isEmpty) {
      throw StateError('Vui lòng nhập tên phòng và tòa nhà.');
    }

    if (room.capacity < 1) {
      throw StateError('Sức chứa phải lớn hơn 0.');
    }

    if (!room.fixedPrice.isFinite || room.fixedPrice < 0) {
      throw StateError('Giá phòng không hợp lệ.');
    }
  }

  Future<void> addRoom(Room room) async {
    requireAdmin();
    _validateRoom(room);

    room.name = room.name.trim();
    room.buildingId = room.buildingId.trim();

    final documentId = Uri.encodeComponent(
      '${room.buildingId}_${room.name}',
    );

    final reference = collection('rooms').doc(documentId);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (snapshot.exists) {
        throw StateError('Phòng đã tồn tại.');
      }

      transaction.set(reference, {
        ..._roomData(room),
        'current_occupancy': 0,
        'active_requests': 0,
      });
    });
  }

  Future<void> updateRoom(
    String documentId,
    Room room,
  ) async {
    requireAdmin();
    _validateRoom(room);

    room.name = room.name.trim();
    room.buildingId = room.buildingId.trim();

    final reference = collection('rooms').doc(documentId);

    await db.runTransaction((transaction) async {
      final old = (await transaction.get(reference)).data();

      if (old == null) {
        throw StateError('Phòng không còn tồn tại.');
      }

      final occupancy =
          (old['current_occupancy'] as num).toInt();

      final requests =
          (old['active_requests'] as num?)?.toInt() ?? 0;

      if (room.capacity < occupancy) {
        throw StateError(
          'Sức chứa không được nhỏ hơn số sinh viên đang ở.',
        );
      }

      if ((occupancy > 0 || requests > 0) &&
          old['label'] != roomLabel(room)) {
        throw StateError(
          'Không đổi tên hoặc tòa nhà khi phòng '
          'có sinh viên hay đơn chờ duyệt.',
        );
      }

      // Keep the room metadata in any existing sanitized roster.
      final rosterRef = collection('room_rosters').doc(documentId);
      final roster = (await transaction.get(rosterRef)).data();
      if (roster != null) {
        transaction.set(rosterRef, _rosterData(documentId, {
          ...old, ..._roomData(room),
        }, _rosterMembers(roster)));
      }
      transaction.update(reference, _roomData(room));
    });
  }

  Future<void> deleteRoom(String documentId) async {
    requireAdmin();

    final reference = collection('rooms').doc(documentId);

    await db.runTransaction((transaction) async {
      final room = (await transaction.get(reference)).data();

      if (room == null) return;

      final occupancy =
          (room['current_occupancy'] as num).toInt();

      final requests =
          (room['active_requests'] as num?)?.toInt() ?? 0;

      if (occupancy > 0 || requests > 0) {
        throw StateError(
          'Không thể xóa phòng đang có sinh viên '
          'hoặc đơn chờ duyệt.',
        );
      }

      transaction.delete(collection('room_rosters').doc(documentId));
      transaction.delete(reference);
    });
  }

  Future<void> updateRoomOccupancy(
    String roomName,
    int occupancy,
  ) async {
    throw StateError(
      'Sĩ số được cập nhật tự động khi duyệt hoặc trả phòng.',
    );
  }

  Future<void> createInvoice(Invoice invoice) async {
    requireAdmin();

    final amounts = [
      invoice.roomFee,
      invoice.electricityFee,
      invoice.waterFee,
    ];

    if (amounts.any(
      (value) => !value.isFinite || value < 0,
    )) {
      throw StateError('Số tiền không hợp lệ.');
    }

    if (invoice.month < 1 ||
        invoice.month > 12 ||
        invoice.year < 1) {
      throw StateError('Kỳ hóa đơn không hợp lệ.');
    }

    final reference = collection('invoices').doc(invoice.id);

    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (snapshot.exists) {
        throw StateError('Hóa đơn đã tồn tại.');
      }

      transaction.set(reference, invoice.toJson());
    });
  }

  Future<void> updateInvoiceStatus(
    String invoiceId,
    String status,
  ) async {
    requireAdmin();

    if (!['paid', 'unpaid'].contains(status)) {
      throw StateError('Trạng thái hóa đơn không hợp lệ.');
    }

    await collection('invoices').doc(invoiceId).update({
      'status': status,
    });
  }

  Future<void> deleteInvoice(String invoiceId) async {
    requireAdmin();

    await collection('invoices').doc(invoiceId).delete();
  }

  Future<void> createTicket(Ticket ticket) async {
    final auth = AuthController.instance;

    if (!auth.isLoggedIn) {
      throw StateError('Vui lòng đăng nhập.');
    }

    if (!auth.isAdmin &&
        (auth.currentUser.roomStatus != RoomStatus.approved ||
            ticket.roomName != auth.currentUser.pendingRoomName)) {
      throw StateError(
        'Bạn chưa được duyệt cư trú tại phòng này.',
      );
    }

    if (ticket.title.trim().isEmpty ||
        ticket.description.trim().isEmpty) {
      throw StateError('Vui lòng nhập nội dung báo cáo.');
    }

    await collection('tickets').doc(ticket.id).set({
      ...ticket.toJson(),
      'owner_username': auth.currentUser.username,
    });
  }

  Future<void> updateTicketStatus(
    String ticketId,
    String status,
  ) async {
    requireAdmin();

    if (![
      'pending',
      'processing',
      'completed',
    ].contains(status)) {
      throw StateError('Trạng thái sự cố không hợp lệ.');
    }

    await collection('tickets').doc(ticketId).update({
      'status': status,
    });
  }

  Future<void> deleteTicket(String ticketId) async {
    requireAdmin();

    await collection('tickets').doc(ticketId).delete();
  }
}