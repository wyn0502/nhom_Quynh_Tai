import 'package:flutter/material.dart';

import 'section_heading.dart';

class InputSpec {
  final String key;
  final String label;
  final Object? value;
  final bool required;
  final bool number;
  final bool integer;
  final bool enabled;
  final int lines;
  final double? min;
  final double? max;
  final Map<String, String>? options;

  const InputSpec(
    this.key,
    this.label, {
    this.value = '',
    this.required = true,
    this.number = false,
    this.integer = false,
    this.enabled = true,
    this.lines = 1,
    this.min,
    this.max,
    this.options,
  });
}

class AppUi {
  static const navy = Color(0xFF1E3A8A);
  static const orange = Color(0xFFF97316);
  static const green = Color(0xFF059669);
  static const red = Color(0xFFDC2626);

  static Widget card(
    BuildContext context, {
    required String title,
    IconData icon = Icons.info_outline,
    String badge = '',
    Color color = navy,
    required List<Widget> children,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            icon: icon,
            title: title,
            badge: badge,
            color: color,
          ),
          if (children.isNotEmpty) const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  static Widget badge(
    String text, {
    Color color = navy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget info(String label, Object? value) {
    final text = value?.toString().trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            text.isEmpty ? 'Chưa cập nhật' : text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget grid(
    List<Widget> children, {
    double minWidth = 145,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context)
            .scale(14) / 14;

        final effectiveWidth =
            minWidth * scale.clamp(1.0, 2.0);

        final columns = (constraints.maxWidth / effectiveWidth)
            .floor()
            .clamp(1, 4)
            .toInt();

        final width =
            (constraints.maxWidth - 12 * (columns - 1)) /
                columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) {
            return SizedBox(
              width: width,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  static Widget data<T>({
    required Stream<T> stream,
    required Widget Function(T value) builder,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Không thể tải dữ liệu. '
              'Kiểm tra kết nối và quyền Firebase.',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return builder(snapshot.data as T);
      },
    );
  }

  static void message(
    BuildContext context,
    String text, {
    bool error = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? red : green,
        content: Text(text),
      ),
    );
  }

  static String errorText(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }

    return 'Không thể hoàn tất thao tác. '
        'Kiểm tra kết nối và quyền truy cập.';
  }

  static Future<bool> run(
    BuildContext context,
    Future<void> Function() action, {
    String success = 'Đã lưu thay đổi.',
  }) async {
    try {
      await action();

      if (context.mounted && success.isNotEmpty) {
        message(context, success);
      }

      return true;
    } catch (error) {
      if (context.mounted) {
        message(
          context,
          errorText(error),
          error: true,
        );
      }

      return false;
    }
  }

  static Future<bool> confirm(
    BuildContext context,
    String text,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Xác nhận'),
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  child: const Text('Đồng ý'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<bool> form(
    BuildContext context, {
    required String title,
    required List<InputSpec> fields,
    required Future<void> Function(
      Map<String, dynamic> values,
    ) onSave,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return _EditorDialog(
              title: title,
              fields: fields,
              onSave: onSave,
            );
          },
        ) ??
        false;
  }

  static String money(num value) {
    final text = value.round().toString();

    final formatted = text.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return '$formatted đ';
  }

  static String today() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  static String status(String value) {
    const labels = {
      'none': 'Chưa đăng ký',
      'pending': 'Đang chờ duyệt',
      'approved': 'Đã được duyệt',
      'rejected': 'Đã từ chối',
      'paid': 'Đã thanh toán',
      'unpaid': 'Chưa thanh toán',
      'processing': 'Đang xử lý',
      'completed': 'Hoàn thành',
      'new': 'Mới',
      'used': 'Đang dùng',
      'broken': 'Hỏng',
      'low': 'Thấp',
      'medium': 'Trung bình',
      'high': 'Khẩn cấp',
    };

    return labels[value] ?? value;
  }
}

class _EditorDialog extends StatefulWidget {
  final String title;
  final List<InputSpec> fields;
  final Future<void> Function(
    Map<String, dynamic> values,
  ) onSave;

  const _EditorDialog({
    required this.title,
    required this.fields,
    required this.onSave,
  });

  @override
  State<_EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends State<_EditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(
          text: '${field.value ?? ""}',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  String? _validate(InputSpec field, String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return field.required ? 'Vui lòng nhập thông tin.' : null;
    }

    if (field.options != null &&
        !field.options!.containsKey(text)) {
      return 'Vui lòng chọn giá trị hợp lệ.';
    }

    if (field.number || field.integer) {
      final number = num.tryParse(text);

      if (number == null || !number.isFinite) {
        return 'Vui lòng nhập số hợp lệ.';
      }

      if (field.integer && number != number.round()) {
        return 'Vui lòng nhập số nguyên.';
      }

      if (field.min != null && number < field.min!) {
        return 'Giá trị tối thiểu: ${field.min}.';
      }

      if (field.max != null && number > field.max!) {
        return 'Giá trị tối đa: ${field.max}.';
      }
    }

    return null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final values = <String, dynamic>{};

      for (final field in widget.fields) {
        final text = _controllers[field.key]!.text.trim();

        if (field.integer) {
          values[field.key] = int.parse(text);
        } else if (field.number) {
          values[field.key] = double.parse(text);
        } else {
          values[field.key] = text;
        }
      }

      await widget.onSave(values);

      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = AppUi.errorText(error);
      });
    }
  }

  Widget _field(InputSpec field) {
    final controller = _controllers[field.key]!;

    if (field.options != null) {
      final options = field.options!;

      return DropdownButtonFormField<String>(
        value: options.containsKey(controller.text)
            ? controller.text
            : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: options.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(
              entry.value,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: _saving || !field.enabled
            ? null
            : (value) {
                controller.text = value ?? '';
              },
        validator: (value) => _validate(field, value),
      );
    }

    return TextFormField(
      controller: controller,
      enabled: !_saving && field.enabled,
      maxLines: field.lines,
      keyboardType: field.number || field.integer
          ? const TextInputType.numberWithOptions(
              decimal: true,
            )
          : field.lines > 1
              ? TextInputType.multiline
              : TextInputType.text,
      decoration: InputDecoration(
        labelText: field.label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: field.lines > 1,
      ),
      validator: (value) => _validate(field, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _field(field),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppUi.red,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? 'Đang lưu…' : 'Lưu',
          ),
        ),
      ],
    );
  }
}