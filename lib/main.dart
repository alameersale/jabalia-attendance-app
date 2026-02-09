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
        systemNavigationBarColor: Color(0xFF0D9488),
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
        
        // إعدادات الثيم الاحترافي
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D9488),
            brightness: Brightness.light,
            primary: const Color(0xFF0D9488),
            secondary: const Color(0xFF14B8A6),
            surface: Colors.white,
            background: const Color(0xFFF8FAFC),
            error: const Color(0xFFDC2626),
          ),
          useMaterial3: true,
          
          // خط عربي احترافي
          textTheme: arabicTextTheme.copyWith(
            displayLarge: arabicTextTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            headlineLarge: arabicTextTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            headlineMedium: arabicTextTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            titleLarge: arabicTextTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            bodyLarge: arabicTextTheme.bodyLarge?.copyWith(
              color: const Color(0xFF475569),
            ),
            bodyMedium: arabicTextTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          
          // شريط التطبيق
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: const Color(0xFF0D9488),
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
              shadowColor: const Color(0xFF0D9488).withOpacity(0.4),
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
              color: const Color(0xFF1E293B),
            ),
          ),
          
          // حقول الإدخال
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelStyle: GoogleFonts.cairo(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            hintStyle: GoogleFonts.cairo(
              color: const Color(0xFF94A3B8),
            ),
            prefixIconColor: const Color(0xFF64748B),
            suffixIconColor: const Color(0xFF64748B),
          ),
          
          // شريط التنقل السفلي
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF0D9488),
            unselectedItemColor: const Color(0xFF94A3B8),
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
            backgroundColor: Color(0xFF0D9488),
            foregroundColor: Colors.white,
            elevation: 6,
            shape: CircleBorder(),
          ),
          
          // Chip Theme
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF1F5F9),
            selectedColor: const Color(0xFF0D9488).withOpacity(0.2),
            labelStyle: GoogleFonts.cairo(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // Divider
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            space: 1,
          ),
          
          // Progress Indicator
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF0D9488),
            linearTrackColor: Color(0xFFE2E8F0),
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
                    Color(0xFF0D9488),
                    Color(0xFF0F766E),
                    Color(0xFF115E59),
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
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        size: 70,
                        color: Color(0xFF0D9488),
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
