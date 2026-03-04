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

// ألوان التطبيق - درجات الأزرق
class AppColors {
  // الألوان الأساسية - أزرق
  static const Color primary = Color(0xFF1565C0);        // أزرق متوسط
  static const Color primaryLight = Color(0xFF42A5F5);   // أزرق فاتح
  static const Color primaryDark = Color(0xFF0D47A1);    // أزرق داكن
  
  // اللون الثانوي (سماوي)
  static const Color secondary = Color(0xFF26C6DA);      // سماوي
  static const Color secondaryLight = Color(0xFF80DEEA); // سماوي فاتح
  static const Color accent = Color(0xFF00BCD4);         // تركواز
  
  // ألوان الحالة
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFE0A800);
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerDark = Color(0xFFC62828);
  
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
        systemNavigationBarColor: AppColors.primaryDark,
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
        
        locale: const Locale('ar', 'PS'),
        supportedLocales: const [
          Locale('ar', 'PS'),
        ],
        
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
          useMaterial3: false,
          
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
          
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          cardTheme: CardTheme(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          
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
          
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.gray500,
            selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.cairo(),
            elevation: 8,
          ),
          
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
          
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            shape: CircleBorder(),
          ),
          
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
          
          dividerTheme: const DividerThemeData(
            color: AppColors.gray300,
            thickness: 1,
            space: 1,
          ),
          
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.primary,
            linearTrackColor: AppColors.gray300,
          ),
        ),
        
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
            backgroundColor: AppColors.primaryDark,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance_rounded,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    'جاري التحميل...',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
