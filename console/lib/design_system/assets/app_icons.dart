import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcons {
  const AppIcons();

  final ActionsIcons actions = const ActionsIcons();
  final LanguageIcons language = const LanguageIcons();
  final ViewTypeIcons viewType = const ViewTypeIcons();
  final StorageIcons storage = const StorageIcons();
  final NavigationIcons navigation = const NavigationIcons();

}

class NavigationIcons {
  const NavigationIcons();

  static const String _navigation = 'assets/icons/navigation';

  SvgAsset get left => const SvgAsset('$_navigation/left.svg');

  SvgAsset get right => const SvgAsset('$_navigation/right.svg');

  SvgAsset get next => const SvgAsset('$_navigation/next.svg');

  SvgAsset get menu => const SvgAsset('$_navigation/menu.svg');
}

class StorageIcons {
  const StorageIcons();

  static const String _storage = 'assets/icons/storage';

  SvgAsset get bucket => const SvgAsset('$_storage/bucket.svg');

  SvgAsset get folder => const SvgAsset('$_storage/folder.svg');

  SvgAsset get object => const SvgAsset('$_storage/object.svg');

  SvgAsset get storage => const SvgAsset('$_storage/storage.svg');
}

class ViewTypeIcons {
  const ViewTypeIcons();

  static const String _viewType = 'assets/icons/view_type';

  SvgAsset get list => const SvgAsset('$_viewType/list.svg');

  SvgAsset get grid => const SvgAsset('$_viewType/grid.svg');
}

class ActionsIcons {
  const ActionsIcons();

  static const String _actions = 'assets/icons/actions';

  SvgAsset get add => const SvgAsset('$_actions/add.svg');

  SvgAsset get close => const SvgAsset('$_actions/close.svg');

  SvgAsset get copy => const SvgAsset('$_actions/copy.svg');

  SvgAsset get delete => const SvgAsset('$_actions/delete.svg');

  SvgAsset get download => const SvgAsset('$_actions/download.svg');

  SvgAsset get edit => const SvgAsset('$_actions/edit.svg');

  SvgAsset get filter => const SvgAsset('$_actions/filter.svg');

  SvgAsset get lock => const SvgAsset('$_actions/lock.svg');

  SvgAsset get logout => const SvgAsset('$_actions/logout.svg');

  SvgAsset get more => const SvgAsset('$_actions/more.svg');

  SvgAsset get refresh => const SvgAsset('$_actions/refresh.svg');

  SvgAsset get search => const SvgAsset('$_actions/search.svg');

  SvgAsset get upload => const SvgAsset('$_actions/upload.svg');

  SvgAsset get uploadFile => const SvgAsset('$_actions/upload-file.svg');

  SvgAsset get uploadFolder => const SvgAsset('$_actions/upload-folder.svg');

  SvgAsset get view => const SvgAsset('$_actions/view.svg');
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
