import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with AsyncActionMixin<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final flow = ref.read(postRegisterFlowProvider.notifier);
    flow.start();
    final ok = await runAction(
      'register',
      () => ref.read(authRepositoryProvider).register(
            fullName: _name.text,
            email: _email.text,
            phone10: _phone.text,
            password: _password.text,
          ),
    );
    if (!ok) {
      flow.finish();
      return;
    }
    if (mounted) context.go(Routes.joinSociety);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.createAccount,
      subtitle: AppStrings.registerSubtitle,
      showBack: true,
      showLogo: false,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _name,
                label: AppStrings.fullName,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: Validators.fullName,
              ),
              const SizedBox(height: Gap.m),
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
                controller: _phone,
                label: AppStrings.phone,
                prefixIcon: Icons.phone_outlined,
                prefixText: '${AppConstants.indiaDialCode} ',
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: Validators.indianPhone,
              ),
              const SizedBox(height: Gap.m),
              AppTextField(
                controller: _password,
                label: AppStrings.password,
                helper: AppStrings.passwordHint,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                // Re-check the confirm field as the password changes.
                onChanged: (_) {
                  if (_confirm.text.isNotEmpty) {
                    _formKey.currentState?.validate();
                  }
                },
              ),
              const SizedBox(height: Gap.m),
              AppTextField(
                controller: _confirm,
                label: AppStrings.confirmPassword,
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    Validators.confirmPassword(v, _password.text),
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: Gap.l),
              PrimaryButton(
                label: AppStrings.register,
                loading: isBusy('register'),
                onPressed: isAnyBusy ? null : _register,
              ),
              const SizedBox(height: Gap.m),
              AuthSwitchRow(
                prompt: AppStrings.haveAccount,
                action: AppStrings.login,
                onTap: () => context.go(Routes.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
