import 'package:flutter_test/flutter_test.dart';
import 'package:tai_quynh_dormitory_management/models/attendance.dart';
import 'package:tai_quynh_dormitory_management/models/invoice.dart';
import 'package:tai_quynh_dormitory_management/models/room.dart';
import 'package:tai_quynh_dormitory_management/models/ticket.dart';
import 'package:tai_quynh_dormitory_management/models/user.dart';

void main() {
  Room room(int cap, int used) => Room(buildingId: 'A', name: '101', capacity: cap, currentOccupancy: used, roomType: 'Normal', fixedPrice: 500000);
  test('US03 full room rejects occupant', () { final r = room(6, 6); expect(r.addOccupant(), false); expect(r.availableBeds, 0); });
  test('US03 zero capacity rejects occupant', () { expect(room(0, 0).hasAvailableBeds(), false); });
  test('US05 empty room cannot remove occupant', () { expect(room(6, 0).removeOccupant(), false); });
  test('US05 add and remove respect capacity', () { final r = room(1, 0); expect(r.addOccupant(), true); expect(r.addOccupant(), false); expect(r.removeOccupant(), true); });
  test('US04 rejected student may reapply', () { final u = User(username:'sv1', email:'', role:UserRole.student, roomStatus:RoomStatus.rejected); expect(u.canRegisterRoom, true); });
  test('US04 approved student cannot reapply', () { final u = User(username:'sv1', email:'', role:UserRole.student, roomStatus:RoomStatus.approved); expect(u.canRegisterRoom, false); });
  test('US08 rejected manager cannot manage', () { final u = User(username:'mgr1', email:'', role:UserRole.buildingManager, managerStatus:ManagerStatus.rejected, managedBuildingId:'A'); expect(u.canManageBuilding, false); });
  test('US08 approved manager still requires building', () { final u = User(username:'mgr1', email:'', role:UserRole.buildingManager, managerStatus:ManagerStatus.approved); expect(u.canManageBuilding, false); });
  test('US06 room JSON roundtrip', () { final r = room(6,2); final c = Room.fromJson(r.toJson(), 'r1'); expect(c.capacity,6); expect(c.currentOccupancy,2); expect(c.id,'r1'); });
  test('US06 missing room numeric fields default zero', () { final r = Room.fromJson({'room_name':'101','building_id':'A'}); expect(r.capacity,0); expect(r.fixedPrice,0); });
  test('US07 password never serialized', () { expect(User(username:'sv1', email:'', password:'secret').toJson().containsKey('password'),false); });
  test('US09 zero padded day', () { expect(AttendanceClock.day(DateTime.utc(2026,1,2)), '2026-01-02'); });
  test('US09 Sunday maps to previous Monday', () { expect(AttendanceClock.monday(DateTime.utc(2026,11,1)), '2026-10-26'); });
  test('US09 Monday maps to itself', () { expect(AttendanceClock.monday(DateTime.utc(2026,11,2)), '2026-11-02'); });
  test('US10 fine numeric conversion', () { expect(ViolationEntry('v',{'fine_amount':25000.0}).fine,25000); });
  test('US10 missing fine defaults to zero', () { expect(ViolationEntry('v',{}).fine,0); });
  test('US10 sum two fine amounts', () { final v=[ViolationEntry('1',{'fine_amount':10000}),ViolationEntry('2',{'fine_amount':20000})]; expect(v.fold<int>(0,(a,b)=>a+b.fine),30000); });
  test('US11 ticket JSON roundtrip', () { final t=Ticket(id:'t',roomName:'Phong 101 - A',studentName:'Student',title:'Broken light',description:'Broken',urgency:'high',date:'2026-11-02'); final c=Ticket.fromJson(t.toJson(),'t'); expect(c.urgency,'high'); expect(c.roomName,t.roomName); });
  test('US11 ticket defaults', () { final t=Ticket.fromJson({'title':'Issue'}); expect(t.status,'pending'); expect(t.urgency,'medium'); });
  test('US12 invoice computed total', () { expect(Invoice.fromJson({'room_fee':600000,'electricity_fee':25000,'water_fee':15000}).totalAmount,640000); });
  test('US12 paid invoice period roundtrip', () { final i=Invoice(id:'i',roomName:'101',month:11,year:2026,roomFee:600000,electricityFee:25000,waterFee:15000,totalAmount:640000,status:'paid'); final c=Invoice.fromJson(i.toJson(),'i'); expect(c.month,11); expect(c.isPaid,true); });
  test('US12 empty fees default to zero', () { expect(Invoice.fromJson({'month':1,'year':2026}).totalAmount,0); });
}
