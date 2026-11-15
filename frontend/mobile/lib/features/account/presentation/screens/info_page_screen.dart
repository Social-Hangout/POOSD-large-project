import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/surface_card.dart';
import '../widgets/account_subpage.dart';

/// A text page opened from the Account menu: Need help?, Privacy policy, Terms of use.
///
/// The help text describes how this app works. The team has no privacy policy or terms of
/// use written yet (the web app's links point nowhere), so those pages say so instead of
/// showing made-up legal text. Replace [InfoPageScreen.privacy] and [InfoPageScreen.terms]
/// with the real documents when they exist.
class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<({String heading, String body})> sections;

  factory InfoPageScreen.help() => const InfoPageScreen(
    title: 'Need help?',
    sections: [
      (
        heading: 'Finding recipes',
        body:
            'On My kitchen, add the ingredients you have, one at a time or '
            'separated by commas. Recipes that use the most of them come first, and '
            'each one shows how many of your ingredients it uses. On Explore you can '
            'browse every recipe or search the same way.',
      ),
      (
        heading: 'Logging in',
        body:
            'New accounts need a verified email before they can log in. Open the '
            'link in the email we sent you. If it has expired, try to log in and tap '
            'Resend verification email.',
      ),
      (
        heading: 'Forgot your password',
        body:
            'Tap Forgot password? on the log in screen and enter your email. We '
            'will send you a link to choose a new password. It opens in your '
            'browser and works for one hour.',
      ),
      (
        heading: 'Changing your password',
        body:
            'Go to Account, then Change password, and tap Send Reset Link. Open '
            'the email, copy the link and paste it on the same page, then choose '
            'your new password. The link works once, for one hour.',
      ),
      (
        heading: 'Changing your name',
        body:
            'Go to Account, then Settings, and tap Edit name. Your email '
            "can't be changed.",
      ),
    ],
  );

  factory InfoPageScreen.privacy() => const InfoPageScreen(
    title: 'Privacy policy',
    sections: [
      (
        heading: 'Not published yet',
        body:
            "Savory's privacy policy hasn't been published yet. It will appear "
            'here once it is ready.',
      ),
    ],
  );

  factory InfoPageScreen.terms() => const InfoPageScreen(
    title: 'Terms of use',
    sections: [
      (
        heading: 'Not published yet',
        body:
            "Savory's terms of use haven't been published yet. They will appear "
            'here once they are ready.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AccountSubpage(
      title: title,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 20),
                Semantics(
                  header: true,
                  child: Text(
                    sections[i].heading,
                    style: AppTextStyles.recipeTitle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(sections[i].body, style: AppTextStyles.body),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
