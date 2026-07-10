import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcons {
  const AppIcons();

  final ActionsIcons actions = const ActionsIcons();
  final LanguageIcons language = const LanguageIcons();

  SvgAsset get admin => const SvgAsset(
    'assets/icons/actions/delete.svg',
    defaultColor: Colors.white,
  );
}

class ActionsIcons {
  const ActionsIcons();

  static const String _actions = 'assets/icons/actions';

  SvgAsset get add => const SvgAsset('$_actions/add.svg');

  SvgAsset get close => const SvgAsset('$_actions/close.svg');

  SvgAsset get copy => const SvgAsset('$_actions/copy.svg');

  SvgAsset get delete => const SvgAsset('$_actions/delete.svg');

  SvgAsset get edit => const SvgAsset('$_actions/edit.svg');

  SvgAsset get logout => const SvgAsset('$_actions/logout.svg');

  SvgAsset get refresh => const SvgAsset('$_actions/refresh.svg');

  SvgAsset get search => const SvgAsset('$_actions/search.svg');
}

class LanguageIcons {
  const LanguageIcons();

  static const String _language = 'assets/icons/languages';

  SvgAsset get es => const SvgAsset('$_language/es.svg');

  SvgAsset get en => const SvgAsset('$_language/en.svg');
}

class SvgAsset {
  final double defaultSvgSize = 24.0;

  final String url;
  final Color? defaultColor;
  final double? defaultSize;

  const SvgAsset(this.url, {this.defaultColor, this.defaultSize});

  Widget build({double? size, Color? color, BoxFit? fit}) => SvgPicture.asset(
    url,
    semanticsLabel: url,
    width: size ?? defaultSize ?? defaultSvgSize,
    height: size ?? defaultSize ?? defaultSvgSize,
    fit: fit ?? BoxFit.fill,
    colorFilter: (color ?? defaultColor) != null
        ? ColorFilter.mode((color ?? defaultColor)!, BlendMode.srcIn)
        : null,
  );
}
