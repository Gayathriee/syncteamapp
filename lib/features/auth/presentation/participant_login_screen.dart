import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';

class ParticipantLoginScreen extends ConsumerStatefulWidget {
  const ParticipantLoginScreen({super.key});

  @override
  ConsumerState<ParticipantLoginScreen> createState() =>
      _ParticipantLoginScreenState();
}

class _ParticipantLoginScreenState
    extends ConsumerState<ParticipantLoginScreen> {
  final _form = FormGroup({
    'email': FormControl<String>(
        validators: [Validators.required, Validators.email]),
    'password': FormControl<String>(
        validators: [Validators.required, Validators.minLength(6)]),
  });

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInParticipant(
            email: _form.value['email'] as String,
            password: _form.value['password'] as String,
          );
      // Router guard handles navigation after auth state updates
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('network') || raw.contains('SocketException') ||
        raw.contains('host lookup') || raw.contains('RecaptchaCallWrapper')) {
      return "no internet connection — connect to WiFi and try again";
    }
    if (raw.contains('user-not-found') || raw.contains('wrong-password') ||
        raw.contains('invalid-credential') || raw.contains('INVALID_LOGIN_CREDENTIALS')) {
      return "those credentials don't match — double-check and try again";
    }
    if (raw.contains('not a participant')) {
      return "looks like that's an admin account — use the admin login below";
    }
    if (raw.contains('too-many-requests')) {
      return "too many attempts — give it a minute and try again";
    }
    return "something went wrong: $raw";
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(child: _PeekingMonster()),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('welcome back!', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text("glad you're here · let's sync up",
                        style: AppTypography.bodySmall),
                    const SizedBox(height: 28),
                    ReactiveForm(
                      formGroup: _form,
                      child: Column(
                        children: [
                          ReactiveTextField<String>(
                            formControlName: 'email',
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'email address',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validationMessages: {
                              'required': (_) => 'email is required',
                              'email': (_) => 'enter a valid email',
                            },
                          ),
                          const SizedBox(height: 12),
                          ReactiveTextField<String>(
                            formControlName: 'password',
                            obscureText: !_passwordVisible,
                            decoration: InputDecoration(
                              hintText: 'password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.warm,
                                ),
                                onPressed: () => setState(
                                    () => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            validationMessages: {
                              'required': (_) => 'password is required',
                              'minLength': (_) => 'at least 6 characters',
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.coralLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_errorMessage!,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.coral)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('sign in →'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("new participant? ",
                            style: AppTypography.bodySmall),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: Text('create account',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.teal,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/admin/login'),
                        child: Text('researcher? admin login →',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.lavender)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeekingMonster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 140),
      painter: _PeekingMonsterPainter(),
    );
  }
}

class _PeekingMonsterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.75;
    final r = size.width * 0.36;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(Offset(cx, cy + 4), r, Paint()..color = Colors.black12);
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = AppColors.coral);

    final eyeY = cy - r * 0.25;
    canvas.drawCircle(Offset(cx - r * 0.36, eyeY), r * 0.22,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.36, eyeY), r * 0.22,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - r * 0.36, eyeY), r * 0.10,
        Paint()..color = const Color(0xFF2A2724));
    canvas.drawCircle(Offset(cx + r * 0.36, eyeY), r * 0.10,
        Paint()..color = const Color(0xFF2A2724));

    final path = Path()
      ..moveTo(cx - r * 0.25, cy + r * 0.15)
      ..quadraticBezierTo(cx, cy + r * 0.35, cx + r * 0.25, cy + r * 0.15);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
