class Invoice {
  final String id;
  final String roomName;
  final int month;
  final int year;
  final double roomFee;
  final double electricityFee;
  final double waterFee;
  final double totalAmount;
  final String status; // 'unpaid', 'paid'
  final int? orderCode;

  Invoice({
    required this.id,
    required this.roomName,
    required this.month,
    required this.year,
    required this.roomFee,
    required this.electricityFee,
    required this.waterFee,
    required this.totalAmount,
    this.status = 'unpaid',
    this.orderCode,
  });

  bool get isPaid => status == 'paid';

  factory Invoice.fromJson(Map<String, dynamic> json, [String? id]) {
    final roomFee = (json['room_fee'] as num?)?.toDouble() ?? 1500000;
    final elec = (json['electricity_fee'] as num?)?.toDouble() ?? 450000;
    final water = (json['water_fee'] as num?)?.toDouble() ?? 150000;
    final total = (json['total_amount'] as num?)?.toDouble() ?? (roomFee + elec + water);

    return Invoice(
      id: id ?? json['id']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? 'Phòng B101',
      month: (json['month'] as num?)?.toInt() ?? 6,
      year: (json['year'] as num?)?.toInt() ?? 2026,
      roomFee: roomFee,
      electricityFee: elec,
      waterFee: water,
      totalAmount: total,
      status: json['status']?.toString() ?? 'unpaid',
      orderCode: (json['payos_order_code'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_name': roomName,
      'month': month,
      'year': year,
      'room_fee': roomFee,
      'electricity_fee': electricityFee,
      'water_fee': waterFee,
      'total_amount': totalAmount,
      'status': status,
      if (orderCode != null) 'payos_order_code': orderCode,
    };
  }
}
