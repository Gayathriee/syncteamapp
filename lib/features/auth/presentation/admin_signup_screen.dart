import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';

class AdminSignupScreen extends ConsumerStatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  ConsumerState<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends ConsumerState<AdminSignupScreen> {
  final _form = FormGroup({
    'email': FormControl<String>(
        validators: [Validators.required, Validators.email]),
    'password': FormControl<String>(
        validators: [Validators.required, Validators.minLength(6)]),
    'inviteCode': FormControl<String>(validators: [Validators.required]),
  });

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUp() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUpAdmin(
            email: _form.value['email'] as String,
            password: _form.value['password'] as String,
            inviteCode: (_form.value['inviteCode'] as String).trim().toUpperCase(),
          );
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return "that email is already registered — sign in instead";
    }
    if (raw.contains('invite code not recognised')) {
      return "invite code not recognised — check you've entered it correctly";
    }
    if (raw.contains('already been used')) {
      return "that invite code has already been used";
    }
    return "couldn't create account — try again";
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/login'),
        ),
        title: Text('researcher access', style: AppTypography.headingMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lavenderLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.lavender),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "you'll need an invite code from the principal investigator to register.",
                      style:
                          AppTypography.bodySmall.copyWith(color: AppColors.lavender),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ReactiveForm(
              formGroup: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('account details', style: AppTypography.headingSmall),
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'email',
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'university email',
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
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'password (min. 6 characters)',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validationMessages: {
                      'required': (_) => 'password is required',
                      'minLength': (_) => 'at least 6 characters',
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('invite code', style: AppTypography.headingSmall),
                  const SizedBox(height: 12),
                  ReactiveTextField<String>(
                    formControlName: 'inviteCode',
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'e.g. SYNC-2025',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validationMessages: {
                      'required': (_) => 'invite code is required',
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
                    style:
                        AppTypography.bodySmall.copyWith(color: AppColors.coral)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.lavender),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('create admin account →'),
            ),
          ],
        ),
      ),
    );
  }
}
