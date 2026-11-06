import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text_styles.dart';

/// TheMealDB credit, worded and linked exactly like web/src/components/MealDbCredit.tsx
/// ("Recipe data from TheMealDB", linking to themealdb.com). The web shows it on every
/// page; here it is in the legal footer (all auth screens) and under the recipe list and
/// recipe screen. The photos are the web's wireframe photos, not TheMealDB's, so the
/// credit is for the data only.
class MealDbCredit extends StatefulWidget {
  const MealDbCredit({super.key, this.textAlign = TextAlign.center});

  final TextAlign textAlign;

  static final url = Uri.parse('https://www.themealdb.com');

  @override
  State<MealDbCredit> createState() => _MealDbCreditState();
}

class _MealDbCreditState extends State<MealDbCredit> {
  late final TapGestureRecognizer _tap = TapGestureRecognizer()
    ..onTap = () =>
        launchUrl(MealDbCredit.url, mode: LaunchMode.externalApplication);

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Recipe data from TheMealDB. Opens themealdb.com',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: AppTextStyles.footerSmall,
            children: [
              const TextSpan(text: 'Recipe data from '),
              TextSpan(
                text: 'TheMealDB',
                style: AppTextStyles.footerSmall.copyWith(
                  decoration: TextDecoration.underline,
                ),
                recognizer: _tap,
              ),
            ],
          ),
          textAlign: widget.textAlign,
        ),
      ),
    );
  }
}
