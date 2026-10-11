import 'package:cross_file/cross_file.dart';

/// Outside the browser there is no file dialog: nothing is picked
class FilePicker {
  static Future<List<XFile>> pickFiles({bool multiple = true}) async => [];

  static Future<List<XFile>> pickDirectory() async => [];
}
