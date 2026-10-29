import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color backgroundColor = Color(0xFF0F224A);
  static const Color brandNavy = Color(0xFF1E3A8A);
  static const Color brandOrange = Color(0xFFF97316);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AuthController.instance.login(
        username,
        password,
      );

      if (!mounted) return;

      if (!result.success) {
        _showMessage(result.message);
      }

      // Khi đăng nhập thành công, DormitoryApp sẽ tự đổi
      // sang MainNavigator qua AuthController.
    } catch (_) {
      _showMessage(
        'Không thể đăng nhập. Vui lòng kiểm tra kết nối.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showHelp({bool forgotPassword = false}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            forgotPassword ? 'Quên mật khẩu' : 'Trợ giúp đăng nhập',
          ),
          content: Text(
            forgotPassword
                ? 'Vui lòng liên hệ ban quản lý ký túc xá để được '
                    'hỗ trợ đặt lại mật khẩu.\n\n'
                    'Ứng dụng hiện dùng tên đăng nhập cho tài khoản. '
                    'Chức năng tự đặt lại mật khẩu qua email chưa được triển khai.'
                : 'Sinh viên chọn “Đăng ký tại đây” để tạo tài khoản.\n\n'
                    'Sau khi đăng ký, đăng nhập bằng tên đăng nhập '
                    'và mật khẩu đã tạo.\n\n'
                    'Tài khoản quản trị viên được ban quản lý cấu hình '
                    'riêng, không đăng ký từ ứng dụng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
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

  Widget _buildInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool password = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
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
            obscureText: password && _obscurePassword,
            autocorrect: false,
            enableSuggestions: !password,
            textCapitalization: TextCapitalization.none,
            textInputAction:
                password ? TextInputAction.done : TextInputAction.next,
            autofillHints: [
              password ? AutofillHints.password : AutofillHints.username,
            ],
            onSubmitted: password
                ? (_) {
                    _handleLogin();
                  }
                : null,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: textSecondary,
                size: 20,
              ),
              suffixIcon: password
                  ? IconButton(
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: textSecondary,
                        size: 19,
                      ),
                    )
                  : null,
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
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
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
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
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'ĐĂNG NHẬP',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _buildInput(
                            label: 'Tên đăng nhập',
                            hint: 'Nhập tên đăng nhập',
                            controller: _usernameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildInput(
                            label: 'Mật khẩu',
                            hint: 'Nhập mật khẩu',
                            controller: _passwordController,
                            icon: Icons.vpn_key_outlined,
                            password: true,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            children: [
                              TextButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => _showHelp(
                                          forgotPassword: true,
                                        ),
                                icon: const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                label: const Text(
                                  'Quên mật khẩu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              TextButton.icon(
                                onPressed:
                                    _isLoading ? null : () => _showHelp(),
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                label: const Text(
                                  'Trợ giúp!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandNavy,
                                foregroundColor: Colors.white,
                                elevation: 0,
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
                                          Icons.login_rounded,
                                          size: 18,
                                        ),
                                        Text(
                                          'ĐĂNG NHẬP',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                              child: const Text.rich(
                                TextSpan(
                                  text: 'Chưa có tài khoản sinh viên? ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Đăng ký tại đây',
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