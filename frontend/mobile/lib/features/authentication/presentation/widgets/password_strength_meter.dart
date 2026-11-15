import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_form_validators.dart';

/// Figma "Password strength": four 4 px segments and a label, plus the password checklist.
/// [passwordStrength] segments are filled. The color and label follow
/// [passwordStrengthLevel]: red "Weak password" until the required rules pass, yellow
/// "Medium password" once they do, green "Strong password" when every check passes.
/// The checklist is shown before typing starts, so the rules are known up front.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static Color colorFor(PasswordStrengthLevel level) => switch (level) {
    PasswordStrengthLevel.weak => AppColors.error,
    PasswordStrengthLevel.medium => AppColors.yellow,
    PasswordStrengthLevel.strong => AppColors.green,
  };

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    final level = passwordStrengthLevel(password);
    final barColor = colorFor(level);
    // Yellow text on white is hard to read, so the Medium label uses ink.
    final labelColor = level == PasswordStrengthLevel.medium
        ? AppColors.ink
        : barColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                if (i > 1) const SizedBox(width: 5),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= strength ? barColor : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 7),
          Semantics(
            liveRegion: true,
            child: Text(
              level.label,
              style: AppTextStyles.strengthLabel.copyWith(color: labelColor),
            ),
          ),
        ],
        const SizedBox(height: 10),
        for (final requirement in passwordRequirements(password))
          _RequirementRow(requirement: requirement),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement});

  final PasswordRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final met = requirement.met;
    return Semantics(
      label: '${requirement.label}: ${met ? 'done' : 'not yet'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  met ? Icons.check_circle : Icons.radio_button_unchecked,
                  key: ValueKey(met),
                  size: 16,
                  color: met ? AppColors.green : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  requirement.label,
                  style: AppTextStyles.small.copyWith(
                    color: met ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
