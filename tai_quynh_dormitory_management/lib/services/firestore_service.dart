import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/auth_controller.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/invoice.dart';
import '../models/ticket.dart';
import '../models/asset.dart';
import '../models/announcement.dart';

class FirestoreService {
  static final FirestoreService _instance =
      FirestoreService._();

  factory FirestoreService() => _instance;

  FirestoreService._();

  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(
    String name,
  ) {
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
    return collection('rooms').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((document) {
          return Room.fromJson(
            document.data(),
            document.id,
          );
        }).toList();
      },
    );
  }

  Stream<List<User>> getStudentsStream() {
    return collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((document) {
          return User.fromJson(document.data());
        }).toList();
      },
    );
  }

  Stream<List<User>> getRoommatesStream(
    String roomName,
  ) {
    return collection('users')
        .where('room_status', isEqualTo: 'approved')
        .where(
          'pending_room_name',
          isEqualTo: roomName,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((document) {
          return User.fromJson(document.data());
        }).toList();
      },
    );
  }

  Stream<List<Invoice>> getInvoicesStream({
    String? roomName,
  }) {
    final auth = AuthController.instance;

    if (!auth.isAdmin &&
        auth.currentUser.roomStatus !=
            RoomStatus.approved) {
      return Stream.value(<Invoice>[]);
    }

    Query<Map<String, dynamic>> query =
        collection('invoices');

    if (roomName != null) {
      query = query.where(
        'room_name',
        isEqualTo: roomName,
      );
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((document) {
          return Invoice.fromJson(
            document.data(),
            document.id,
          );
        }).toList();
      },
    );
  }

  Stream<List<Ticket>> getTicketsStream({
    String? roomName,
  }) {
    final auth = AuthController.instance;

    if (!auth.isAdmin &&
        auth.currentUser.roomStatus !=
            RoomStatus.approved) {
      return Stream.value(<Ticket>[]);
    }

    Query<Map<String, dynamic>> query =
        collection('tickets');

    if (roomName != null) {
      query = query.where(
        'room_name',
        isEqualTo: roomName,
      );
    }

    return query.snapshots().map(
      (snapshot) {
        return snapshot.docs.map((document) {
          return Ticket.fromJson(
            document.data(),
            document.id,
          );
        }).toList();
      },
    );
  }

  Stream<List<Announcement>>
      getAnnouncementsStream() {
    return collection('announcements')
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((document) {
          final data = document.data();

          return Announcement(
            id: document.id,
            title: data['title']?.toString() ?? '',
            content:
                data['content']?.toString() ?? '',
            department:
                data['department']?.toString() ?? '',
            date: data['date']?.toString() ?? '',
          );
        }).toList();
      },
    );
  }

  Stream<List<RoomAsset>> getRoomAssetsStream(
    String roomName,
  ) {
    return collection('assets')
        .where(
          'room_name',
          isEqualTo: roomName,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((document) {
          final data = document.data();

          return RoomAsset(
            id: document.id,
            name: data['name']?.toString() ?? '',
            description:
                data['description']?.toString() ?? '',
            quantity:
                (data['quantity'] as num?)
                        ?.toInt() ??
                    0,
            status:
                data['status']?.toString() ?? 'used',
          );
        }).toList();
      },
    );
  }

  Future<DocumentReference<Map<String, dynamic>>>
      _user(int userId) async {
    final auth = AuthController.instance;

    if (auth.isLoggedIn &&
        auth.currentUser.id == userId) {
      return collection('users').doc(
        auth.currentUser.username,
      );
    }

    requireAdmin();

    final snapshot = await collection('users')
        .where('id', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError(
        'Không tìm thấy sinh viên.',
      );
    }

    return snapshot.docs.first.reference;
  }

  Future<DocumentReference<Map<String, dynamic>>>
      _room(String label) async {
    final snapshot = await collection('rooms')
        .where('label', isEqualTo: label)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError(
        'Phòng không còn tồn tại.',
      );
    }

    return snapshot.docs.first.reference;
  }

  Future<void> _sync(
    DocumentReference<Map<String, dynamic>>
        reference,
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
        auth.isAdmin ||
        auth.currentUser.id != userId) {
      throw StateError(
        'Không có quyền đăng ký phòng.',
      );
    }

    final userReference = collection('users').doc(
      auth.currentUser.username,
    );

    final roomReference = await _room(roomName);

    await db.runTransaction((transaction) async {
      final userSnapshot =
          await transaction.get(userReference);

      final roomSnapshot =
          await transaction.get(roomReference);

      final user = userSnapshot.data();
      final room = roomSnapshot.data();

      if (user == null || room == null) {
        throw StateError(
          'Không tìm thấy hồ sơ hoặc phòng.',
        );
      }

      final status = user['room_status'];

      if (status == 'pending' ||
          status == 'approved') {
        throw StateError(
          'Bạn đã đăng ký phòng. '
          'Vui lòng chờ admin xử lý.',
        );
      }

      final occupancy =
          (room['current_occupancy'] as num)
              .toInt();

      final capacity =
          (room['capacity'] as num).toInt();

      if (occupancy >= capacity) {
        throw StateError('Phòng đã đầy.');
      }

      final requests =
          (room['active_requests'] as num?)
                  ?.toInt() ??
              0;

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
        'Trạng thái chờ duyệt được tạo '
        'khi sinh viên đăng ký.',
      );
    }

    final userReference = await _user(userId);

    final targetReference =
        roomName != null && roomName.isNotEmpty
            ? await _room(roomName)
            : null;

    await db.runTransaction((transaction) async {
      final userSnapshot =
          await transaction.get(userReference);

      final user = userSnapshot.data();

      if (user == null ||
          user['role'] != 'student') {
        throw StateError(
          'Không tìm thấy sinh viên hợp lệ.',
        );
      }

      final oldRoomId =
          user['pending_room_doc'] as String?;

      final oldRoomReference =
          oldRoomId == null
              ? null
              : collection('rooms').doc(oldRoomId);

      final newRoomReference =
          targetReference ?? oldRoomReference;

      final oldRoom =
          oldRoomReference == null
              ? null
              : (await transaction.get(
                  oldRoomReference,
                ))
                  .data();

      final newRoom =
          newRoomReference == null
              ? null
              : (await transaction.get(
                  newRoomReference,
                ))
                  .data();

      final oldStatus = user['room_status'];

      if (status == RoomStatus.approved) {
        if (newRoom == null ||
            newRoomReference == null) {
          throw StateError(
            'Chưa chọn phòng hợp lệ.',
          );
        }

        if (oldStatus == 'approved' &&
            oldRoomReference?.id ==
                newRoomReference.id) {
          return;
        }

        final occupancy =
            (newRoom['current_occupancy'] as num)
                .toInt();

        final capacity =
            (newRoom['capacity'] as num).toInt();

        if (occupancy >= capacity) {
          throw StateError(
            'Phòng đã đầy, không thể duyệt thêm.',
          );
        }
      }

      if (oldRoom != null &&
          oldRoomReference != null) {
        if (oldStatus == 'pending') {
          final requests =
              (oldRoom['active_requests'] as num?)
                      ?.toInt() ??
                  0;

          if (requests < 1) {
            throw StateError(
              'Số đơn chờ của phòng không hợp lệ.',
            );
          }

          transaction.update(
            oldRoomReference,
            {
              'active_requests': requests - 1,
            },
          );
        }

        if (oldStatus == 'approved') {
          final occupancy =
              (oldRoom['current_occupancy'] as num)
                  .toInt();

          if (occupancy < 1) {
            throw StateError(
              'Sĩ số phòng không hợp lệ.',
            );
          }

          transaction.update(
            oldRoomReference,
            {
              'current_occupancy': occupancy - 1,
            },
          );
        }
      }

      if (status == RoomStatus.approved) {
        final occupancy =
            (newRoom!['current_occupancy'] as num)
                .toInt();

        transaction.update(
          newRoomReference!,
          {
            'current_occupancy': occupancy + 1,
          },
        );
      }

      transaction.update(userReference, {
        'room_status': status.name,
        'room_id':
            status == RoomStatus.approved
                ? (roomId ?? 1)
                : null,
        'pending_room_doc':
            status == RoomStatus.approved
                ? newRoomReference!.id
                : null,
        'pending_room_name':
            status == RoomStatus.approved
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
      if (hometown != null)
        'hometown': hometown.trim(),
      if (className != null)
        'class_name': className.trim(),
    });

    await _sync(reference);
  }

  Future<void> deleteUser(int userId) async {
    requireAdmin();

    final userReference = await _user(userId);

    // Xóa hồ sơ và giải phóng phòng trong cùng transaction.
    await db.runTransaction((transaction) async {
      final snapshot =
          await transaction.get(userReference);

      final user = snapshot.data();

      if (user == null) return;

      if (user['role'] != 'student') {
        throw StateError(
          'Chỉ được xóa hồ sơ sinh viên.',
        );
      }

      final roomId =
          user['pending_room_doc'] as String?;

      final roomReference =
          roomId == null
              ? null
              : collection('rooms').doc(roomId);

      final room =
          roomReference == null
              ? null
              : (await transaction.get(
                  roomReference,
                ))
                  .data();

      if (room != null &&
          roomReference != null) {
        if (user['room_status'] == 'pending') {
          final requests =
              (room['active_requests'] as num?)
                      ?.toInt() ??
                  0;

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
              (room['current_occupancy'] as num)
                  .toInt();

          if (occupancy < 1) {
            throw StateError(
              'Sĩ số phòng không hợp lệ.',
            );
          }

          transaction.update(roomReference, {
            'current_occupancy': occupancy - 1,
          });
        }
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
      throw StateError(
        'Vui lòng nhập tên phòng và tòa nhà.',
      );
    }

    if (room.capacity < 1) {
      throw StateError(
        'Sức chứa phải lớn hơn 0.',
      );
    }

    if (!room.fixedPrice.isFinite ||
        room.fixedPrice < 0) {
      throw StateError(
        'Giá phòng không hợp lệ.',
      );
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

    final reference =
        collection('rooms').doc(documentId);

    await db.runTransaction((transaction) async {
      final snapshot =
          await transaction.get(reference);

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

    final reference =
        collection('rooms').doc(documentId);

    await db.runTransaction((transaction) async {
      final old =
          (await transaction.get(reference)).data();

      if (old == null) {
        throw StateError(
          'Phòng không còn tồn tại.',
        );
      }

      final occupancy =
          (old['current_occupancy'] as num)
              .toInt();

      final requests =
          (old['active_requests'] as num?)
                  ?.toInt() ??
              0;

      if (room.capacity < occupancy) {
        throw StateError(
          'Sức chứa không được nhỏ hơn '
          'số sinh viên đang ở.',
        );
      }

      if ((occupancy > 0 || requests > 0) &&
          old['label'] != roomLabel(room)) {
        throw StateError(
          'Không đổi tên hoặc tòa nhà khi phòng '
          'có sinh viên hay đơn chờ duyệt.',
        );
      }

      transaction.update(
        reference,
        _roomData(room),
      );
    });
  }

  Future<void> deleteRoom(
    String documentId,
  ) async {
    requireAdmin();

    final reference =
        collection('rooms').doc(documentId);

    await db.runTransaction((transaction) async {
      final room =
          (await transaction.get(reference)).data();

      if (room == null) return;

      final occupancy =
          (room['current_occupancy'] as num)
              .toInt();

      final requests =
          (room['active_requests'] as num?)
                  ?.toInt() ??
              0;

      if (occupancy > 0 || requests > 0) {
        throw StateError(
          'Không thể xóa phòng đang có sinh viên '
          'hoặc đơn chờ duyệt.',
        );
      }

      transaction.delete(reference);
    });
  }

  Future<void> updateRoomOccupancy(
    String roomName,
    int occupancy,
  ) async {
    throw StateError(
      'Sĩ số được cập nhật tự động '
      'khi duyệt hoặc trả phòng.',
    );
  }

  Future<void> createInvoice(
    Invoice invoice,
  ) async {
    requireAdmin();

    final amounts = [
      invoice.roomFee,
      invoice.electricityFee,
      invoice.waterFee,
    ];

    if (amounts.any(
      (value) => !value.isFinite || value < 0,
    )) {
      throw StateError(
        'Số tiền không hợp lệ.',
      );
    }

    if (invoice.month < 1 ||
        invoice.month > 12 ||
        invoice.year < 1) {
      throw StateError(
        'Kỳ hóa đơn không hợp lệ.',
      );
    }

    final reference =
        collection('invoices').doc(invoice.id);

    await db.runTransaction((transaction) async {
      final snapshot =
          await transaction.get(reference);

      if (snapshot.exists) {
        throw StateError(
          'Hóa đơn đã tồn tại.',
        );
      }

      transaction.set(
        reference,
        invoice.toJson(),
      );
    });
  }

  Future<void> updateInvoiceStatus(
    String invoiceId,
    String status,
  ) async {
    requireAdmin();

    if (!['paid', 'unpaid'].contains(status)) {
      throw StateError(
        'Trạng thái hóa đơn không hợp lệ.',
      );
    }

    await collection('invoices')
        .doc(invoiceId)
        .update({
      'status': status,
    });
  }

  Future<void> deleteInvoice(
    String invoiceId,
  ) async {
    requireAdmin();

    await collection('invoices')
        .doc(invoiceId)
        .delete();
  }

  Future<void> createTicket(
    Ticket ticket,
  ) async {
    final auth = AuthController.instance;

    if (!auth.isLoggedIn) {
      throw StateError(
        'Vui lòng đăng nhập.',
      );
    }

    if (!auth.isAdmin &&
        (auth.currentUser.roomStatus !=
                RoomStatus.approved ||
            ticket.roomName !=
                auth.currentUser.pendingRoomName)) {
      throw StateError(
        'Bạn chưa được duyệt cư trú '
        'tại phòng này.',
      );
    }

    if (ticket.title.trim().isEmpty ||
        ticket.description.trim().isEmpty) {
      throw StateError(
        'Vui lòng nhập nội dung báo cáo.',
      );
    }

    await collection('tickets')
        .doc(ticket.id)
        .set({
      ...ticket.toJson(),
      'owner_username':
          auth.currentUser.username,
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
      throw StateError(
        'Trạng thái sự cố không hợp lệ.',
      );
    }

    await collection('tickets')
        .doc(ticketId)
        .update({
      'status': status,
    });
  }

  Future<void> deleteTicket(
    String ticketId,
  ) async {
    requireAdmin();

    await collection('tickets')
        .doc(ticketId)
        .delete();
  }
}