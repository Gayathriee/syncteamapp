import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_state_provider.dart';
import '../../../shared/widgets/monster_avatar.dart';
import '../domain/user_model.dart';

class ParticipantSignupScreen extends ConsumerStatefulWidget {
  const ParticipantSignupScreen({super.key});

  @override
  ConsumerState<ParticipantSignupScreen> createState() =>
      _ParticipantSignupScreenState();
}

class _ParticipantSignupScreenState
    extends ConsumerState<ParticipantSignupScreen> {
  final _form = FormGroup({
    'email': FormControl<String>(
        validators: [Validators.required, Validators.email]),
    'password': FormControl<String>(
        validators: [Validators.required, Validators.minLength(6)]),
  });

  MonsterVariant _selectedVariant = MonsterVariant.octopus;
  bool _consentGiven = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  Future<void> _signUp() async {
    if (_form.invalid) {
      _form.markAllAsTouched();
      return;
    }
    if (!_consentGiven) {
      setState(() => _errorMessage = 'please tick the consent box to continue');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUpParticipant(
            email: _form.value['email'] as String,
            password: _form.value['password'] as String,
            variant: _selectedVariant,
          );
      if (mounted) context.go('/dashboard');
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
    if (raw.contains('email-already-in-use')) {
      return "that email is already registered — try signing in instead";
    }
    if (raw.contains('weak-password')) {
      return "password is too weak — try something longer";
    }
    return "couldn't create account: $raw";
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
          onPressed: () => context.go('/login'),
        ),
        title: Text('join the study', style: AppTypography.headingMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('pick your monster', style: AppTypography.headingSmall),
            const SizedBox(height: 4),
            Text(
              "this is how you'll appear to your team throughout the study",
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            _MonsterPicker(
              selected: _selectedVariant,
              onChanged: (v) => setState(() => _selectedVariant = v),
            ),
            const SizedBox(height: 28),
            Text('your account', style: AppTypography.headingSmall),
            const SizedBox(height: 16),
            ReactiveForm(
              formGroup: _form,
              child: Column(
                children: [
                  ReactiveTextField<String>(
                    formControlName: 'email',
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'university email address',
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
                      hintText: 'choose a password (min. 6 characters)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
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
            const SizedBox(height: 20),
            // Consent checkbox
            _ConsentCheckbox(
              value: _consentGiven,
              onChanged: (v) => setState(() => _consentGiven = v),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('I consent and want to join →'),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: Text('already registered? sign in',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonsterPicker extends StatelessWidget {
  const _MonsterPicker({required this.selected, required this.onChanged});
  final MonsterVariant selected;
  final ValueChanged<MonsterVariant> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: MonsterVariant.values.map((variant) {
          final isSelected = variant == selected;
          return GestureDetector(
            onTap: () => onChanged(variant),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.tealLight : AppColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.teal : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: MonsterAvatar(variant: variant, size: 56),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  const _ConsentCheckbox({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.teal,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'I have read the participant information sheet, understand the study '
              'involves wearing a heart-rate sensor, and consent to my anonymised '
              'data being used for research purposes. I know I can withdraw at any '
              'time without giving a reason.',
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
