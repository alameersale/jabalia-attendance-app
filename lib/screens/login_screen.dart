import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../main.dart';

/// صفحة تسجيل الدخول - مبنية من الصفر، حقول واضحة على أندرويد
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_usernameError != null || _passwordError != null) {
      setState(() {
        _usernameError = null;
        _passwordError = null;
      });
    }
  }

  Future<void> _login() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text;

    setState(() {
      _usernameError = user.isEmpty ? 'يرجى إدخال اسم المستخدم' : null;
      _passwordError = pass.isEmpty ? 'يرجى إدخال كلمة المرور' : null;
    });
    if (user.isEmpty || pass.isEmpty) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final success = await auth.login(user, pass);

    if (!success && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'فشل تسجيل الدخول', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// تزيين الحقل كما في الواجهة الرئيسية - يعمل على أندرويد
  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
    bool hasError = false,
  }) {
    final borderColor = hasError ? AppColors.danger : const Color(0xFFDDDDDD);
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.cairo(fontSize: 14, color: const Color(0xFF888888)),
      prefixIcon: Icon(prefixIcon, color: AppColors.primary, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_rounded, size: 44, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'الحضور والانصراف',
                  style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'بلدية جباليا النزلة',
                  style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 28),

                // بطاقة الدخول - بدون Form لتجنب ثيم الحقول على أندرويد
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.login_rounded, color: AppColors.primary, size: 26),
                            const SizedBox(width: 10),
                            Text(
                              'تسجيل الدخول',
                              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // حقل اسم المستخدم - TextField مع تزيين صريح
                        TextField(
                          controller: _usernameController,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          onChanged: (_) => _clearError(),
                          cursorColor: AppColors.primary,
                          style: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFF1A1A1A)),
                          decoration: _fieldDecoration(
                            hintText: 'البريد / الجوال / رقم الهوية',
                            prefixIcon: Icons.person_outline_rounded,
                            hasError: _usernameError != null,
                          ),
                        ),
                        if (_usernameError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _usernameError!,
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // حقل كلمة المرور
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          onChanged: (_) => _clearError(),
                          onSubmitted: (_) => _login(),
                          cursorColor: AppColors.primary,
                          style: GoogleFonts.cairo(fontSize: 16, color: const Color(0xFF1A1A1A)),
                          decoration: _fieldDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            hasError: _passwordError != null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF666666),
                                size: 22,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        if (_passwordError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _passwordError!,
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // زر الدخول
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login_rounded, size: 22),
                                          const SizedBox(width: 10),
                                          Text('تسجيل الدخول', style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('الإصدار 2.1.1', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
