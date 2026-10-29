class Ticket {
  final String id;
  final String roomName;
  final String studentName;
  final String title;
  final String description;
  final String urgency;
  final String status;
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

  factory Ticket.fromJson(
    Map<String, dynamic> json, [
    String? id,
  ]) {
    return Ticket(
      id: id ?? json['id']?.toString() ?? '',
      roomName: json['room_name']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      urgency: json['urgency']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      date: json['date']?.toString() ?? '',
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