import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
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
      await ref.read(authRepositoryProvider).signInAdmin(
            email: _form.value['email'] as String,
            password: _form.value['password'] as String,
          );
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
      return "credentials not recognised — check your email and password";
    }
    if (raw.contains('not an admin') || raw.contains('admin profile missing')) {
      return raw.contains('profile missing')
          ? raw
          : "that account doesn't have admin access";
    }
    return "sign in failed: $raw";
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavender,
      body: Column(
        children: [
          // Researcher icon area
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Researcher Login',
                    style: AppTypography.headingLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SyncTeam admin portal',
                    style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70),
                  ),
                ],
              ),
            ),
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
                    Text('sign in', style: AppTypography.headingLarge),
                    const SizedBox(height: 24),
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
                                onPressed: () => setState(() =>
                                    _passwordVisible = !_passwordVisible),
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.lavender),
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
                        Text("new researcher? ", style: AppTypography.bodySmall),
                        GestureDetector(
                          onTap: () => context.go('/admin/signup'),
                          child: Text('request access',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.lavender,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('participant login →',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.teal)),
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
