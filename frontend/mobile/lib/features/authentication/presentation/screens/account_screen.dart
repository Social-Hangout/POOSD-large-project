import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/eyebrow_heading.dart';
import '../../../../shared/widgets/form_error_message.dart';
import '../../../../shared/widgets/form_status_message.dart';
import '../../../../shared/widgets/legal_footer.dart';
import '../../../../shared/widgets/savory_button.dart';
import '../../../../shared/widgets/savory_text_field.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../../domain/user.dart';
import '../controllers/auth_form_validators.dart';
import '../controllers/session_controller.dart';

/// Account tab: the logged-in user's first name, last name and email, a form to change the
/// name (PUT /api/users/me), and Log Out. The email is read-only because the API doesn't
/// allow changing it. Figma 12 isn't built yet, so this uses the existing card, field and
/// button components.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  bool _editing = false;
  bool _submitted = false;
  bool _saving = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  String? get _firstNameError =>
      _submitted ? AuthFormValidators.firstName(_firstName.text) : null;
  String? get _lastNameError =>
      _submitted ? AuthFormValidators.lastName(_lastName.text) : null;

  void _startEditing(User user) {
    _firstName.text = user.firstName;
    _lastName.text = user.lastName;
    setState(() {
      _editing = true;
      _submitted = false;
      _error = null;
      _status = null;
    });
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    setState(() {
      _editing = false;
      _error = null;
    });
  }

  Future<void> _save(User user) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (_firstNameError != null || _lastNameError != null) return;

    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    // Nothing changed: no request needed.
    if (firstName == user.firstName && lastName == user.lastName) {
      setState(() => _editing = false);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .updateName(firstName: firstName, lastName: lastName);
      if (mounted) {
        setState(() {
          _editing = false;
          _status = 'Name updated.';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.message.isEmpty
              ? 'Unable to update your name.'
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;

    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenX,
              AppSpacing.screenTop,
              AppSpacing.screenX,
              AppSpacing.screenBottom,
            ),
            children: [
              const EyebrowHeading(
                eyebrow: 'Your account',
                heading: 'Account',
                gap: 10,
              ),
              const SizedBox(height: AppSpacing.section),
              SurfaceCard(
                child: user == null
                    ? Text('Not logged in.', style: AppTextStyles.body)
                    : _editing
                    ? _buildForm(user)
                    : _buildDetails(user),
              ),
              const SizedBox(height: AppSpacing.section),
              SavoryButton(
                label: 'Log Out',
                variant: SavoryButtonVariant.secondary,
                onPressed: _saving
                    ? null
                    : () =>
                          ref.read(sessionControllerProvider.notifier).logout(),
              ),
              const SizedBox(height: 24),
              Text('About', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 12),
              const LegalFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Your details', style: AppTextStyles.sectionHeading),
        ),
        const SizedBox(height: 8),
        _DetailRow(label: 'First name', value: user.firstName),
        _DetailRow(label: 'Last name', value: user.lastName),
        _DetailRow(label: 'Email', value: user.email, showDivider: false),
        if (_status != null) ...[
          const SizedBox(height: 12),
          FormStatusMessage(_status!),
        ],
        const SizedBox(height: AppSpacing.cardGap),
        SavoryButton(
          label: 'Edit name',
          variant: SavoryButtonVariant.tint,
          onPressed: () => _startEditing(user),
        ),
      ],
    );
  }

  Widget _buildForm(User user) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Edit name', style: AppTextStyles.sectionHeading),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          SavoryTextField(
            label: 'First name',
            hint: 'First name',
            controller: _firstName,
            errorText: _firstNameError,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.givenName],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          SavoryTextField(
            label: 'Last name',
            hint: 'Last name',
            controller: _lastName,
            errorText: _lastNameError,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.familyName],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(user),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          _DetailRow(label: 'Email', value: user.email, showDivider: false),
          Text("Your email can't be changed.", style: AppTextStyles.small),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.fieldGap),
            FormErrorMessage(_error!),
          ],
          const SizedBox(height: AppSpacing.cardGap),
          SavoryButton(
            label: 'Save name',
            isLoading: _saving,
            loadingLabel: 'Saving…',
            onPressed: () => _save(user),
          ),
          const SizedBox(height: 10),
          SavoryButton(
            label: 'Cancel',
            variant: SavoryButtonVariant.secondary,
            onPressed: _saving ? null : _cancel,
          ),
        ],
      ),
    );
  }
}

/// Label and value with a divider, like the ingredient rows on the recipe screen.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.fieldLabel),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.bodyInk),
            ],
          ),
        ),
      ),
    );
  }
}
