class Invoice {
  final String id;
  final String roomName;
  final int month;
  final int year;
  final double roomFee;
  final double electricityFee;
  final double waterFee;
  final double totalAmount;
  final String status;
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

  factory Invoice.fromJson(
    Map<String, dynamic> json, [
    String? id,
  ]) {
    final roomFee =
        (json['room_fee'] as num?)?.toDouble() ?? 0;

    final electricityFee =
        (json['electricity_fee'] as num?)?.toDouble() ?? 0;

    final waterFee =
        (json['water_fee'] as num?)?.toDouble() ?? 0;

    return Invoice(
      id: id ?? json['id']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? '',
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      roomFee: roomFee,
      electricityFee: electricityFee,
      waterFee: waterFee,
      totalAmount:
          (json['total_amount'] as num?)?.toDouble() ??
              roomFee + electricityFee + waterFee,
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