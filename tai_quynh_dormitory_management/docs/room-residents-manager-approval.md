# Danh sách cư trú và duyệt quản lý tòa

## Sửa lỗi

- `functions/discipline.js` phải tồn tại vì `functions/index.js` và `functions/service.js` đều `require('./discipline')`. File trước đây bị đặt nhầm thành `iscipline.js`.
- Cloud Function `getRoomResidents` trả về `full_name` và `mssv` của sinh viên đã được duyệt. Không đọc trực tiếp toàn bộ tài liệu `v2_users` ở ứng dụng, tránh tiết lộ điện thoại, CCCD và các thông tin khác. Sinh viên đã đăng nhập được xem danh sách người ở phòng; quản lý tòa chỉ được xem phòng thuộc tòa được phân công.
- Màn hình **Phòng KTX** có mục **Sinh viên trong phòng** (nhấn để tải danh sách). Sinh viên chưa được duyệt không được tính.
- `reviewBuildingManager` ghi `v2_manager_assignments/{buildingId}` thông qua giao dịch khi admin duyệt lần đầu, giữ tối đa 2 quản lý mỗi tòa. Firestore **không có bảng giống SQL**: collection `v2_manager_assignments` xuất hiện sau lần ghi thành công đầu tiên, không cần tạo bảng trống trước.

## Triển khai lên dự án Firebase đang chạy

Thay đổi trên GitHub **không tự động triển khai** lên Cloud Functions hoặc Cloud Firestore. Sau khi merge:

```bash
cd tai_quynh_dormitory_management
npm --prefix functions ci
npm --prefix functions test
firebase use <firebase-project-id>
firebase deploy --only functions,firestore:rules,firestore:indexes
flutter pub get
flutter run
```

Cần đăng nhập Firebase CLI bằng tài khoản có quyền triển khai và xác minh `firebase use` đang trỏ đúng project. Đảm bảo Cloud Functions chạy ở vùng `asia-southeast1`, đúng với Flutter client.

## Kiểm tra thủ công

1. Admin mở **Duyệt quản lý tòa**, chọn tòa `A` và lưu. Xác minh `v2_users/{username}` có `manager_status: approved`, `managed_building_id: A`, đồng thời `v2_manager_assignments/A` có mảng `usernames`.
2. Duyệt người thứ hai cho tòa A thì thành công; duyệt người thứ ba phải bị từ chối với lỗi có ý nghĩa. Thu hồi quyền người đầu tiên rồi duyệt người thứ ba phải thành công.
3. Đăng nhập sinh viên, vào **Phòng KTX** và mở **Sinh viên trong phòng** tại phòng có người ở. Chỉ hiển thị họ tên và MSSV của các sinh viên đã được duyệt. Phòng trống hiển thị thông báo không có sinh viên.
4. Đăng nhập quản lý tòa được duyệt, kiểm tra **Tòa A** chỉ chứa cư dân tòa A.
5. Nếu xuất hiện lỗi `internal`, xem Firebase Functions logs của `reviewBuildingManager` hoặc `getRoomResidents` sau khi triển khai. Không thể xác nhận lỗi server đã hết chỉ từ việc sửa repo.

## Dữ liệu cũ

Nếu đã phân quyền quản lý tòa thủ công trong `v2_users` trước khi triển khai, cần đồng bộ các quản lý đó vào `v2_manager_assignments/{buildingId}` trước khi tiếp tục duyệt, tránh vượt giới hạn 2 người. Không tự ý tạo dữ liệu quản lý tòa giả.
