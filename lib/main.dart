// File: lib/main.dart
// UPDATED: Added a new route '/update_status' for the new screen.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';

// Colors
import 'theme/app_colors.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/app_lock_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/call_log_provider.dart';
import 'providers/display_settings_provider.dart';

// Services
import 'package:bondnex/services/auth/auth_service.dart';
import 'package:bondnex/services/database/database_helper.dart';

// Screens
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/splash_screen.dart';
import 'package:bondnex/settings/permissions/permissions_screen.dart';
import 'screens/dashboard/home_page.dart';
import 'package:bondnex/settings/general/settings_screen.dart';
import 'screens/dashboard/intro_dashboard.dart';
import 'package:bondnex/settings/profile/change_name_screen.dart';
import 'package:bondnex/settings/profile/profile_photo_screen.dart';
import 'package:bondnex/settings/security/password.dart';
import 'package:bondnex/settings/permissions/usage_access_screen.dart';
import 'package:bondnex/settings/security/uninstall_confirm_screen.dart';
import 'package:bondnex/settings/general/merge_contacts_screen.dart';
import 'package:bondnex/phone/partner/partner_call_history_screen.dart';
import 'package:bondnex/phone/screens/call_log_details_screen.dart';
import 'package:bondnex/phone/screens/display_options_screen.dart';
import 'package:bondnex/screens/profile/edit_profile_screen.dart';
import 'package:bondnex/screens/profile/update_status_screen.dart'; // Puthu screen ah import pannunga
import 'package:bondnex/settings/profile/account_settings_screen.dart';
import 'package:bondnex/settings/security/panic_button_settings_screen.dart';
import 'package:bondnex/settings/legal/privacy_policy_screen.dart';
import 'package:bondnex/settings/legal/terms_screen.dart';
import 'package:bondnex/phone/widgets/call_overlay_handler.dart'; // Added for Call UI overlay

import 'package:bondnex/services/background/work_manager_service.dart';
import 'package:bondnex/services/background/fcm_service.dart';
import 'package:bondnex/services/security/rasp_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ignore: deprecated_member_use
  await FirebaseAppCheck.instance.activate(
    // ignore: deprecated_member_use
    androidProvider: AndroidProvider.playIntegrity,
    // ignore: deprecated_member_use
    appleProvider: AppleProvider.appAttest,
    providerWeb: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

  // Initialize Security Services
  await RaspService().init();
  await FCMService().init();

  await DatabaseHelper().initDatabase();

  await WorkManagerService.init();
  WorkManagerService.registerPeriodicSync();

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
            create: (context) => CallLogProvider(
              Provider.of<UserProvider>(context, listen: false),
            ),
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
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        final devicePreviewBuilder = DevicePreview.appBuilder(context, child);
        return CallOverlayHandler(child: devicePreviewBuilder);
      },
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
            borderSide: BorderSide(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.pureWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            borderSide: BorderSide(
              color: AppColors.darkGrey.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.darkGrey.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.primaryBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        '/login': (context) => const AuthWrapper(),
        '/home': (context) => const HomePage(),
        '/permissions': (context) => const PermissionsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/account_settings': (context) => const AccountSettingsScreen(),
        '/change_name': (context) => const ChangeNameScreen(),
        '/profile_photo': (context) => const ProfilePhotoScreen(),
        '/password': (context) => const PasswordPage(),
        '/usage_access': (context) => const UsageAccessScreen(),
        '/panic_button_settings': (context) =>
            const PanicButtonSettingsScreen(),
        '/uninstall_lock': (context) => const UninstallConfirmScreen(),
        '/merge_contacts': (context) => const MergeContactsScreen(),
        '/partner_call_history': (context) => const PartnerCallHistoryScreen(),
        '/call_details': (context) => const CallLogDetailsScreen(),
        '/display_options': (context) => const DisplayOptionsScreen(),
        '/intro_dashboard': (context) => const IntroDashboardScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/update_status': (context) => const UpdateStatusScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/terms_conditions': (context) => const TermsAndConditionsScreen(),
      },
    );
  }
}
