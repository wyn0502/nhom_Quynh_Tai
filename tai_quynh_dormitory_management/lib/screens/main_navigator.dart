import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'room_screen.dart';
import 'user_screen.dart';
import 'invoice_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigatorState>();
    state?.setTab(index);
  }

  @override
  State<MainNavigator> createState() {
    return _MainNavigatorState();
  }
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  void setTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Danh sách 4 màn hình
  final List<Widget> _pages = [
    const HomeScreen(),
    RoomScreen(),
    UserScreen(),
    const InvoiceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color barBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color selectedColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    final Color unselectedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBg,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF64748B).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home_outlined, 0, isDark: isDark),
                  activeIcon: _buildNavIcon(Icons.home_rounded, 0, isActive: true, isDark: isDark),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.meeting_room_outlined, 1, isDark: isDark),
                  activeIcon: _buildNavIcon(Icons.meeting_room_rounded, 1, isActive: true, isDark: isDark),
                  label: 'Phòng KTX',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.people_outline_rounded, 2, isDark: isDark),
                  activeIcon: _buildNavIcon(Icons.people_rounded, 2, isActive: true, isDark: isDark),
                  label: 'Sinh viên',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.receipt_long_outlined, 3, isDark: isDark),
                  activeIcon: _buildNavIcon(Icons.receipt_long_rounded, 3, isActive: true, isDark: isDark),
                  label: 'Hóa đơn',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, {bool isActive = false, required bool isDark}) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.5) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          size: 24,
        ),
      );
    }
    return Icon(icon, size: 24);
  }
}
