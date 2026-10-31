import 'package:cloud_firestore/cloud_firestore.dart';

class DormDates {
  static DateTime vietnamNow() =>
      DateTime.now().toUtc().add(const Duration(hours: 7));

  static String date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String week(DateTime value) {
    final day = DateTime.utc(value.year, value.month, value.day);
    final start = day.subtract(Duration(days: day.weekday - 1));
    return '${date(start)} – ${date(start.add(const Duration(days: 6)))}';
  }

  static String instant(Object? value) {
    DateTime? parsed;
    if (value is Timestamp) parsed = value.toDate();
    if (value is DateTime) parsed = value;
    if (value is String) parsed = DateTime.tryParse(value);
    if (parsed == null) return 'Chưa có thời gian';

    final vn = parsed.toUtc().add(const Duration(hours: 7));
    return '${date(vn)} '
        '${vn.hour.toString().padLeft(2, '0')}:'
        '${vn.minute.toString().padLeft(2, '0')}';
  }
}