import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'room_screen.dart';
import 'user_screen.dart';
import 'invoice_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  static void switchToTab(BuildContext context, int index) {
    context
        .findAncestorStateOfType<_MainNavigatorState>()
        ?.setTab(index);
  }

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _index = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    RoomScreen(),
    UserScreen(),
    InvoiceScreen(),
  ];

  static const _labels = [
    'Trang chủ',
    'Phòng KTX',
    'Sinh viên',
    'Hóa đơn',
  ];

  static const _icons = [
    Icons.home_outlined,
    Icons.meeting_room_outlined,
    Icons.people_outline_rounded,
    Icons.receipt_long_outlined,
  ];

  static const _activeIcons = [
    Icons.home_rounded,
    Icons.meeting_room_rounded,
    Icons.people_rounded,
    Icons.receipt_long_rounded,
  ];

  void setTab(int value) {
    if (value < 0 || value >= _pages.length) return;

    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark;

    final activeColor = dark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1E3A8A);

    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Material(
        color: Theme.of(context).cardColor,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_pages.length, (index) {
                final selected = index == _index;

                final color = selected
                    ? activeColor
                    : const Color(0xFF94A3B8);

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: _labels[index],
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setTab(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? activeColor.withValues(
                                        alpha: 0.10,
                                      )
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Icon(
                                selected
                                    ? _activeIcons[index]
                                    : _icons[index],
                                color: color,
                                size: 23,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _labels[index],
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}