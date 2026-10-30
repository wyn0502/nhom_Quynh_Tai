import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/auth_controller.dart';
import '../models/attendance.dart';
import '../models/dormitory_rules.dart';
import '../services/discipline_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';

import 'manager_approval_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final service = DisciplineService();

  DateTime _date = AttendanceClock.vietnamNow();

  late Stream<List<AttendanceEntry>> _attendance;
  late Stream<List<ViolationEntry>> _violations;
  late Stream<String?> _session;

  Timer? _timer;
  bool _busy = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadStreams();

    // Chỉ cập nhật giao diện.
    // Tính phạt tự động chạy ở máy chủ Firebase.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  void _loadStreams() {
    final day = AttendanceClock.day(_date);

    _attendance = service.attendance(day);
    _violations = service.violations(AttendanceClock.monday(_date));
    _session = service.session(day);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = AttendanceClock.vietnamNow();

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );

    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _loadStreams();
      });
    }
  }

  Future<void> _upload() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      if (service.hasPendingUpload) {
        await service.retrySubmission();

        if (mounted) {
          AppUi.message(context, 'Đã xác nhận gửi ảnh điểm danh.');
        }
        return;
      }

      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (photo == null || !mounted) return;

      final confirmed = await AppUi.confirm(
        context,
        'Gửi ảnh bạn đang ở trong phòng? '
        'Ảnh tối đa 2 MB. Mỗi ngày gửi một lần trước 22:10.',
      );

      if (!confirmed || !mounted) return;

      await service.submitPhoto(photo);

      if (mounted) {
        AppUi.message(
          context,
          'Đã gửi ảnh điểm danh, đang chờ quản lý kiểm tra.',
        );
      }
    } catch (error) {
      if (mounted) {
        AppUi.message(context, AppUi.errorText(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _viewPhoto(AttendanceEntry entry) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final bytes = await service.evidence(entry.id);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${entry.studentName} • ${entry.roomName}'),
          content: SizedBox(
            width: 600,
            child: InteractiveViewer(
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Text('Không thể hiển thị ảnh.');
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        AppUi.message(context, AppUi.errorText(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(AttendanceEntry entry, bool accept) async {
    if (accept) {
      final confirmed = await AppUi.confirm(
        context,
        'Xác nhận ảnh của ${entry.studentName} hợp lệ?',
      );

      if (!confirmed || !mounted) return;

      await AppUi.run(
        context,
        () => service.reviewEvidence(entry.id, accept: true),
        success: 'Đã xác nhận điểm danh.',
      );
    } else {
      await AppUi.form(
        context,
        title: 'Ảnh không hợp lệ — phạt 50.000đ',
        fields: const [
          InputSpec(
            'reason',
            'Lý do (5–500 ký tự)',
            lines: 3,
          ),
        ],
        onSave: (values) => service.reviewEvidence(
          entry.id,
          accept: false,
          reason: values['reason'] as String,
        ),
      );
    }
  }

  Future<void> _recordViolation() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final options = <String, String>{};

      if (AuthController.instance.isAdmin) {
        final users = await FirestoreService().getStudentsStream().first;

        for (final user in users) {
          if (user.hasActiveRoom) {
            options[user.username] =
                '${user.displayName} — ${user.pendingRoomName}';
          }
        }
      } else {
        for (final user in await service.managedResidents()) {
          options[user['username'] as String] =
              '${user['full_name']} — ${user['room_name']}';
        }
      }

      if (!mounted) return;

      if (options.isEmpty) {
        throw StateError(
          'Chưa có sinh viên được duyệt phòng trong phạm vi quản lý.',
        );
      }

      final requestId = 'event_${DateTime.now().microsecondsSinceEpoch}';

      await AppUi.form(
        context,
        title: 'Ghi nhận vi phạm — 50.000đ/lần',
        fields: [
          InputSpec(
            'username',
            'Sinh viên',
            options: options,
          ),
          InputSpec(
            'rule',
            'Hành vi vi phạm',
            options: Map.of(DormitoryRules.violations)
              ..remove('attendance'),
          ),
          const InputSpec(
            'note',
            'Mô tả sự việc (5–500 ký tự)',
            lines: 3,
          ),
        ],
        onSave: (values) => service.recordViolation(
          username: values['username'] as String,
          ruleId: values['rule'] as String,
          note: values['note'] as String,
          requestId: requestId,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppUi.message(context, AppUi.errorText(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _weeklySummary(List<ViolationEntry> violations) {
    final monday = AttendanceClock.monday(_date);

    final sunday = AttendanceClock.day(
      DateTime.parse(monday).add(const Duration(days: 6)),
    );

    final grouped = <String, List<ViolationEntry>>{};

    for (final entry in violations) {
      grouped.putIfAbsent(entry.username, () => []).add(entry);
    }

    final visible = grouped.entries.where(
      (entry) => '${entry.key} ${entry.value.first.studentName}'
          .toLowerCase()
          .contains(_search.toLowerCase()),
    );

    final total = violations.fold<int>(
      0,
      (sum, entry) => sum + entry.fine,
    );

    return AppUi.card(
      context,
      title: 'Vi phạm trong tuần',
      icon: Icons.receipt_long,
      badge: '$monday – $sunday',
      children: [
        Text(
          '${violations.length} lần • Tổng tiền phạt: ${AppUi.money(total)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (!AuthController.instance.isStudent)
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: const InputDecoration(
              labelText: 'Tìm sinh viên vi phạm',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        if (violations.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Chưa ghi nhận vi phạm trong tuần này.'),
          ),
        for (final group in visible)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '${group.value.first.studentName} (${group.key})',
            ),
            subtitle: Text(
              '${group.value.length} lần • '
              '${AppUi.money(group.value.fold<int>(
                0,
                (sum, item) => sum + item.fine,
              ))}',
            ),
            children: [
              for (final item in group.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item.day} • ${item.roomName}'),
                  subtitle: Text(
                    '${item.reason}\n${AppUi.money(item.fine)}',
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _sessionMessage(AsyncSnapshot<String?> snapshot) {
    if (snapshot.hasError) {
      return 'Không thể tải trạng thái phiên điểm danh.';
    }

    switch (snapshot.data) {
      case 'failed':
        return 'Phiên mở không thành công. Không tự tính phạt cho '
            'phiên này; vui lòng liên hệ ban quản lý.';
      case 'closed':
        return 'Đã chốt phiên điểm danh.';
      case 'open':
        return 'Danh sách cư trú đầu phiên đã được ghi nhận.';
      case 'opening':
        return 'Hệ thống đang mở phiên, vui lòng chờ.';
      default:
        return 'Chưa có phiên điểm danh cho ngày này. '
            'Chưa có phiên thì không tự tính phạt.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;
    final reviewer = auth.isAdmin || auth.isBuildingManager;
    final selectedToday =
        AttendanceClock.day(_date) == AttendanceClock.today;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm danh & Tiền phạt'),
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Duyệt quản lý tòa',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManagerApprovalScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Điểm danh: 22:00–22:10 mỗi ngày (giờ Việt Nam). '
            'Không nộp ảnh trước 22:10: tự động vi phạm. '
            'Mức phạt: 50.000đ/lần.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(AttendanceClock.day(_date)),
              ),
              if (reviewer)
                FilledButton.icon(
                  onPressed: _busy ? null : _recordViolation,
                  icon: const Icon(Icons.add),
                  label: const Text('Ghi nhận vi phạm'),
                ),
              TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nội quy ký túc xá'),
                      content: const SingleChildScrollView(
                        child: Text(DormitoryRules.text),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Xem nội quy'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppUi.data<List<ViolationEntry>>(
            stream: _violations,
            builder: _weeklySummary,
          ),
          AppUi.data<List<AttendanceEntry>>(
            stream: _attendance,
            builder: (entries) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điểm danh ngày ${AttendanceClock.day(_date)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<String?>(
                  stream: _session,
                  builder: (context, snapshot) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_sessionMessage(snapshot)),
                  ),
                ),
                if (entries.isEmpty)
                  Text(
                    auth.isStudent
                        ? 'Chưa có lượt điểm danh. Chỉ sinh viên đã '
                            'được duyệt phòng khi mở phiên mới có tên.'
                        : 'Chưa có sinh viên trong phiên điểm danh này.',
                  ),
                for (final entry in entries)
                  AppUi.card(
                    context,
                    title: entry.studentName,
                    badge: entry.statusLabel,
                    icon: Icons.fact_check_outlined,
                    children: [
                      AppUi.info('Phòng', entry.roomName),
                      if (entry.data['reason'] != null)
                        AppUi.info(
                          'Lý do vi phạm',
                          entry.data['reason'],
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (entry.hasEvidence)
                            OutlinedButton.icon(
                              onPressed:
                                  _busy ? null : () => _viewPhoto(entry),
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Xem minh chứng'),
                            ),
                          if (auth.isStudent &&
                              entry.status == 'awaiting' &&
                              selectedToday)
                            FilledButton.icon(
                              onPressed:
                                  !_busy && AttendanceClock.isOpen
                                      ? _upload
                                      : null,
                              icon: const Icon(Icons.upload),
                              label: Text(
                                _busy
                                    ? 'Đang gửi…'
                                    : service.hasPendingUpload
                                        ? 'Gửi lại xác nhận'
                                        : 'Tải ảnh điểm danh',
                              ),
                            ),
                          if (reviewer &&
                              entry.status == 'submitted') ...[
                            FilledButton(
                              onPressed:
                                  _busy ? null : () => _review(entry, true),
                              child: const Text('Ảnh hợp lệ'),
                            ),
                            OutlinedButton(
                              onPressed:
                                  _busy ? null : () => _review(entry, false),
                              child: const Text('Ảnh không hợp lệ'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}