import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/sync_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

class AppColors {
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark  = Color(0xFF0D47A1);
  static const Color secondary    = Color(0xFF26C6DA);
  static const Color success      = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color warning      = Color(0xFFFFC107);
  static const Color danger       = Color(0xFFD32F2F);
  static const Color gray50  = Color(0xFFF8F9FA);
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

  await DatabaseService.instance.database;
  await NotificationService.instance.initialize();

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  runApp(const JabaliaApp());
}

class JabaliaApp extends StatelessWidget {
  const JabaliaApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        supportedLocales: const [Locale('ar', 'PS')],

        // ثيم بسيط بدون GoogleFonts لضمان تصيير الحقول بشكل صحيح على أندرويد
        theme: ThemeData(
          useMaterial3: false,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: Colors.white,
            error: AppColors.danger,
          ),
          scaffoldBackgroundColor: AppColors.gray50,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
          ),
        ),

        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),

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
        // جاري التحقق من الجلسة المحفوظة
        if (auth.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.primaryDark,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_balance,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
