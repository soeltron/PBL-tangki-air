import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final themeService = ThemeService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    themeService.addListener(_onThemeUpdate);
  }

  void _onThemeUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await AuthService().login(
      _usernameController.text,
      _passwordController.text,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!success) {
        _errorMessage = AuthService().error ?? 'Email atau password salah';
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    themeService.removeListener(_onThemeUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeService.isDarkMode;
    final background = isDark
        ? const Color(0xFF090D16)
        : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF131C2E) : Colors.white;
    final field = isDark ? const Color(0xFF0D1424) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF24324A) : const Color(0xFFE2E8F0);
    final fieldBorder = isDark
        ? const Color(0xFF3B4D66)
        : const Color(0xFFCBD5E1);
    final primary = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondary = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final label = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final accent = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Water Drop Logo Icon in Polije Blue Theme
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF084B83), Color(0xFF022B42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'SIKAD - Monitoring Tandon',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masuk untuk mengakses sistem IoT tandon air',
                  style: TextStyle(color: secondary, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text(
                        'Email',
                        style: TextStyle(
                          color: label,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: field,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: fieldBorder),
                        ),
                        child: TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: primary),
                          decoration: InputDecoration(
                            hintText: 'Masukkan email',
                            hintStyle: TextStyle(color: secondary),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: accent,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Password',
                        style: TextStyle(
                          color: label,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: field,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: fieldBorder),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isLoading) _handleLogin();
                          },
                          style: TextStyle(color: primary),
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            hintStyle: TextStyle(color: secondary),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: accent,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: secondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Masuk Sistem SIKAD',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Gunakan akun yang terdaftar di server',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
