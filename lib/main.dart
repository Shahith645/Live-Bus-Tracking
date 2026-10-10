import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/session_provider.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const SmartBusTrackerApp());
}

class SmartBusTrackerApp extends StatelessWidget {
  const SmartBusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Bus Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
