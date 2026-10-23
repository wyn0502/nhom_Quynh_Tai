import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigator.dart';

// Khởi tạo Firebase
Future<void> main() async {
  // Đảm bảo Flutter được khởi tạo trước Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Kết nối Firebase với xử lý ngoại lệ an toàn
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // Chạy ứng dụng
  runApp(const DormitoryApp());
}

// Ứng dụng quản lý ký túc xá hỗ trợ Phân quyền & Light / Dark Mode
class DormitoryApp extends StatelessWidget {
  const DormitoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeController.instance, AuthController.instance]),
      builder: (context, _) {
        return MaterialApp(
          title: 'DOMITORY - Ký Túc Xá Sinh Viên',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeController.instance.themeMode,

          // ===================================================================
          // LIGHT THEME (Giao diện Sáng - Brand Identity Web Gốc & Font Inter)
          // ===================================================================
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              primary: const Color(0xFF1E3A8A),
              secondary: const Color(0xFFF97316),
              surface: const Color(0xFFEEF2F8),
              brightness: Brightness.light,
            ),
            cardColor: Colors.white,
            scaffoldBackgroundColor: const Color(0xFFEEF2F8),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1E293B),
              elevation: 0,
            ),
          ),

          // ===================================================================
          // DARK THEME (Giao diện Tối & Font Inter)
          // ===================================================================
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              primary: const Color(0xFF3B82F6),
              secondary: const Color(0xFFF97316),
              surface: const Color(0xFF0F172A),
              brightness: Brightness.dark,
            ),
            cardColor: const Color(0xFF1E293B),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          // Điều hướng xác thực: Chưa đăng nhập -> LoginScreen, Đã đăng nhập -> MainNavigator
          home: AuthController.instance.isLoggedIn
              ? const MainNavigator()
              : const LoginScreen(),
        );
      },
    );
  }
}
