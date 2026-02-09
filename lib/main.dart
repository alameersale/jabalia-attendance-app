import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

// ألوان بلدية جباليا النزلة
class AppColors {
  // الألوان الأساسية
  static const Color primary = Color(0xFF1A5A4A);        // أخضر داكن
  static const Color primaryLight = Color(0xFF2D7A66);   // أخضر فاتح
  static const Color primaryDark = Color(0xFF0F3D32);    // أخضر غامق
  
  // اللون الثانوي (الذهبي)
  static const Color secondary = Color(0xFFC9A227);      // ذهبي
  static const Color secondaryLight = Color(0xFFE0B93D); // ذهبي فاتح
  static const Color accent = Color(0xFFD4AF37);         // ذهبي لامع
  
  // ألوان الحالة
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFF34CE57);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFE0A800);
  static const Color danger = Color(0xFFDC3545);
  static const Color dangerDark = Color(0xFFC82333);
  
  // ألوان محايدة
  static const Color gray50 = Color(0xFFF8F9FA);
  static const Color gray100 = Color(0xFFF1F3F5);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray300 = Color(0xFFDEE2E6);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray500 = Color(0xFFADB5BD);
  static const Color gray600 = Color(0xFF6C757D);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray900 = Color(0xFF212529);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database
  await DatabaseService.instance.database;
  
  // Initialize Notifications
  await NotificationService.instance.initialize();
  
  // Set orientation (mobile only)
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // استخدام خط Cairo العربي
    final arabicTextTheme = GoogleFonts.cairoTextTheme(
      ThemeData.light().textTheme,
    );
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp(
        title: 'حضور جباليا',
        debugShowCheckedModeBanner: false,
        
        // دعم RTL للعربية
        locale: const Locale('ar', 'PS'),
        supportedLocales: const [
          Locale('ar', 'PS'),
        ],
        
        // إعدادات الثيم الاحترافي - ألوان بلدية جباليا
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: Colors.white,
            background: AppColors.gray50,
            error: AppColors.danger,
          ),
          useMaterial3: true,
          
          // خط عربي احترافي
          textTheme: arabicTextTheme.copyWith(
            displayLarge: arabicTextTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
            headlineLarge: arabicTextTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
            headlineMedium: arabicTextTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
            titleLarge: arabicTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
            bodyLarge: arabicTextTheme.bodyLarge?.copyWith(
              color: AppColors.gray700,
            ),
            bodyMedium: arabicTextTheme.bodyMedium?.copyWith(
              color: AppColors.gray600,
            ),
          ),
          
          // شريط التطبيق
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          
          // تحسين مظهر الأزرار
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: AppColors.primary.withOpacity(0.4),
              textStyle: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // أزرار النص
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // تحسين مظهر البطاقات
          cardTheme: CardTheme(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          
          // تحسين مظهر الحوارات
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titleTextStyle: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          
          // حقول الإدخال
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.gray100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gray300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelStyle: GoogleFonts.cairo(
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: GoogleFonts.cairo(
              color: AppColors.gray500,
            ),
            prefixIconColor: AppColors.gray600,
            suffixIconColor: AppColors.gray600,
          ),
          
          // شريط التنقل السفلي
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.gray500,
            selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.cairo(),
            elevation: 8,
          ),
          
          // Snackbar
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentTextStyle: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Floating Action Button
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            shape: CircleBorder(),
          ),
          
          // Chip Theme
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.gray100,
            selectedColor: AppColors.primary.withOpacity(0.2),
            labelStyle: GoogleFonts.cairo(
              color: AppColors.gray700,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // Divider
          dividerTheme: const DividerThemeData(
            color: AppColors.gray300,
            thickness: 1,
            space: 1,
          ),
          
          // Progress Indicator
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.primary,
            linearTrackColor: AppColors.gray300,
          ),
        ),
        
        // تعيين اتجاه RTL
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.primaryDark,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // شعار متحرك
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          'https://jabalia.ps/social-media/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.access_time_filled_rounded,
                              size: 70,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // مؤشر التحميل
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // نص التحميل
                    Text(
                      'جاري التحميل...',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'بلدية جباليا النزلة',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
