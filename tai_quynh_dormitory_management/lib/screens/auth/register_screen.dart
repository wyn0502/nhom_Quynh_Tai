import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';

/// Màn hình Đăng ký sinh viên mới & Chọn phòng ở nguyên bản từ Web gốc (Ảnh 2)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mssvController = TextEditingController();
  final _classNameController = TextEditingController();
  final _hometownController = TextEditingController();

  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (username.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Vui lòng điền đầy đủ các trường thông tin bắt buộc!'),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Vui lòng nhập mật khẩu!'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('Mật khẩu xác nhận không trùng khớp!'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthController.instance.register(
      username: username,
      password: password,
      email: _emailController.text.trim().isEmpty ? '$username@ktx.com' : _emailController.text.trim(),
      fullName: fullName,
      mssv: _mssvController.text.trim().isEmpty ? 'SV2026' : _mssvController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? '0988888888' : _phoneController.text.trim(),
      className: _classNameController.text.trim().isEmpty ? 'CNTT' : _classNameController.text.trim(),
      hometown: _hometownController.text.trim().isEmpty ? 'Hà Nội' : _hometownController.text.trim(),
      role: _selectedRole,
    );

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

        // Quay về trang gốc (hệ thống sẽ tự động chuyển vào MainNavigator)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  // Logo DOMITORY
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

                  const SizedBox(height: 22),

                  // Thẻ Đăng ký
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
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
                            'ĐĂNG KÝ',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Dropdown Vai trò
                        const Text('Vai trò tài khoản', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UserRole>(
                              value: _selectedRole,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: UserRole.student, child: Text('Sinh viên', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                DropdownMenuItem(value: UserRole.admin, child: Text('Quản trị viên (Admin)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRole = val);
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tên đăng nhập & Email
                        _buildInputField('Tên đăng nhập', 'Nhập tài khoản hoặc email', _usernameController, Icons.person_outline),
                        const SizedBox(height: 10),
                        _buildInputField('Địa chỉ Email', 'Nhập email của bạn', _emailController, Icons.email_outlined),

                        const SizedBox(height: 10),

                        // Mật khẩu
                        _buildInputField('Mật khẩu', 'Nhập mật khẩu', _passwordController, Icons.vpn_key_outlined, isPassword: true),
                        const SizedBox(height: 10),
                        _buildInputField('Xác nhận mật khẩu', 'Nhập lại mật khẩu', _confirmPasswordController, Icons.vpn_key_outlined, isPassword: true),

                        const SizedBox(height: 16),

                        // Phân cách thông tin hồ sơ
                        Text(
                          'THÔNG TIN HỒ SƠ NỘI TRÚ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: brandOrange,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Họ tên & Số điện thoại
                        _buildInputField('Họ và Tên', 'Họ và tên có dấu', _fullNameController, Icons.badge_outlined),
                        const SizedBox(height: 10),
                        _buildInputField('Số điện thoại', 'Số điện thoại di động', _phoneController, Icons.phone_outlined),

                        const SizedBox(height: 10),

                        // MSSV & Lớp
                        _buildInputField('Mã số sinh viên (MSSV)', 'Mã số sinh viên', _mssvController, Icons.numbers_outlined),
                        const SizedBox(height: 10),
                        _buildInputField('Lớp quản lý', 'Ví dụ: CNTT1', _classNameController, Icons.school_outlined),

                        const SizedBox(height: 10),

                        // Quê quán
                        _buildInputField('Quê quán', 'Tỉnh/Thành phố', _hometownController, Icons.location_on_outlined),

                        const SizedBox(height: 18),

                        // Nút Đăng ký hồ sơ
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                      Icon(Icons.how_to_reg_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'ĐĂNG KÝ HỒ SƠ',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                text: 'Đã có tài khoản? ',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                children: [
                                  TextSpan(
                                    text: 'Đăng nhập ngay',
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

  Widget _buildInputField(String label, String hint, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
