import 'package:flutter/material.dart';

import '../app_shell.dart';

/// Branded launch screen — the album-page logo and tagline on the brand
/// blue. Shown briefly on cold start, then fades into the main app.
///
/// The native splash (flutter_native_splash) paints the same blue + logo
/// instantly before Flutter starts, so the hand-off looks continuous;
/// this screen adds the tagline, which the native splash can't render
/// reliably (Android 12 masks the splash image to a circle).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _brandBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _continueToApp();
  }

  Future<void> _continueToApp() async {
    await Future<void>.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandBlue,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon/splash.png',
                width: 232,
                height: 232,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 26),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOut,
                builder: (_, value, child) =>
                    Opacity(opacity: value, child: child),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 44),
                  child: Text(
                    'Your go-to app for mastering sticker collections',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
