import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/auth/provider/auth_provider.dart';
import 'package:testers/screen/notifications/notification_screen.dart';
import 'package:testers/screen/room/room_main_screen.dart';
import 'package:testers/screen/auth/login_screen.dart';
import 'package:testers/screen/auth/splash_screen.dart';
import 'package:testers/screen/discovery/discovery.dart';
import 'package:testers/screen/discovery/provider/discount_provider.dart';
import 'package:testers/screen/discovery/provider/publish_provider.dart';
import 'package:testers/screen/profile/my_profile.dart';
import 'package:testers/screen/recharge/recharge_screen.dart';
import 'package:testers/services/ads/unity_ads_service.dart';
import 'package:testers/screen/report/report_provider.dart';
import 'package:testers/screen/settings/setting_screen.dart';
import 'package:testers/theme/app_theme.dart';
import 'package:testers/theme/theme_provider.dart';
import 'package:testers/constants/app_routes.dart';

import 'constants/info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance;
  await PublishConstants.load();
  await UnityAdsService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<PublishProvider>(
          create: (_) => PublishProvider(),
        ),
        ChangeNotifierProvider(create: (_) => DiscountProvider()),
        ChangeNotifierProvider.value(value: ReportProvider.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Testers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: themeProvider.themeMode,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.discovery: (_) => const Discovery(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.profile: (_) => const MyProfile(),
        AppRoutes.notification: (_) => const NotificationScreen(),
        AppRoutes.room: (_) => const RoomMainScreen(),
        AppRoutes.recharge: (_) => const RechargeScreen(),
      },
    );
  }
}
