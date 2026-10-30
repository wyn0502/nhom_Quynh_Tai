class AttendanceClock {
  static DateTime vietnamNow() =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  static String day(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String get today => day(vietnamNow());

  static String monday(DateTime date) =>
      day(DateTime.utc(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - 1)));

  static bool get isOpen {
    final time = vietnamNow();
    return time.hour == 22 && time.minute < 10;
  }
}

class AttendanceEntry {
  final String id;
  final Map<String, dynamic> data;

  AttendanceEntry(this.id, this.data);

  String get studentName => data['student_name']?.toString() ?? '';
  String get username => data['username']?.toString() ?? '';
  String get roomName => data['room_name']?.toString() ?? '';
  String get buildingId => data['building_id']?.toString() ?? '';
  String get status => data['status']?.toString() ?? 'awaiting';

  bool get hasEvidence => data['evidence_path'] != null;

  String get statusLabel =>
      const {
        'awaiting': 'Chưa gửi ảnh',
        'submitted': 'Chờ kiểm tra ảnh',
        'accepted': 'Điểm danh hợp lệ',
        'violation': 'Vi phạm',
      }[status] ??
      status;
}

class ViolationEntry {
  final String id;
  final Map<String, dynamic> data;

  ViolationEntry(this.id, this.data);

  String get username => data['username']?.toString() ?? '';

  String get studentName =>
      data['student_name']?.toString() ?? username;

  String get roomName => data['room_name']?.toString() ?? '';
  String get day => data['day']?.toString() ?? '';
  String get reason => data['reason']?.toString() ?? '';

  int get fine => (data['fine_amount'] as num?)?.toInt() ?? 0;
}