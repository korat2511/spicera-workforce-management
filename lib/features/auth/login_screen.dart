import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared_widgets/animated_brand_background.dart';
import '../shell/main_shell_screen.dart';
import 'data/auth_api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authApiService = const AuthApiService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return valid ? null : 'Enter a valid email address';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await _authApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await authController.login(token);

      if (!mounted) return;
      NavigationUtils.pushAndRemoveUntil(
        const MainShellScreen(),
        context: context,
      );
    } on ApiValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarUtils.showError(context, e.firstMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarUtils.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarUtils.showError(
        context,
        'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBrandBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  ResponsiveUtils.screenPadding(context) +
                  const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.panel),
                          boxShadow: AppShadows.level3,
                        ),
                        child: const Icon(
                          Icons.punch_clock,
                          color: AppColors.primary,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Spicera Workforce',
                        style: AppTypography.headlineMd(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sign in to manage attendance & payroll',
                        style: AppTypography.bodyLg(
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: AppTypography.titleMd(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.username],
                                validator: _validateEmail,
                                style: AppTypography.titleMd(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'admin@spicera.com',
                                  prefixIcon: Icon(
                                    Icons.mail_outline,
                                    size: 24,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                'Password',
                                style: AppTypography.titleMd(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.password],
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _handleLogin(),
                                style: AppTypography.titleMd(
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 24,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 24,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    textStyle: AppTypography.titleMd(),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.onPrimary,
                                            ),
                                          ),
                                        )
                                      : const Text('Log In'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
