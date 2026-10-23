class Room {
  String? id;
  String buildingId;       
  String name;             
  int capacity;            
  int currentOccupancy;    
  String roomType;         
  double fixedPrice;       

  Room({
    this.id,
    required this.buildingId,
    required this.name,
    required this.capacity,
    this.currentOccupancy = 0, 
    required this.roomType,
    required this.fixedPrice,
  });

  int get availableBeds => (capacity - currentOccupancy).clamp(0, capacity);

  bool hasAvailableBeds() {
    return currentOccupancy < capacity;
  }

  bool addOccupant() {
    if (hasAvailableBeds()) {
      currentOccupancy++;
      return true; 
    } else {
      return false; 
    }
  }

  bool removeOccupant() {
    if (currentOccupancy > 0) {
      currentOccupancy--;
      return true; 
    } else {
      return false; 
    }
  }

  factory Room.fromJson(Map<String, dynamic> json, [String? docId]) {
    return Room(
      id: docId ?? json['id']?.toString(),
      buildingId: json['building_id']?.toString() ?? 'Tòa A',
      name: json['room_name']?.toString() ?? docId ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      currentOccupancy: (json['current_occupancy'] as num?)?.toInt() ?? 0,
      roomType: json['type']?.toString() ?? 'Thường',
      fixedPrice: (json['fixed_rent'] as num?)?.toDouble() ?? 1500000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'building_id': buildingId,
      'room_name': name,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'type': roomType,
      'fixed_rent': fixedPrice,
    };
  }
}