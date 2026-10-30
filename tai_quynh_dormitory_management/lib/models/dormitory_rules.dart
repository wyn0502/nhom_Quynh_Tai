class DormitoryRules {
  static const version = '2026-10-30';
  static const defaultFine = 50000;

  static const violations = {
    'attendance': 'Không điểm danh đúng hạn / minh chứng không hợp lệ',
    'noise': 'Gây ồn, làm mất trật tự sau 22:00',
    'hygiene': 'Xả rác, không giữ vệ sinh phòng và khu vực chung',
    'property': 'Làm hư hỏng, tự ý tháo dỡ thiết bị ký túc xá',
    'room_transfer': 'Tự ý chuyển phòng hoặc cho người khác ở thay',
    'visitor': 'Đưa khách ở lại qua đêm khi chưa được phép',
  };

  static const text = '''NỘI QUY KÝ TÚC XÁ

1. Điểm danh mỗi ngày từ 22:00 đến trước 22:10 (giờ Việt Nam). Sinh viên đã được duyệt phòng phải tải ảnh rõ mặt bản thân đang ở trong phòng. Không nộp ảnh đúng hạn được tự động ghi nhận 1 lần vi phạm; ảnh không hợp lệ do người quản lý kiểm tra và ghi rõ lý do. Mỗi ngày chỉ tính một lần vi phạm điểm danh.

2. Giữ yên tĩnh sau 22:00. Không gây ồn, tụ tập làm ảnh hưởng người khác.

3. Giữ vệ sinh phòng, hành lang và khu vực chung; bỏ rác đúng nơi quy định.

4. Bảo quản tài sản, thiết bị được bàn giao; không làm hư hỏng hoặc tự ý tháo dỡ.

5. Không tự ý chuyển phòng, đổi chỗ hoặc cho người khác ở thay.

6. Không đưa khách ở lại qua đêm khi chưa được ban quản lý cho phép.

MỨC PHẠT: 50.000đ cho mỗi lần vi phạm các mục trên. Các vi phạm ngoài điểm danh phải được admin hoặc quản lý tòa xác nhận và ghi rõ sự việc. Tổng tiền phạt bằng số lần vi phạm × 50.000đ, thống kê theo tuần từ thứ Hai đến Chủ nhật. Sinh viên được xem từng khoản phạt và liên hệ ban quản lý khi cần đối soát.

QUẢN LÝ TÒA: Chỉ xem danh sách sinh viên và minh chứng thuộc tòa được giao; không chia sẻ ảnh hoặc thông tin sinh viên ra ngoài. Mỗi tòa tối đa 2 người quản lý, tài khoản phải được admin duyệt trước khi sử dụng. Kiểm tra ảnh trung thực, không ghi nhận trùng một sự việc.

Ảnh được dùng để đối soát điểm danh, không thay thế việc kiểm tra thực tế khi cần thiết. Việc tích đồng ý xác nhận bạn đã đọc và cam kết tuân thủ nội quy này.''';
}