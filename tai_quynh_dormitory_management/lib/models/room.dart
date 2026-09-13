class Room {
  String buildingId;       
  String name;             
  int capacity;            
  int currentOccupancy;    
  String roomType;         
  double fixedPrice;       

  
  Room({
    required this.buildingId,
    required this.name,
    required this.capacity,
    this.currentOccupancy = 0, 
    required this.roomType,
    required this.fixedPrice,
  });

  
  bool hasAvailableBeds() {
    return currentOccupancy < capacity;
  }

  
  bool addOccupant() {
    if (hasAvailableBeds()) {
      currentOccupancy++;
      print('Đã xếp chỗ thành công vào phòng $name. Sĩ số: $currentOccupancy/$capacity');
      return true; 
    } else {
      print('Lỗi: Phòng $name đã đạt tối đa sức chứa ($capacity người).');
      return false; 
    }
  }

  
  bool removeOccupant() {
    if (currentOccupancy > 0) {
      currentOccupancy--;
      print('Một sinh viên đã rời phòng $name. Sĩ số: $currentOccupancy/$capacity');
      return true;
    } else {
      print('Lỗi: Phòng $name hiện đang trống, không thể giảm số lượng.');
      return false;
    }
  }
}