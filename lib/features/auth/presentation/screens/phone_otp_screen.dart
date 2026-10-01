import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_scaffold.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen>
    with AsyncActionMixin<PhoneOtpScreen> {
  final _phoneForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  String? _verificationId;
  int _secondsLeft = 0;
  Timer? _timer;

  String get _phoneE164 => '${AppConstants.indiaDialCode}${_phone.text.trim()}';

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    // On resend the phone form is no longer on screen; the number was
    // already validated the first time.
    if (!resend && !_phoneForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    String? id;
    final ok = await runAction('send', () async {
      id = await ref.read(authRepositoryProvider).sendOtp(_phoneE164);
    });
    if (!ok || !mounted || id == null) return;
    // Android auto-verified: the router takes the user in.
    if (id == AuthRepository.autoVerifiedId) return;
    setState(() => _verificationId = id);
    _startTimer();
  }

  Future<void> _verify() async {
    if (!_codeForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await runAction(
      'verify',
      () => ref
          .read(authRepositoryProvider)
          .verifyOtp(_verificationId!, _code.text),
    );
  }

  void _changeNumber() {
    _timer?.cancel();
    _code.clear();
    setState(() {
      _verificationId = null;
      _secondsLeft = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final codeStep = _verificationId != null;
    return AuthScaffold(
      title: AppStrings.otpTitle,
      subtitle: codeStep
          ? '${AppStrings.otpCodeSubtitle} $_phoneE164'
          : AppStrings.otpPhoneSubtitle,
      showBack: true,
      showLogo: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: codeStep ? _buildCodeStep() : _buildPhoneStep(),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneForm,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('phone'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _phone,
            label: AppStrings.phone,
            prefixIcon: Icons.phone_outlined,
            prefixText: '${AppConstants.indiaDialCode} ',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: Validators.indianPhone,
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: Gap.l),
          PrimaryButton(
            label: AppStrings.sendOtp,
            loading: isBusy('send'),
            onPressed: isAnyBusy ? null : () => _sendCode(),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    final theme = Theme.of(context);
    return Form(
      key: _codeForm,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey('code'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(AppConstants.otpLength),
            ],
            decoration: const InputDecoration(
              labelText: AppStrings.otpCode,
              counterText: '',
            ),
            validator: Validators.otp,
            onChanged: (v) {
              if (v.length == AppConstants.otpLength) _verify();
            },
          ),
          const SizedBox(height: Gap.l),
          PrimaryButton(
            label: AppStrings.verifyOtp,
            loading: isBusy('verify'),
            onPressed: isAnyBusy ? null : _verify,
          ),
          const SizedBox(height: Gap.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: isAnyBusy ? null : _changeNumber,
                child: const Text(AppStrings.changeNumber),
              ),
              _secondsLeft > 0
                  ? Text(
                      '${AppStrings.resendIn} $_secondsLeft${AppStrings.seconds}',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant),
                    )
                  : TextButton(
                      onPressed:
                          isAnyBusy ? null : () => _sendCode(resend: true),
                      child: isBusy('send')
                          ? const SizedBox.square(
                              dimension: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Text(AppStrings.resendOtp),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
