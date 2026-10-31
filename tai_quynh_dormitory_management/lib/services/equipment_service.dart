import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../controllers/auth_controller.dart';
import '../models/room.dart';

class EquipmentService {
  final db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get stock =>
      db.collection('v2_inventory');

  CollectionReference<Map<String, dynamic>> get assets =>
      db.collection('v2_assets');

  CollectionReference<Map<String, dynamic>> get moves =>
      db.collection('v2_equipment_moves');

  String requestId() => moves.doc().id;

  String get uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  void staff() {
    if (uid.isEmpty ||
        !(AuthController.instance.isAdmin ||
            AuthController.instance.isBuildingManager)) {
      throw StateError(
        'Chỉ admin và quản lý tòa đã duyệt được quản lý thiết bị.',
      );
    }
  }

  Future<T> _transaction<T>(
    Future<T> Function(Transaction) action,
  ) async {
    StateError? domain;
    StackTrace? trace;

    try {
      return await db.runTransaction<T>((transaction) async {
        domain = null;
        trace = null;

        try {
          return await action(transaction);
        } on StateError catch (error, stack) {
          domain = error;
          trace = stack;
          rethrow;
        }
      });
    } catch (error, stack) {
      if (domain != null) {
        Error.throwWithStackTrace(domain!, trace ?? stack);
      }
      rethrow;
    }
  }

  Future<void> guardRoomDeletion(
    Room room,
    Future<void> Function() remove,
  ) async {
    Future<bool> occupied() async =>
        ((await db.collection('v2_rooms').doc(room.id).get())
                    .data()?['equipment_count'] as num? ??
                0) >
            0;

    if (await occupied()) {
      throw StateError(
        'Phòng còn thiết bị đã bàn giao. '
        'Hãy thu hồi hoặc thanh lý thiết bị trước khi xóa phòng.',
      );
    }

    try {
      await remove();
    } catch (error) {
      if (await occupied()) {
        throw StateError(
          'Phòng vừa được bàn giao thêm thiết bị. '
          'Hãy thu hồi trước khi xóa.',
        );
      }
      rethrow;
    }
  }

  Future<void> create(String name, String unit, int quantity) async {
    staff();

    if (!AuthController.instance.isAdmin) {
      throw StateError('Chỉ admin được thêm thiết bị.');
    }

    if (name.trim().isEmpty ||
        name.trim().length > 100 ||
        unit.trim().isEmpty ||
        unit.trim().length > 20 ||
        quantity < 0 ||
        quantity > 1000000) {
      throw StateError('Tên, đơn vị và số lượng thiết bị không hợp lệ.');
    }

    String key(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final reference = stock.doc(
      Uri.encodeComponent('${key(name)}|${key(unit)}'),
    );

    await _transaction((tx) async {
      if ((await tx.get(reference)).exists) {
        throw StateError(
          'Thiết bị này đã có trong kho. Hãy dùng nút Nhập thêm.',
        );
      }

      tx.set(reference, {
        'name': name.trim(),
        'unit': unit.trim(),
        'total': quantity,
        'available': quantity,
        'assigned': 0,
        'last_move_id': '',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> change({
    required String requestId,
    required String kind,
    required String inventoryId,
    required int quantity,
    Room? room,
  }) async {
    staff();

    if (quantity < 1 ||
        quantity > 1000000 ||
        ![
          'restock',
          'issue',
          'return',
          'damage',
          'repair',
          'dispose',
        ].contains(kind)) {
      throw StateError('Số lượng phải là số nguyên lớn hơn 0.');
    }

    final admin = AuthController.instance.isAdmin;

    if (['restock', 'dispose'].contains(kind) && !admin) {
      throw StateError('Thao tác này cần quyền admin.');
    }

    if (kind != 'restock' && room?.id == null) {
      throw StateError('Hãy chọn phòng nhận thiết bị.');
    }

    final stockRef = stock.doc(inventoryId);
    final moveRef = moves.doc(requestId);
    final assetId = room == null ? '' : '${room.id}|$inventoryId';
    final actorUid = uid;
    final actorName = AuthController.instance.currentUser.displayName;

    void verifyReceipt(Map<String, dynamic> receipt) {
      if (receipt['kind'] != kind ||
          receipt['inventory_id'] != inventoryId ||
          receipt['room_id'] != (room?.id ?? '') ||
          receipt['quantity'] != quantity ||
          receipt['actor_uid'] != actorUid) {
        throw StateError('Mã giao dịch đã dùng cho một thao tác khác.');
      }
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      Timestamp? observed;
      Object? observedRoomMove;

      try {
        await _transaction((tx) async {
          final receipt = (await tx.get(moveRef)).data();

          if (receipt != null) {
            verifyReceipt(receipt);
            return;
          }

          final inventory = (await tx.get(stockRef)).data();

          if (inventory == null) {
            throw StateError('Thiết bị không còn tồn tại.');
          }

          observed = inventory['updated_at'] as Timestamp?;

          Map<String, dynamic>? allocation;
          Map<String, dynamic>? currentRoom;

          if (room != null) {
            currentRoom = (await tx.get(
              db.collection('v2_rooms').doc(room.id),
            ))
                .data();

            allocation = (await tx.get(assets.doc(assetId))).data();

            if (currentRoom == null) {
              throw StateError('Phòng không còn tồn tại.');
            }

            observedRoomMove = currentRoom['last_equipment_move_id'];

            if (currentRoom['label'] != room.label) {
              throw StateError(
                'Thông tin phòng đã thay đổi. '
                'Hãy quay lại mở phòng để bàn giao.',
              );
            }

            if (!admin &&
                currentRoom['building_id'] !=
                    AuthController.instance.currentUser.managedBuildingId) {
              throw StateError(
                'Bạn chỉ được bàn giao trong tòa được phân công.',
              );
            }
          }

          var available = (inventory['available'] as num).toInt();
          var assigned = (inventory['assigned'] as num).toInt();
          var total = (inventory['total'] as num).toInt();
          var held = (allocation?['quantity'] as num?)?.toInt() ?? 0;
          var damaged =
              (allocation?['damaged_count'] as num?)?.toInt() ?? 0;

          switch (kind) {
            case 'restock':
              available += quantity;
              total += quantity;

            case 'issue':
              if (available < quantity) {
                throw StateError(
                  available == 0
                      ? 'Thiết bị đã hết kho.'
                      : 'Kho chỉ còn $available ${inventory['unit']}.',
                );
              }
              available -= quantity;
              assigned += quantity;
              held += quantity;

            case 'return':
              if (quantity > held - damaged) {
                throw StateError(
                  'Chỉ được thu hồi thiết bị đang tốt. '
                  'Thiết bị hỏng cần sửa hoặc chờ admin thanh lý.',
                );
              }
              held -= quantity;
              available += quantity;
              assigned -= quantity;

            case 'damage':
              if (quantity > held - damaged) {
                throw StateError(
                  'Số lượng hỏng vượt số thiết bị đang tốt trong phòng.',
                );
              }
              damaged += quantity;

            case 'repair':
              if (quantity > damaged) {
                throw StateError(
                  'Số lượng sửa vượt số thiết bị hỏng.',
                );
              }
              damaged -= quantity;

            case 'dispose':
              if (quantity > damaged) {
                throw StateError(
                  'Chỉ được thanh lý thiết bị đã ghi nhận hỏng.',
                );
              }
              held -= quantity;
              damaged -= quantity;
              assigned -= quantity;
              total -= quantity;
          }

          if (available < 0 ||
              assigned < 0 ||
              total != available + assigned ||
              total > 1000000000 ||
              damaged < 0 ||
              damaged > held) {
            throw StateError(
              'Dữ liệu thiết bị không khớp. Vui lòng liên hệ admin.',
            );
          }

          tx.update(stockRef, {
            'available': available,
            'assigned': assigned,
            'total': total,
            'last_move_id': requestId,
            'updated_at': FieldValue.serverTimestamp(),
          });

          if (room != null) {
            final ref = assets.doc(assetId);

            if (held == 0) {
              tx.delete(ref);
            } else {
              tx.set(ref, {
                'inventory_id': inventoryId,
                'room_id': room.id,
                'room_name': currentRoom!['label'],
                'building_id': currentRoom['building_id'],
                'name': inventory['name'],
                'unit': inventory['unit'],
                'quantity': held,
                'damaged_count': damaged,
                'status': damaged == held ? 'broken' : 'used',
                'description': 'Đang tốt: ${held - damaged} • Hỏng: $damaged',
                'last_move_id': requestId,
              });
            }
          }

          if (room != null) {
            final before =
                (currentRoom!['equipment_count'] as num?)?.toInt() ?? 0;

            final delta = kind == 'issue'
                ? quantity
                : (kind == 'return' || kind == 'dispose')
                    ? -quantity
                    : 0;

            if (before + delta < 0) {
              throw StateError(
                'Số lượng thiết bị của phòng không khớp. '
                'Hãy liên hệ admin.',
              );
            }

            tx.update(db.collection('v2_rooms').doc(room.id), {
              'equipment_count': before + delta,
              'last_equipment_move_id': requestId,
            });
          }

          tx.set(moveRef, {
            'inventory_id': inventoryId,
            'asset_id': assetId,
            'room_id': room?.id ?? '',
            'building_id': currentRoom?['building_id'] ?? '',
            'room_name': currentRoom?['label'] ?? '',
            'item_name': inventory['name'],
            'kind': kind,
            'quantity': quantity,
            'actor_uid': actorUid,
            'actor_name': actorName,
            'created_at': FieldValue.serverTimestamp(),
          });
        });

        return;
      } on FirebaseException catch (error) {
        // Chỉ thử lại khi xác nhận có cập nhật đồng thời trên máy chủ.
        if (error.code != 'permission-denied' || observed == null) {
          rethrow;
        }

        final confirmed = (await moveRef.get(
          const GetOptions(source: Source.server),
        ))
            .data();

        if (confirmed != null) {
          verifyReceipt(confirmed);
          return;
        }

        final latest = (await stockRef.get(
          const GetOptions(source: Source.server),
        ))
            .data();

        if (latest == null) rethrow;

        var conflict = latest['updated_at'] != observed;

        if (!conflict && room != null) {
          final freshRoom = (await db
                  .collection('v2_rooms')
                  .doc(room.id)
                  .get(const GetOptions(source: Source.server)))
              .data();

          conflict = freshRoom != null &&
              freshRoom['last_equipment_move_id'] != observedRoomMove;
        }

        if (!conflict) rethrow;

        if (attempt == 2) {
          throw StateError(
            'Kho hoặc phòng đang được cập nhật đồng thời. Hãy thử lại.',
          );
        }
      }
    }
  }
}