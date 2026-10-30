import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'room_screen.dart';
import 'user_screen.dart';
import 'invoice_screen.dart';
import 'attendance_screen.dart';
import 'managed_building_screen.dart';
import '../controllers/auth_controller.dart';

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

  bool get _manager => AuthController.instance.isBuildingManager;

  List<Widget> get _pages => _manager
      ? const [
          ManagedBuildingScreen(),
          AttendanceScreen(),
        ]
      : const [
          HomeScreen(),
          RoomScreen(),
          UserScreen(),
          InvoiceScreen(),
          AttendanceScreen(),
        ];

  List<String> get _labels => _manager
      ? const [
          'Tòa phụ trách',
          'Điểm danh',
        ]
      : const [
          'Trang chủ',
          'Phòng KTX',
          'Sinh viên',
          'Hóa đơn',
          'Điểm danh',
        ];

  List<IconData> get _icons => _manager
      ? const [
          Icons.apartment_outlined,
          Icons.fact_check_outlined,
        ]
      : const [
          Icons.home_outlined,
          Icons.meeting_room_outlined,
          Icons.people_outline_rounded,
          Icons.receipt_long_outlined,
          Icons.fact_check_outlined,
        ];

  List<IconData> get _activeIcons => _manager
      ? const [
          Icons.apartment,
          Icons.fact_check,
        ]
      : const [
          Icons.home_rounded,
          Icons.meeting_room_rounded,
          Icons.people_rounded,
          Icons.receipt_long_rounded,
          Icons.fact_check,
        ];

  void setTab(int value) {
    if (value < 0 || value >= _pages.length) return;

    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;

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
                                    ? activeColor.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
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