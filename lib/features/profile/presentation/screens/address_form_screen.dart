import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/india_states.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/address.dart';
import '../providers/address_providers.dart';
import 'addresses_screen.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});

  final Address? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen>
    with AsyncActionMixin<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.address?.fullName);
  late final _phone = TextEditingController(
      text: widget.address?.phone.replaceFirst(AppConstants.indiaDialCode, ''));
  late final _line1 = TextEditingController(text: widget.address?.line1);
  late final _line2 = TextEditingController(text: widget.address?.line2);
  late final _landmark = TextEditingController(text: widget.address?.landmark);
  late final _city = TextEditingController(text: widget.address?.city);
  late final _pincode = TextEditingController(text: widget.address?.pincode);
  late String? _state = widget.address?.state;
  late AddressLabel _label = widget.address?.label ?? AddressLabel.home;
  late bool _isDefault = widget.address?.isDefault ?? false;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    // Prefill name and phone from the profile for a new address.
    if (!_editing) {
      final user = ref.read(currentAppUserProvider).value;
      _name.text = user?.fullName ?? '';
      _phone.text = (user?.phone ?? '').replaceFirst(AppConstants.indiaDialCode, '');
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _line2, _landmark, _city, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _uid {
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
    return uid;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final state = stateByName(_state!)!;
    String? savedId;
    final ok = await runAction('save', () async {
      savedId = await ref.read(addressRepositoryProvider).save(
            _uid,
            Address(
              id: widget.address?.id ?? '',
              label: _label,
              fullName: _name.text.trim(),
              phone: '${AppConstants.indiaDialCode}${_phone.text.trim()}',
              line1: _line1.text.trim(),
              line2: _line2.text.trim(),
              landmark: _landmark.text.trim(),
              city: _city.text.trim(),
              state: state.name,
              stateCode: state.gstCode,
              pincode: _pincode.text.trim(),
              isDefault: _isDefault,
            ),
          );
    });
    if (ok && mounted) context.pop(savedId);
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteAddressConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final ok = await runAction('delete',
        () => ref.read(addressRepositoryProvider).delete(_uid, widget.address!));
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? AppStrings.editAddress : AppStrings.addAddress),
        actions: [
          if (_editing)
            IconButton(
              tooltip: AppStrings.deleteAddress,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: isAnyBusy ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(Gap.m),
                children: [
                  AppTextField(
                    controller: _name,
                    label: AppStrings.fullName,
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.fullName,
                  ),
                  const SizedBox(height: Gap.m),
                  AppTextField(
                    controller: _phone,
                    label: AppStrings.phone,
                    prefixIcon: Icons.phone_outlined,
                    prefixText: '${AppConstants.indiaDialCode} ',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: Validators.indianPhone,
                  ),
                  const SizedBox(height: Gap.m),
                  AppTextField(
                    controller: _line1,
                    label: AppStrings.addressLine1,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.required,
                  ),
                  const SizedBox(height: Gap.m),
                  AppTextField(
                    controller: _line2,
                    label: AppStrings.addressLine2,
                    textCapitalization: TextCapitalization.words,
                    validator: Validators.required,
                  ),
                  const SizedBox(height: Gap.m),
                  AppTextField(
                    controller: _landmark,
                    label: AppStrings.landmark,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: Gap.m),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _city,
                          label: AppStrings.city,
                          textCapitalization: TextCapitalization.words,
                          validator: Validators.required,
                        ),
                      ),
                      const SizedBox(width: Gap.m),
                      Expanded(
                        child: AppTextField(
                          controller: _pincode,
                          label: AppStrings.pincode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: Validators.pincode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.m),
                  DropdownButtonFormField<String>(
                    initialValue: _state,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: AppStrings.state),
                    items: [
                      for (final s in indiaStates)
                        DropdownMenuItem(value: s.name, child: Text(s.name)),
                    ],
                    onChanged: (v) => setState(() => _state = v),
                    validator: (v) => v == null ? AppStrings.errSelectState : null,
                  ),
                  const SizedBox(height: Gap.l),
                  Text(AppStrings.addressLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: Gap.s),
                  SegmentedButton<AddressLabel>(
                    segments: [
                      for (final l in AddressLabel.values)
                        ButtonSegment(value: l, label: Text(addressLabelText(l))),
                    ],
                    selected: {_label},
                    onSelectionChanged: (s) => setState(() => _label = s.first),
                  ),
                  const SizedBox(height: Gap.s),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.setAsDefault),
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                  const SizedBox(height: Gap.l),
                  PrimaryButton(
                    label: AppStrings.saveAddress,
                    loading: isBusy('save'),
                    onPressed: isAnyBusy ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
