import 'package:flutter/material.dart';

void main() {
  runApp(const DormitoryApp());
}

class DormitoryApp extends StatelessWidget {
  // Sửa lại cú pháp key cho tương thích với Dart cũ
  const DormitoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Ký túc xá',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Đã xóa dòng useMaterial3: true gây lỗi
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  // Sửa lại cú pháp key
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ thống Quản lý Ký túc xá', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Ban Quản Lý"),
              accountEmail: const Text("admin@dormitory.edu.vn"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
              ),
              decoration: BoxDecoration(color: Colors.blue[800]),
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room),
              title: const Text('Quản lý Phòng'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Quản lý Sinh viên'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Quản lý Hóa đơn'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.domain, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Chào mừng đến với Bảng điều khiển!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Chọn chức năng ở menu bên trái để bắt đầu.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}