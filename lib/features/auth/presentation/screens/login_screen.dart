import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with AsyncActionMixin<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // On success the router redirects to Home or the admin panel.
    await runAction(
      'email',
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(_email.text, _password.text),
    );
  }

  Future<void> _google() async {
    await runAction(
      'google',
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.welcomeBack,
      subtitle: AppStrings.loginSubtitle,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      _email.text = 'user@test.com';
                      _password.text = '123456';
                    },
                    child: const Text('Temp User'),
                  ),
                  TextButton(
                    onPressed: () {
                      _email.text = 'admin@test.com';
                      _password.text = '123456';
                    },
                    child: const Text('Admin'),
                  ),
                ],
              ),
              const SizedBox(height: Gap.s),
              AppTextField(
                controller: _email,
                label: AppStrings.email,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
              ),
              const SizedBox(height: Gap.m),
              AppTextField(
                controller: _password,
                label: AppStrings.password,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: Validators.loginPassword,
                onSubmitted: (_) => _login(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isAnyBusy
                      ? null
                      : () => context.push(Routes.forgotPassword),
                  child: const Text(AppStrings.forgotPassword),
                ),
              ),
              const SizedBox(height: Gap.s),
              PrimaryButton(
                label: AppStrings.login,
                loading: isBusy('email'),
                onPressed: isAnyBusy ? null : _login,
              ),
              const SizedBox(height: Gap.l),
              const OrDivider(label: AppStrings.or),
              const SizedBox(height: Gap.l),
              SecondaryButton(
                label: AppStrings.loginWithOtp,
                icon: const Icon(Icons.sms_outlined),
                onPressed: isAnyBusy ? null : () => context.push(Routes.otp),
              ),
              const SizedBox(height: Gap.m),
              SecondaryButton(
                label: AppStrings.continueWithGoogle,
                icon: const GoogleMark(),
                loading: isBusy('google'),
                onPressed: isAnyBusy ? null : _google,
              ),
              const SizedBox(height: Gap.l),
              AuthSwitchRow(
                prompt: AppStrings.noAccount,
                action: AppStrings.register,
                onTap: () => context.push(Routes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
