import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.restoreSession();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, auth.isLoggedIn ? '/' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: primary.withAlpha(80), blurRadius: 28, offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.mic_rounded, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Podcasty',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w800, color: primary, letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
