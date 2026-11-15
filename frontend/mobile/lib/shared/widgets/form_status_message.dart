import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Success/info message under a form, the web's `<StatusMessage>` without `error`.
class FormStatusMessage extends StatelessWidget {
  const FormStatusMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AppTextStyles.fieldError.copyWith(
          fontSize: 13,
          color: AppColors.greenDark,
        ),
      ),
    );
  }
}
