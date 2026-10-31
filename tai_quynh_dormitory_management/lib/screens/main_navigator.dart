import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../app_theme.dart';
import 'equipment_screen.dart';
import '../services/firestore_service.dart';
import '../widgets/app_ui.dart';
import 'home_screen.dart';
import 'room_screen.dart';
import 'user_screen.dart';
import 'invoice_screen.dart';
import 'attendance_screen.dart';
import 'managed_building_screen.dart';
import 'staff_activity_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  static void switchToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_MainNavigatorState>()?.setTab(index);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int index = 0;
  late Future<void> preparation;

  bool get manager => AuthController.instance.isBuildingManager;

  @override
  void initState() {
    super.initState();
    preparation = AuthController.instance.isAdmin
        ? FirestoreService().syncRoomRosters()
        : Future.value();
  }

  List<Widget> get pages => manager
      ? const [
          ManagedBuildingScreen(),
          AttendanceScreen(),
          StaffActivityScreen(tickets: true),
          StaffActivityScreen(),
        ]
      : const [
          HomeScreen(),
          RoomScreen(),
          UserScreen(),
          InvoiceScreen(),
          AttendanceScreen(),
        ];

  List<String> get labels => manager
      ? ['Tòa phụ trách', 'Điểm danh', 'Sự cố', 'Thông báo']
      : ['Trang chủ', 'Phòng KTX', 'Sinh viên', 'Hóa đơn', 'Điểm danh'];

  List<IconData> get icons => manager
      ? [
          Icons.apartment_outlined,
          Icons.fact_check_outlined,
          Icons.handyman_outlined,
          Icons.campaign_outlined,
        ]
      : [
          Icons.home_outlined,
          Icons.meeting_room_outlined,
          Icons.people_outline,
          Icons.receipt_long_outlined,
          Icons.fact_check_outlined,
        ];

  void setTab(int value) {
    if (value >= 0 && value < pages.length) {
      setState(() => index = value);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: preparation,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang cập nhật danh sách cư trú…'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppUi.errorText(snapshot.error!)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(
                          () => preparation =
                              FirestoreService().syncRoomRosters(),
                        ),
                        child: const Text('Thử lại đồng bộ'),
                      ),
                      TextButton(
                        onPressed: () => AuthController.instance.logout(),
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final home = !manager && index == 0;

          final navigation = MobileBottomBar(
            index: index,
            labels: labels,
            icons: icons,
            onSelect: setTab,
          );

          return Scaffold(
            body: !manager && index == 0
                ? Theme(
                    data: AppTheme.build(Theme.of(context).brightness),
                    child: pages[index],
                  )
                : pages[index],
            floatingActionButton:
                AuthController.instance.isAdmin && home
                    ? Theme(
                        data: AppTheme.build(
                          Theme.of(context).brightness,
                        ),
                        child: FloatingActionButton.extended(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EquipmentScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Kho thiết bị'),
                        ),
                      )
                    : null,
            bottomNavigationBar: home
                ? Theme(
                    data: AppTheme.build(Theme.of(context).brightness),
                    child: navigation,
                  )
                : navigation,
          );
        },
      );
}

class MobileBottomBar extends StatelessWidget {
  final int index;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelect;

  const MobileBottomBar({
    super.key,
    required this.index,
    required this.labels,
    required this.icons,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: List.generate(
            labels.length,
            (i) => NavigationDestination(
              icon: Icon(icons[i]),
              label: labels[i],
            ),
          ),
        ),
      );
}