import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/discipline_service.dart';
import 'app_ui.dart';

/// Loads only when expanded; users never read private student profiles.
class RoomResidentsTile extends StatefulWidget {
  final Room room;

  const RoomResidentsTile({
    super.key,
    required this.room,
  });

  @override
  State<RoomResidentsTile> createState() => _RoomResidentsTileState();
}

class _RoomResidentsTileState extends State<RoomResidentsTile> {
  Future<List<Map<String, dynamic>>>? _residents;

  void _load() {
    final id = widget.room.id;
    if (id == null) return;

    setState(() {
      _residents = DisciplineService().roomResidents(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: PageStorageKey<String>('room_residents_${widget.room.id}'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: const Icon(Icons.people_outline),
      title: const Text('Sinh viên trong phòng'),
      onExpansionChanged: (expanded) {
        if (expanded && _residents == null) _load();
      },
      children: [
        if (_residents != null)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _residents,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppUi.errorText(snapshot.error!),
                      style: const TextStyle(color: AppUi.red),
                    ),
                    TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final students = snapshot.data!;
              if (students.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Chưa có sinh viên được duyệt vào phòng.'),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${students.length} sinh viên đang ở'),
                  for (final student in students)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        student['full_name']?.toString() ?? '',
                      ),
                      subtitle: (student['mssv']?.toString() ?? '').isEmpty
                          ? null
                          : Text('MSSV: ${student['mssv']}'),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
