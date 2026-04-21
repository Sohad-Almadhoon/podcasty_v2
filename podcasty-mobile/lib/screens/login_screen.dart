import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  AuthProvider? _auth;
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _auth = Provider.of<AuthProvider>(context, listen: false);
      _authListener = () {
        if (mounted && _auth!.isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/');
        }
      };
      _auth!.addListener(_authListener!);
    });
  }

  @override
  void dispose() {
    if (_auth != null && _authListener != null) {
      _auth!.removeListener(_authListener!);
    }
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.login(_emailController.text.trim(), _passwordController.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithGoogle();
      // Browser opens; auth listener (initState) navigates when session arrives.
    } catch (e, st) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Google sign-in failed'),
            content: SingleChildScrollView(
              child: SelectableText(
                'Error: $e\n\nStack:\n$st',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // ── Logo ──
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: primary.withAlpha(60), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Podcasty',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30, fontWeight: FontWeight.w800, color: primary, letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('AI-powered podcasts, made simple', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 40),

                  // ── Google button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: const _GoogleGIcon(size: 20),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Divider ──
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or sign in with email', style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Expanded(child: Divider(color: colors.outline)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Email ──
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Password ──
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Login button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Guest ──
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    child: Text(
                      'Continue as guest',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google "G" logo drawn with CustomPainter — no network/SVG dependency.
class _GoogleGIcon extends StatelessWidget {
  final double size;
  const _GoogleGIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const blue = Color(0xFF4285F4);
  static const red = Color(0xFFEA4335);
  static const yellow = Color(0xFFFBBC05);
  static const green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final stroke = size.width * 0.22;
    final radius = r - stroke / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Blue arc (top-right → right → horizontal bar)
    canvas.drawArc(rect, -0.6, 1.9, false, paint..color = blue);
    // Green arc (bottom-right)
    canvas.drawArc(rect, 1.3, 1.1, false, paint..color = green);
    // Yellow arc (bottom-left)
    canvas.drawArc(rect, 2.4, 1.1, false, paint..color = yellow);
    // Red arc (top-left)
    canvas.drawArc(rect, 3.5, 2.2, false, paint..color = red);

    // Horizontal bar forming the "G"
    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - stroke / 2, r - stroke / 2, stroke),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
