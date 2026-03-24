import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:testers/screen/Notification/notification_screen.dart';
import 'package:testers/screen/group_testers/group_main_screen.dart';
import 'package:testers/screen/installizer/login_screen.dart';
import 'package:testers/screen/installizer/splash_screen.dart';
import 'package:testers/screen/open_testers/open_testers.dart';
import 'package:testers/screen/open_testers/provider/discount_provider.dart';
import 'package:testers/screen/open_testers/provider/publish_provider.dart';
import 'package:testers/screen/profile/my_profile.dart';
import 'package:testers/screen/recharge/recharge_screen.dart';
import 'package:testers/screen/recharge/service/ads/unity/unity_ads_service.dart';
import 'package:testers/screen/report/report_provider.dart';
import 'package:testers/screen/setting/setting_screen.dart';
import 'package:testers/service/provider/auth_provider.dart';
import 'package:testers/theme/app_theme.dart';
import 'package:testers/theme/theme_provider.dart';
import 'controllers/app_routes.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance;

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
        AppRoutes.ot: (_) => const OpenTesters(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.profile: (_) => const MyProfile(),
        AppRoutes.notification: (_) => const NotificationScreen(),
        AppRoutes.groupTesters: (_) => const GroupMainScreen(),
        AppRoutes.recharge: (_) => const RechargeScreen(),
      },
    );
  }
}
