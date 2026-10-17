
abstract class BaseEntity<ID> {
  final ID id;
  String name;
  String description;

  BaseEntity({
    required this.id,
    required this.name,
    required this.description,
  });

  // Phương thức chung: Lấy thông tin
  String getInfo() {
    return 'ID: $id | Tên: $name | Mô tả: $description';
  }

  // Phương thức chung: Cập nhật mô tả
  void updateDescription(String newDescription) {
    description = newDescription;
  }

  // Generic Method
  void displayData<T>(T data) {
    print('Thông tin bổ sung: $data');
  }
}
