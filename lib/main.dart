// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

// Colors
import 'providers/app_colors.dart';

// Providers
// CORRECTED: Imported the new ThemeProvider for state management
import 'providers/theme_provider.dart'; 
import 'providers/user_provider.dart';
import 'providers/app_lock_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/call_log_provider.dart';
import 'providers/display_settings_provider.dart';

// Services
import 'services/auth_service.dart';
import 'services/database_helper.dart';

// Screens
import 'auth_wrapper.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'permissions_screen.dart';
import 'home_page.dart';
import 'app_lock_screen.dart';
import 'settings_screen.dart';
import 'settings/account_settings_screen.dart';
import 'settings/change_name_screen.dart';
import 'settings/profile_photo_screen.dart';
import 'settings/password.dart';
import 'settings/usage_access_screen.dart';
import 'settings/panic_button_settings_screen.dart';
import 'settings/uninstall_confirm_screen.dart';
import 'settings/merge_contacts_screen.dart';
import 'partner_call_history_screen.dart';
import 'phone/call_log_details_screen.dart';
import 'phone/display_options_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await DatabaseHelper().initDatabase();
  
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
          // CORRECTED: Used ThemeProvider which is a ChangeNotifier
          ChangeNotifierProvider(create: (_) => ThemeProvider()), 
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => AppLockProvider()),
          ChangeNotifierProvider(create: (_) => ContactsProvider()),
          ChangeNotifierProvider(create: (_) => DisplaySettingsProvider()),
          ChangeNotifierProxyProvider<UserProvider, CallLogProvider>(
            create: (context) => CallLogProvider(Provider.of<UserProvider>(context, listen: false)),
            update: (context, userProvider, previousCallLogProvider) {
              previousCallLogProvider?.updateUserProvider(userProvider);
              return previousCallLogProvider ?? CallLogProvider(userProvider);
            },
          ),
        ],
        child: const BondNexApp(),
      ),
    ),
  );
}

class BondNexApp extends StatelessWidget {
  const BondNexApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CORRECTED: Getting the instance of ThemeProvider from Provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'BondNex',
      debugShowCheckedModeBanner: false,
      // CORRECTED: Using the themeMode from the themeProvider instance
      themeMode: themeProvider.themeMode,

      // 🟢 LIGHT THEME - Premium Green & White
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: AppColors.lightColorScheme,
        scaffoldBackgroundColor: AppColors.offWhite,
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.offWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Text Theme
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          titleSmall: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
          bodySmall: GoogleFonts.poppins(color: AppColors.textSecondary),
          labelLarge: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          labelMedium: GoogleFonts.poppins(color: AppColors.textSecondary),
          labelSmall: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        
        // Icon Theme
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.pureWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: AppColors.textSecondary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.pureWhite,
          hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
          labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textTertiary.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.textTertiary.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        
        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.pureWhite,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.pureWhite,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
        ),
        
        // FloatingActionButton Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.pureWhite,
        ),
      ),
      
      // 🟢 DARK THEME - Premium Black & Green
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: AppColors.darkColorScheme,
        scaffoldBackgroundColor: AppColors.primaryBlack,
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryBlack,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textOnDark),
          titleTextStyle: GoogleFonts.poppins(
            color: AppColors.textOnDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Text Theme
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.bold),
          headlineMedium: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w500),
          titleSmall: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w500),
          bodyLarge: GoogleFonts.poppins(color: AppColors.textOnDark),
          bodyMedium: GoogleFonts.poppins(color: AppColors.textOnDark),
          bodySmall: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
          labelLarge: GoogleFonts.poppins(color: AppColors.textOnDark, fontWeight: FontWeight.w500),
          labelMedium: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
          labelSmall: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
        ),
        
        // Icon Theme
        iconTheme: const IconThemeData(color: AppColors.textOnDarkSecondary),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.surfaceBlack,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceBlack,
          hintStyle: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
          labelStyle: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.darkGrey.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.darkGrey.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        
        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.primaryBlack,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceBlack,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textOnDarkSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
        ),
        
        // FloatingActionButton Theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.primaryBlack,
        ),
      ),
      
      home: const SplashScreen(),
      
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/permissions': (context) => const PermissionsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/account_settings': (context) => const AccountSettingsScreen(),
        '/change_name': (context) => const ChangeNameScreen(),
        '/profile_photo': (context) => const ProfilePhotoScreen(),
        '/password': (context) => const PasswordPage(),
        '/usage_access': (context) => const UsageAccessScreen(),
        '/panic_button_settings': (context) => const PanicButtonSettingsScreen(),
        '/uninstall_lock': (context) => const UninstallConfirmScreen(),
        '/merge_contacts': (context) => const MergeContactsScreen(),
        '/partner_call_history': (context) => const PartnerCallHistoryScreen(),
        '/call_details':(context) => const CallLogDetailsScreen(),
        '/display_options': (context) => const DisplayOptionsScreen(),
      },
    );
  }
}
