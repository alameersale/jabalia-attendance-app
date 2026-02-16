import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../providers/auth_provider.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // الحركات الرئيسية
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _formController;
  late AnimationController _fieldsController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;

  // حركة الشعار - سقوط مع ارتداد
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;

  // حركة العنوان
  late Animation<double> _titleSlide;
  late Animation<double> _titleOpacity;

  // حركة الشعار الفرعي
  late Animation<double> _subtitleScale;

  // حركة البطاقة
  late Animation<Offset> _formSlide;
  late Animation<double> _formOpacity;

  // حركة الحقول المتتابعة
  late Animation<double> _field1Animation;
  late Animation<double> _field2Animation;
  late Animation<double> _field3Animation;
  late Animation<double> _field4Animation;
  late Animation<double> _buttonAnimation;

  // حركة العائم
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // ====== 1. حركة الشعار - يسقط من فوق مع دوران وارتداد ======
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.85), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 15),
    ]).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _logoRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0.1), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // ====== 2. حركة العنوان - ينزلق من اليمين ======
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _titleSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: Curves.elasticOut,
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _subtitleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    // ====== 3. حركة بطاقة تسجيل الدخول - تنزلق من الأسفل ======
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.elasticOut,
    ));

    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // ====== 4. حركة الحقول المتتابعة - كل حقل يظهر واحد تلو الآخر ======
    _fieldsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _field1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    _field2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _field3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _field4Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fieldsController,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    // ====== 5. حركة الفقاعات العائمة ======
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _floatingController,
    );

    // ====== 6. حركة البريق (shimmer) ======
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  void _startAnimationSequence() async {
    // تسلسل الحركات البهلوانية
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _formController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _fieldsController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    _titleController.dispose();
    _formController.dispose();
    _fieldsController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!success && mounted) {
      HapticFeedback.mediumImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  auth.error ?? 'فشل تسجيل الدخول',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1976D2),
              Color(0xFF1E88E5),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ====== الفقاعات العائمة في الخلفية ======
            ...List.generate(12, (i) => _buildAnimatedBubble(i)),

            // ====== المحتوى الرئيسي ======
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isSmallScreen ? 12 : 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedHeader(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 32),
                      _buildAnimatedForm(isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12 : 20),
                      _buildAnimatedFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // الفقاعات المتحركة في الخلفية
  // ============================================
  Widget _buildAnimatedBubble(int index) {
    final random = math.Random(index * 42);
    final size = 15.0 + random.nextDouble() * 80;
    final startX = random.nextDouble();
    final startY = random.nextDouble();
    final speed = 0.5 + random.nextDouble() * 2.0;
    final phase = random.nextDouble() * math.pi * 2;

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final t = _floatingAnimation.value;

        return Positioned(
          left: screenSize.width * startX +
              math.sin(t * math.pi * 2 * speed + phase) * 30,
          top: screenSize.height * startY +
              math.cos(t * math.pi * 2 * speed + phase) * 25,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03 + random.nextDouble() * 0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // الشعار المتحرك مع الارتداد والدوران
  // ============================================
  Widget _buildAnimatedHeader(bool isSmallScreen) {
    return Column(
      children: [
        // الشعار مع حركة بهلوانية
        AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Opacity(
              opacity: _logoOpacity.value,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(_logoScale.value)
                  ..rotateZ(_logoRotation.value),
                child: child,
              ),
            );
          },
          child: Hero(
            tag: 'app_logo',
            child: Container(
              width: isSmallScreen ? 85 : 105,
              height: isSmallScreen ? 85 : 105,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 18),

        // العنوان مع حركة انزلاق
        AnimatedBuilder(
          animation: _titleController,
          builder: (context, child) {
            return Opacity(
              opacity: _titleOpacity.value,
              child: Transform.translate(
                offset: Offset(_titleSlide.value, 0),
                child: child,
              ),
            );
          },
          child: Text(
            'الحضور والانصراف',
            style: GoogleFonts.cairo(
              fontSize: isSmallScreen ? 24 : 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // الشعار الفرعي مع حركة تكبير
        AnimatedBuilder(
          animation: _titleController,
          builder: (context, child) {
            return Transform.scale(
              scale: _subtitleScale.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_city_rounded,
                  size: 18,
                  color: AppColors.secondaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'بلدية جباليا النزلة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.secondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // نموذج تسجيل الدخول المتحرك
  // ============================================
  Widget _buildAnimatedForm(bool isSmallScreen) {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        return Opacity(
          opacity: _formOpacity.value,
          child: SlideTransition(
            position: _formSlide,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 80,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: AnimatedBuilder(
            animation: _fieldsController,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان النموذج مع حركة
                  _buildStaggeredChild(
                    animation: _field1Animation,
                    child: Row(
                      children: [
                        // أيقونة مع حركة دوران
                        AnimatedBuilder(
                          animation: _fieldsController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _field1Animation.value * math.pi * 2,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.1),
                                  AppColors.primaryLight.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.login_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // معلومات الدخول
                  _buildStaggeredChild(
                    animation: _field1Animation,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.06),
                            AppColors.primaryLight.withOpacity(0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'سجل دخول بالبريد الإلكتروني أو رقم الجوال أو رقم الهوية',
                              style: GoogleFonts.cairo(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // حقل اسم المستخدم
                  _buildStaggeredChild(
                    animation: _field2Animation,
                    slideFromLeft: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اسم المستخدم',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          keyboardType: TextInputType.text,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: AppColors.gray900,
                          ),
                          decoration: InputDecoration(
                            hintText: 'البريد / الجوال / رقم الهوية',
                            hintStyle: GoogleFonts.cairo(
                              color: AppColors.gray500,
                              fontSize: 13,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.danger),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال اسم المستخدم';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // حقل كلمة المرور
                  _buildStaggeredChild(
                    animation: _field3Animation,
                    slideFromLeft: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كلمة المرور',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: AppColors.gray900,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.cairo(
                              color: AppColors.gray500,
                              letterSpacing: 3,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.gray600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.gray50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.danger),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال كلمة المرور';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // زر تسجيل الدخول مع حركة بهلوانية
                  _buildStaggeredChild(
                    animation: _buttonAnimation,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                    AppColors.primary,
                                  ],
                                  stops: [
                                    0.0,
                                    _shimmerController.value,
                                    1.0,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'جاري التحقق...',
                                            style: GoogleFonts.cairo(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login_rounded, size: 22),
                                          const SizedBox(width: 10),
                                          Text(
                                            'تسجيل الدخول',
                                            style: GoogleFonts.cairo(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================
  // حركة العناصر المتتابعة (Staggered)
  // ============================================
  Widget _buildStaggeredChild({
    required Animation<double> animation,
    required Widget child,
    bool slideFromLeft = false,
  }) {
    final slideOffset = slideFromLeft ? -50.0 : 50.0;
    
    return Transform.translate(
      offset: Offset(
        (1.0 - animation.value) * slideOffset,
        0,
      ),
      child: Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.8 + (animation.value * 0.2),
          child: child,
        ),
      ),
    );
  }

  // ============================================
  // التذييل المتحرك
  // ============================================
  Widget _buildAnimatedFooter() {
    return AnimatedBuilder(
      animation: _fieldsController,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1.0 - _buttonAnimation.value.clamp(0.0, 1.0)) * 30),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.secondaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  'الإصدار 2.1.1',
                  style: GoogleFonts.cairo(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '© ${DateTime.now().year} بلدية جباليا النزلة',
            style: GoogleFonts.cairo(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
