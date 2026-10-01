import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AsyncActionMixin<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await runAction(
      'send',
      () => ref.read(authRepositoryProvider).sendPasswordReset(_email.text),
    );
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.mark_email_read_outlined,
          title: AppStrings.resetSentTitle,
          message: AppStrings.resetSentBody,
          actionLabel: AppStrings.backToLogin,
          onAction: () => context.go(Routes.login),
        ),
      );
    }

    return AuthScaffold(
      title: AppStrings.resetPassword,
      subtitle: AppStrings.resetSubtitle,
      showBack: true,
      showLogo: false,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _email,
              label: AppStrings.email,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: Validators.email,
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: Gap.l),
            PrimaryButton(
              label: AppStrings.sendResetLink,
              loading: isBusy('send'),
              onPressed: isAnyBusy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
