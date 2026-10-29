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

  String get label => 'Phòng $name - $buildingId';

  int get availableBeds {
    if (capacity <= 0) return 0;

    return (capacity - currentOccupancy)
        .clamp(0, capacity)
        .toInt();
  }

  bool hasAvailableBeds() {
    return capacity > 0 && currentOccupancy < capacity;
  }

  bool addOccupant() {
    if (!hasAvailableBeds()) return false;

    currentOccupancy++;
    return true;
  }

  bool removeOccupant() {
    if (currentOccupancy <= 0) return false;

    currentOccupancy--;
    return true;
  }

  factory Room.fromJson(
    Map<String, dynamic> json, [
    String? docId,
  ]) {
    return Room(
      id: docId ?? json['id']?.toString(),
      buildingId: json['building_id']?.toString() ?? '',
      name: json['room_name']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      currentOccupancy:
          (json['current_occupancy'] as num?)?.toInt() ?? 0,
      roomType: json['type']?.toString() ?? '',
      fixedPrice:
          (json['fixed_rent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'building_id': buildingId,
      'room_name': name,
      'label': label,
      'capacity': capacity,
      'current_occupancy': currentOccupancy,
      'type': roomType,
      'fixed_rent': fixedPrice,
    };
  }
}