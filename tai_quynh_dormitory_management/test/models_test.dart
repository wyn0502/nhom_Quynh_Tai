import 'package:flutter_test/flutter_test.dart';
import 'package:tai_quynh_dormitory_management/models/room.dart';
import 'package:tai_quynh_dormitory_management/models/user.dart';
import 'package:tai_quynh_dormitory_management/widgets/room_occupancy.dart';

void main() {
  test('Approved students have an active room', () {
    final student = User.fromJson({
      'username': 'sv001',
      'role': 'student',
      'room_status': 'approved',
      'pending_room_name': 'Phòng a102 - A',
    });

    expect(student.hasActiveRoom, isTrue);
    expect(student.canRegisterRoom, isFalse);
  });

  test('Pending students cannot register two rooms', () {
    final student = User.fromJson({
      'username': 'sv002',
      'role': 'student',
      'room_status': 'pending',
    });

    expect(student.hasPendingRoom, isTrue);
    expect(student.canRegisterRoom, isFalse);
  });

  test('Occupancy and available beds remain consistent', () {
    final room = Room(
      buildingId: 'A',
      name: 'a102',
      capacity: 6,
      currentOccupancy: 2,
      roomType: 'Thường',
      fixedPrice: 1000000,
    );
    expect(room.availableBeds, 4);
    expect(RoomOccupancy.ratio(room), closeTo(1 / 3, 0.001));
    expect(room.hasAvailableBeds(), isTrue);
  });

  test('Manager requires both approval and building assignment', () {
    final pending = User.fromJson({
      'username': 'mgr001',
      'role': 'buildingManager',
      'manager_status': 'pending',
      'managed_building_id': 'A',
    });
    final approved = User.fromJson({
      'username': 'mgr002',
      'role': 'buildingManager',
      'manager_status': 'approved',
      'managed_building_id': 'A',
    });

    expect(pending.canManageBuilding, isFalse);
    expect(approved.canManageBuilding, isTrue);
  });
}
