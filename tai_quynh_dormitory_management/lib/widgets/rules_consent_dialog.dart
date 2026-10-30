import 'package:flutter/material.dart';

import '../models/dormitory_rules.dart';

Future<bool> requestRulesConsent(BuildContext context) async {
  bool accepted = false;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Đọc và đồng ý nội quy'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(DormitoryRules.text),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: accepted,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Tôi đã đọc và đồng ý nội quy, '
                        'bao gồm mức phạt 50.000đ/lần.',
                      ),
                      onChanged: (value) {
                        setState(() => accepted = value == true);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Quay lại'),
              ),
              FilledButton(
                onPressed:
                    accepted ? () => Navigator.pop(context, true) : null,
                child: const Text('Đồng ý và đăng ký'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}