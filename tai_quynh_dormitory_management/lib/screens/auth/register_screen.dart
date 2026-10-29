import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color backgroundColor = Color(0xFF0F224A);
  static const Color brandNavy = Color(0xFF1E3A8A);
  static const Color brandOrange = Color(0xFFF97316);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mssvController = TextEditingController();
  final _classNameController = TextEditingController();
  final _hometownController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _mssvController.dispose();
    _classNameController.dispose();
    _hometownController.dispose();

    super.dispose();
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success
            ? const Color(0xFF059669)
            : const Color(0xFFEF4444),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final username =
        _usernameController.text.trim().toLowerCase();

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final mssv = _mssvController.text.trim();

    if (username.isEmpty || fullName.isEmpty || mssv.isEmpty) {
      _showMessage(
        'Vui lòng nhập tên đăng nhập, họ tên và mã số sinh viên.',
      );
      return;
    }

    if (!RegExp(r'^[a-z0-9_]{3,40}$').hasMatch(username)) {
      _showMessage(
        'Tên đăng nhập gồm 3–40 ký tự: '
        'chữ thường, số hoặc dấu gạch dưới.',
      );
      return;
    }

    if (username == 'admin') {
      _showMessage(
        'Tên đăng nhập này dành riêng cho quản trị viên.',
      );
      return;
    }

    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
            .hasMatch(email)) {
      _showMessage('Địa chỉ email không hợp lệ.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Mật khẩu xác nhận không trùng khớp.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthController.instance.register(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
        mssv: mssv,
        phone: _phoneController.text.trim(),
        className: _classNameController.text.trim(),
        hometown: _hometownController.text.trim(),
        role: UserRole.student,
      );

      if (!mounted) return;

      if (!result.success) {
        _showMessage(result.message);
        return;
      }

      _showMessage(
        result.message,
        success: true,
      );

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (_) {
      _showMessage(
        'Không thể đăng ký. Vui lòng kiểm tra kết nối.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 28,
              ),
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
                decoration: const BoxDecoration(
                  color: brandOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'KÝ TÚC XÁ SINH VIÊN',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool password = false,
    bool confirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
  }) {
    final visible = confirmPassword
        ? _showConfirmPassword
        : _showPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFCBD5E1),
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: !_isLoading,
            obscureText: password && !visible,
            autocorrect: false,
            enableSuggestions: !password,
            keyboardType: keyboardType,
            textInputAction: action,
            onSubmitted: action == TextInputAction.done
                ? (_) {
                    _handleRegister();
                  }
                : null,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: textSecondary,
                size: 18,
              ),
              suffixIcon: password
                  ? IconButton(
                      tooltip:
                          visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                if (confirmPassword) {
                                  _showConfirmPassword =
                                      !_showConfirmPassword;
                                } else {
                                  _showPassword = !_showPassword;
                                }
                              });
                            },
                      icon: Icon(
                        visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: textSecondary,
                      ),
                    )
                  : null,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 24,
                    ),
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
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Vai trò tài khoản',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 18,
                                color: brandNavy,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sinh viên',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: textSecondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInputField(
                          label: 'Tên đăng nhập *',
                          hint: 'Chữ thường, số hoặc dấu _',
                          controller: _usernameController,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Địa chỉ email liên hệ',
                          hint: 'Nhập email của bạn',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Mật khẩu *',
                          hint: 'Ít nhất 6 ký tự',
                          controller: _passwordController,
                          icon: Icons.vpn_key_outlined,
                          password: true,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Xác nhận mật khẩu *',
                          hint: 'Nhập lại mật khẩu',
                          controller: _confirmPasswordController,
                          icon: Icons.vpn_key_outlined,
                          password: true,
                          confirmPassword: true,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'THÔNG TIN HỒ SƠ NỘI TRÚ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: brandOrange,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Họ và tên *',
                          hint: 'Họ và tên có dấu',
                          controller: _fullNameController,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Số điện thoại',
                          hint: 'Số điện thoại di động',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Mã số sinh viên (MSSV) *',
                          hint: 'Nhập mã số sinh viên',
                          controller: _mssvController,
                          icon: Icons.numbers_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Lớp quản lý',
                          hint: 'Nhập lớp của bạn',
                          controller: _classNameController,
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildInputField(
                          label: 'Quê quán',
                          hint: 'Tỉnh/Thành phố',
                          controller: _hometownController,
                          icon: Icons.location_on_outlined,
                          action: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '* Thông tin bắt buộc',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandNavy,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 46),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                                : const Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Icon(
                                        Icons.how_to_reg_rounded,
                                        size: 18,
                                      ),
                                      Text(
                                        'ĐĂNG KÝ HỒ SƠ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text.rich(
                              TextSpan(
                                text: 'Đã có tài khoản? ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Đăng nhập ngay',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: brandNavy,
                                      decoration:
                                          TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
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