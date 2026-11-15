import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Server error shown above a form's button (409, 429, 503, offline...).
/// Uses the field-error style from Figma; announced to screen readers.
class FormErrorMessage extends StatelessWidget {
  const FormErrorMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AppTextStyles.fieldError.copyWith(fontSize: 13),
      ),
    );
  }
}
