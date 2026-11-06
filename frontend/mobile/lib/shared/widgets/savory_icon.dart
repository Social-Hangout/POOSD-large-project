import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icons from the Figma file (Mobile Screens page), saved as SVG in assets/icons/.
enum SavoryIcons {
  eye('eye'),
  eyeOff('eye_off'),
  alertCircle('alert_circle'),
  search('search'),
  searchGreen('search_green'),
  navKitchen('nav_kitchen'),
  navExplore('nav_explore'),
  navSaved('nav_saved'),
  navAccount('nav_account');

  const SavoryIcons(this.file);
  final String file;
  String get path => 'assets/icons/$file.svg';
}

class SavoryIcon extends StatelessWidget {
  const SavoryIcon(this.icon, {super.key, this.size = 20, this.semanticLabel});

  final SavoryIcons icon;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    icon.path,
    width: size,
    height: size,
    semanticsLabel: semanticLabel,
  );
}
