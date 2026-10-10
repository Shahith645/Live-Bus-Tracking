import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../home/home_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1));

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final session = context.read<SessionProvider>();
    await Future.wait([
      session.loadSession(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => session.isLoggedIn ? const HomeDashboard() : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.primary, size: 64),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fade,
                child: const Column(
                  children: [
                    Text('Smart Bus Tracker',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('Track. Report. Arrive on time.',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: _fade,
                child: const SizedBox(
                  height: 26,
                  width: 26,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
