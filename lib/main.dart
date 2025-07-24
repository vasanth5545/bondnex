// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/app_lock_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/call_log_provider.dart';
import 'providers/display_settings_provider.dart';
import 'services/auth_service.dart';
import 'services/database_helper.dart';
// import 'services/background_service.dart'; // Intha line-a comment pannirukken

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

  // Background service-kaga save panna code-a remove pannirukken
  
  await DatabaseHelper().initDatabase();
  // await initializeBackgroundService(); // Intha line-ayum comment pannirukken
  
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
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        primaryColor: Colors.blue,
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF5F5F7),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: GoogleFonts.poppins(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.black87, displayColor: Colors.black),
        iconTheme: const IconThemeData(color: Colors.black54),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey[500],
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        primaryColor: const Color(0xFF007AFF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007AFF),
          secondary: Colors.blueAccent,
          surface: Color(0xFF1C2C44),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white70),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C2C44),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C2C44),
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF0A0E1A),
          selectedItemColor: const Color(0xFF007AFF),
          unselectedItemColor: Colors.grey[600],
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
