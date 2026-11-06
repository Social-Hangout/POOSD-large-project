import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_form_validators.dart';

/// Figma "Password strength": four 4 px segments and a label. Filled segments and wording
/// follow the web's meter: [strength] segments filled, red with "Weak password" under 3,
/// green with "Strong password" from 3.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    final strong = isStrongPassword(strength);
    final color = strong ? AppColors.green : AppColors.error;
    final label = strong ? 'Strong password' : 'Weak password';

    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 1; i <= 4; i++) ...[
                  if (i > 1) const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= strength ? color : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: AppTextStyles.strengthLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
