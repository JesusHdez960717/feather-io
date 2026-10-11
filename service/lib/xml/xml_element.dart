import 'package:service/feather.dart';

/// An XML element: a name, its attributes, and either text or child elements.
///
/// It is both what the models build to answer in XML ([toXmlString]) and what
/// [XmlElement.parse] gives for a request body ([child], [children], [text]).
/// Names are kept without their namespace prefix (`s3:Key` is `Key`), so a
/// client that declares the S3 namespace with a prefix reads the same.
class XmlElement {
  final String name;
  final Map<String, String> attributes;
  final List<XmlElement> elements;

  /// The text of the element; null for one with children or empty (`<a/>`).
  final String? text;

  XmlElement(
    this.name, {
    this.attributes = const {},
    this.elements = const [],
    this.text,
  });

  /// A leaf with [value] as its text (`<Size>12</Size>`). A null value is an
  /// empty element (`<Prefix></Prefix>`), as S3 writes the ones it always sends.
  XmlElement.leaf(this.name, Object? value)
    : attributes = const {},
      elements = const [],
      text = value?.toString() ?? '';

  /// The document in [xml]. A body that isn't well-formed XML is a
  /// [FormatException].
  factory XmlElement.parse(String xml) => XmlParser(xml).parse();

  /// The first child element called [name], or null.
  XmlElement? child(String name) {
    for (final element in elements) {
      if (element.name == name) return element;
    }
    return null;
  }

  /// Every child element called [name], in order.
  Iterable<XmlElement> children(String name) =>
      elements.where((element) => element.name == name);

  /// The text of the first child called [name], or null without one.
  String? childText(String name) => child(name)?.text;

  /// The document with its XML declaration, indented two spaces per level.
  String toXmlString() {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n');
    _write(buffer, 0);
    return buffer.toString();
  }

  void _write(StringBuffer buffer, int depth) {
    final indent = '  ' * depth;
    buffer
      ..write(indent)
      ..write('<$name');
    attributes.forEach(
      (key, value) => buffer.write(' $key="${escape(value)}"'),
    );
    if (elements.isEmpty) {
      if (text == null) {
        buffer.writeln('/>');
      } else {
        buffer.writeln('>${escape(text!)}</$name>');
      }
      return;
    }
    buffer.writeln('>');
    for (final element in elements) {
      element._write(buffer, depth + 1);
    }
    buffer.writeln('$indent</$name>');
  }

  /// [value] with the characters XML reserves as entities.
  static String escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  @override
  String toString() => 'XmlElement{$name}';
}

/// A model that has an XML form, as [toXml] (the S3 responses). The controller
/// chooses between it and the JSON of `toJson()` (`S3Response`).
abstract interface class XmlSerializable {
  XmlElement toXml();
}
