/// Model Bản tin & Thông báo Ký túc xá (từ quan_ly_ktx.sql)
class Announcement {
  final String id;
  final String title;
  final String content;
  final String department; // 'Phòng Tài chính', 'Ban Cơ sở vật chất', 'Phòng Quản lý KTX'
  final String date;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.department,
    required this.date,
  });
}
