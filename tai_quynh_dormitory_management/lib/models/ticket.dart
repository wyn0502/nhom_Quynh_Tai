class Ticket {
  final String id;
  final String roomName;
  final String studentName;
  final String title;
  final String description;
  final String urgency; // 'low', 'medium', 'high'
  final String status; // 'pending', 'processing', 'completed'
  final String date;

  Ticket({
    required this.id,
    required this.roomName,
    required this.studentName,
    required this.title,
    required this.description,
    this.urgency = 'medium',
    this.status = 'pending',
    required this.date,
  });

  factory Ticket.fromJson(Map<String, dynamic> json, [String? id]) {
    return Ticket(
      id: id ?? json['id']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? 'Phòng B101',
      studentName: json['student_name']?.toString() ?? 'Sinh viên',
      title: json['title']?.toString() ?? 'Sự cố thiết bị',
      description: json['description']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      date: json['date']?.toString() ?? '25/06/2026',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_name': roomName,
      'student_name': studentName,
      'title': title,
      'description': description,
      'urgency': urgency,
      'status': status,
      'date': date,
    };
  }
}
