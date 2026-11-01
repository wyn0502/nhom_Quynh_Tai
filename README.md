# Domirtory Management

**Xây dựng ứng dụng quản lý ký túc xá**

Bài tập lớn học phần **Lập trình cho thiết bị di động**, lớp **N04**,
Đại học Phenikaa.

## Giới thiệu

Ứng dụng hỗ trợ quản lý phòng ở, sinh viên và các hoạt động trong
ký túc xá, phân quyền cho quản trị viên, quản lý tòa nhà và sinh viên.

## Thành viên và đóng góp

| STT | Họ và tên | Mã sinh viên | Công việc phụ trách | Đóng góp |
|---|---|---|---|---|
| 1 | Đặng Đức Tài | 24107665 | Phân tích yêu cầu, xây dựng User Stories; thiết kế đăng nhập, đăng ký và Home; xây dựng phân quyền, quản lý phòng, đăng ký và duyệt phòng; tích hợp, kiểm thử và sửa lỗi phần phụ trách. | 50% |
| 2 | Lò Tuấn Quỳnh | 24104502 | Thiết kế và kết nối Firebase; xây dựng quản lý tòa, điểm danh, thống kê vi phạm, hóa đơn, sự cố và thiết bị; kiểm thử phần phụ trách; phối hợp hoàn thiện báo cáo và demo. | 50% |

Hai thành viên cùng trao đổi yêu cầu, rà soát sản phẩm và chuẩn bị
nội dung bảo vệ bài tập lớn.

## Công nghệ

- Flutter và Dart.
- Firebase Authentication.
- Cloud Firestore.
- Các dịch vụ Firebase phục vụ lưu ảnh và xử lý điểm danh.
- Git và GitHub.

## Repository

https://github.com/wyn0502/nhom_Quynh_Tai
]633;E;printf '\\n## Cấu trúc thư mục\\n\\n';b6dde542-5d3d-409a-b7f3-253420ab033a]633;C
## Cấu trúc thư mục

Cấu trúc rút gọn đến ba cấp.

```text
nhom_Quynh_Tai/
|-- .devcontainer/
    |-- devcontainer.json
|-- .github/
    |-- workflows/
        |-- flutter-web.yml
|-- README.md
|-- tai_quynh_dormitory_management/
    |-- .gitignore
    |-- .metadata
    |-- README.md
    |-- android/
        |-- .gitignore
        |-- app/
        |-- build.gradle
        |-- gradle.properties
        |-- gradle/
        |-- settings.gradle
    |-- docs/
        |-- room-residents-manager-approval.md
    |-- firebase.json
    |-- firestore.indexes.json
    |-- firestore.rules
    |-- functions/
        |-- .gitignore
        |-- discipline.js
        |-- index.js
        |-- package-lock.json
        |-- package.json
        |-- service.js
        |-- test/
    |-- ios/
        |-- .gitignore
        |-- Flutter/
        |-- Runner.xcodeproj/
        |-- Runner.xcworkspace/
        |-- Runner/
    |-- lib/
        |-- app_theme.dart
        |-- controllers/
        |-- firebase_options.dart
        |-- main.dart
        |-- models/
        |-- role_palette.dart
        |-- screens/
        |-- services/
        |-- utils/
        |-- widgets/
    |-- pubspec.lock
    |-- pubspec.yaml
    |-- storage.rules
    |-- test/
        |-- models_test.dart
        |-- registration_and_sync_test.dart
        |-- widget_test.dart
    |-- web/
        |-- favicon.png
        |-- icons/
        |-- index.html
        |-- manifest.json
```
