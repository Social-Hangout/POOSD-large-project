import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../features/authentication/presentation/controllers/session_controller.dart';
import 'account_avatar.dart';
import 'brand_header.dart';

/// Brand header for logged-in screens, with the user's initials (frames 06-14).
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).valueOrNull;
    return BrandHeader(
      trailing: user == null
          ? null
          : AccountAvatar(
              initials: user.initials,
              onTap: () => context.go(AppRoutes.account),
            ),
    );
  }
}
