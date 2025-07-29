// File: lib/main.dart
// UPDATED: The '/login' route now points to AuthWrapper. This ensures that after logging out,
// the user is correctly redirected to the IntroDashboardScreen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

// Colors
import 'providers/app_colors.dart';

// Providers
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
import 'permissions_screen.dart';
import 'home_page.dart';
import 'app_lock_screen.dart';
import 'settings_screen.dart';
import 'intro_dashboard.dart';
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
  print("💥 BondNex app starting...");
  await DatabaseHelper().initDatabase();
  
  
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => AuthService()),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'BondNex',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: AppColors.lightColorScheme,
        scaffoldBackgroundColor: AppColors.offWhite,
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
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyLarge: GoogleFonts.poppins(color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.poppins(color: AppColors.textPrimary),
          bodySmall: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        cardTheme: CardThemeData(
          color: AppColors.pureWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.pureWhite,
          hintStyle: GoogleFonts.poppins(color: AppColors.textTertiary),
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
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.pureWhite,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      
      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: AppColors.darkColorScheme,
        scaffoldBackgroundColor: AppColors.primaryBlack,
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
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          bodyLarge: GoogleFonts.poppins(color: AppColors.textOnDark),
          bodyMedium: GoogleFonts.poppins(color: AppColors.textOnDark),
          bodySmall: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnDarkSecondary),
        cardTheme: CardThemeData(
          color: AppColors.surfaceBlack,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceBlack,
          hintStyle: GoogleFonts.poppins(color: AppColors.textOnDarkSecondary),
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
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.primaryBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceBlack,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textOnDarkSecondary,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      
      home: const SplashScreen(),
      
      routes: {
        // FIX: '/login' now correctly points to the AuthWrapper.
        '/login': (context) => const AuthWrapper(),
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
        '/intro_dashboard': (context) => const IntroDashboardScreen(),
      },
    );
  }
}
