
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Cấu hình Firebase được tạo bởi FlutterFire CLI
import 'firebase_options.dart';

// Điều hướng các màn hình của ứng dụng
import 'screens/main_navigator.dart';

// Khởi tạo Firebase
Future<void> main() async {
  // Đảm bảo Flutter được khởi tạo trước Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Kết nối Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Chạy ứng dụng
  runApp(const DormitoryApp());
}

// Ứng dụng quản lý ký túc xá
class DormitoryApp extends StatelessWidget {
  const DormitoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Ký túc xá',
      debugShowCheckedModeBanner: false,

      // Cấu hình giao diện chung
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),

      // Màn hình chính
      home: const MainNavigator(),
    );
  }
}
