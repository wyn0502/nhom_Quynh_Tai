import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import 'register_screen.dart';

/// Màn hình Đăng nhập hệ thống nguyên bản từ Website gốc (Ảnh 2)
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController(text: 'wyn05');
  final TextEditingController _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthController.instance.login(username, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(result.message)),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tông màu xanh Navy nhận diện nguyên bản từ Web gốc (Ảnh 2)
    final Color bgNavy = const Color(0xFF0F224A);
    final Color brandNavy = const Color(0xFF1E3A8A);
    final Color brandOrange = const Color(0xFFF97316);

    return Scaffold(
      backgroundColor: bgNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Logo KTX nguyên bản (DOMITORY + Chấm cam + KÝ TÚC XÁ SINH VIÊN)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'DOMITORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: brandOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'KÝ TÚC XÁ SINH VIÊN',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 2. Thẻ Đăng Nhập màu trắng
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Trường Tên đăng nhập
                        const Text(
                          'Tên đăng nhập',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: TextField(
                            controller: _usernameController,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
                              hintText: 'Nhập tài khoản hoặc email',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Trường Mật khẩu
                        const Text(
                          'Mật khẩu',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF64748B), size: 19),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 19,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintText: 'Nhập mật khẩu',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Quên mật khẩu & Trợ giúp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
                              label: const Text('Quên mật khẩu', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFF64748B)),
                              label: const Text('Trợ giúp!', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nút ĐĂNG NHẬP
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.login_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'ĐĂNG NHẬP',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Chuyển sang Đăng ký
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Chưa có tài khoản sinh viên? ',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                children: [
                                  TextSpan(
                                    text: 'Đăng ký tại đây',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: brandNavy,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
