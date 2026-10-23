/// Model Thiết bị & Tài sản KTX phân bổ theo phòng (từ quan_ly_ktx.sql)
class RoomAsset {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final String status; // 'new', 'used', 'broken'

  const RoomAsset({
    required this.id,
    required this.name,
    required this.description,
    this.quantity = 1,
    this.status = 'new',
  });

  String get statusLabel {
    switch (status) {
      case 'new':
        return 'MỚI';
      case 'used':
        return 'ĐANG DÙNG';
      case 'broken':
        return 'HỎNG';
      default:
        return 'TỐT';
    }
  }
}
