# Bản Spark: xem cư trú và duyệt quản lý tòa

Hai chức năng **danh sách sinh viên trong phòng** và **duyệt quản lý tòa**
đã được chuyển sang Firestore trực tiếp, không cần Cloud Functions / Blaze.

## Mô hình dữ liệu

- `v2_users/{username}`: hồ sơ riêng tư (role, room_status, pending_room_doc...).
- `v2_rooms/{roomId}`: phòng và sĩ số.
- `v2_room_rosters/{roomId}`: danh sách công khai tối thiểu, chỉ gồm
  `room_id`, `room_name`, `building_id`, `members` (username, full_name, mssv).
  Ứng dụng không tải hồ sơ sinh viên đầy đủ để hiển thị thẻ phòng.
- `v2_manager_assignments/{encodedBuildingId}`: phân công `usernames`
  tối đa hai người cho mỗi tòa, tạo tự động trong transaction khi admin duyệt.

## Triển khai và kiểm thử Flutter Web trong Codespaces

Trong thư mục `tai_quynh_dormitory_management`, dùng nhánh
`fix/room-residents-manager-approval` và kiểm tra đang trỏ tới đúng
project Firebase `ltmobile-89b11`.

```bash
git fetch origin
git switch fix/room-residents-manager-approval
git pull --ff-only origin fix/room-residents-manager-approval

flutter pub get
flutter test
flutter test -d chrome
flutter build web --release

firebase deploy --project ltmobile-89b11 --only firestore
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Mở mục **Ports** trên Codespaces, bật port 8080 và dùng URL được cung cấp
để test ứng dụng web (không cần triển khai Firebase Hosting).

## Kiểm thử chức năng

1. Admin mở tab **Phòng KTX**, nhấn biểu tượng đồng bộ
   (chỉ **một lần** sau khi chuyển sang bản Spark; không thực hiện trong lúc
   admin khác đang duyệt hoặc trả phòng). Bản ghi `v2_room_rosters` được tạo.
2. Sinh viên mở thẻ phòng **a102 - A** và mở danh sách người ở;
   chỉ thấy họ tên/MSSV của sinh viên đã duyệt, không thấy CCCD/điện thoại.
3. Admin duyệt thêm hoặc trả phòng; danh sách được cập nhật cùng giao dịch
   cập nhật sĩ số. Thử cả trường hợp phòng đã đầy.
4. Admin duyệt quản lý tòa A lần đầu: giao dịch tạo
   `v2_manager_assignments/A`. Duyệt người thứ hai thành công, người thứ ba
   bị từ chối. Thu hồi một người rồi duyệt lại.
5. Quản lý tòa A đăng nhập, chỉ thấy danh sách phòng và sinh viên tòa A.

**Giới hạn gói Spark:** các tính năng điểm danh tự động ban đêm, tải ảnh
minh chứng bảo mật và xử lý vi phạm vẫn dùng Cloud Functions nên *chưa chạy*
chỉ với Firestore. Không coi các tính năng này đã được sửa bằng bản Spark.
Bản Flutter Web cũng cần cấu hình Firebase Authentication Web (allowed domains).

Firestore là NoSQL: collection tự xuất hiện sau khi ghi tài liệu đầu tiên;
không cần tạo bảng trống trong Firebase Console.
