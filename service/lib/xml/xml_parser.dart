import 'package:service/feather.dart';

/// Reads the XML bodies of S3 requests (DeleteObjects,
/// CompleteMultipartUpload…) into an [XmlElement]: elements, attributes, text,
/// CDATA and entities; the declaration, comments, processing instructions and
/// a DOCTYPE are skipped. Not a validating parser: it only needs the elements
/// of a well-formed document, and anything else is a [FormatException].
class XmlParser {
  final String _xml;
  int _position = 0;

  XmlParser(this._xml);

  XmlElement parse() {
    _skipMisc();
    if (!_startsWith('<')) _fail('no root element');
    final root = _element();
    _skipMisc();
    if (_position < _xml.length) _fail('content after the root element');
    return root;
  }

  XmlElement _element() {
    _expect('<');
    final qualified = _name();
    final attributes = <String, String>{};
    while (true) {
      _skipSpaces();
      if (_startsWith('/>')) {
        _position += 2;
        return XmlElement(_localName(qualified), attributes: attributes);
      }
      if (_startsWith('>')) {
        _position++;
        break;
      }
      final attribute = _name();
      _skipSpaces();
      _expect('=');
      _skipSpaces();
      attributes[attribute] = _quoted();
    }

    final elements = <XmlElement>[];
    final text = StringBuffer();
    while (true) {
      if (_position >= _xml.length) _fail('<$qualified> is not closed');
      if (_startsWith('</')) {
        _position += 2;
        final closing = _name();
        if (closing != qualified) {
          _fail('</$closing> closes <$qualified>');
        }
        _skipSpaces();
        _expect('>');
        break;
      }
      if (_startsWith('<![CDATA[')) {
        final end = _xml.indexOf(']]>', _position);
        if (end < 0) _fail('unclosed CDATA');
        text.write(_xml.substring(_position + 9, end));
        _position = end + 3;
      } else if (_startsWith('<!--') || _startsWith('<?')) {
        _skipMarkup();
      } else if (_startsWith('<')) {
        elements.add(_element());
      } else {
        final next = _xml.indexOf('<', _position);
        final end = next < 0 ? _xml.length : next;
        text.write(unescape(_xml.substring(_position, end)));
        _position = end;
      }
    }
    // Mixed content (text between elements) only keeps the elements
    return XmlElement(
      _localName(qualified),
      attributes: attributes,
      elements: elements,
      text: elements.isEmpty ? text.toString() : null,
    );
  }

  /// The declaration, comments, processing instructions, a DOCTYPE and the
  /// whitespace around the root element.
  void _skipMisc() {
    while (true) {
      _skipSpaces();
      if (_startsWith('<?') || _startsWith('<!')) {
        _skipMarkup();
      } else {
        return;
      }
    }
  }

  void _skipMarkup() {
    final end = _startsWith('<!--')
        ? _xml.indexOf('-->', _position)
        : _startsWith('<?')
        ? _xml.indexOf('?>', _position)
        : _xml.indexOf('>', _position);
    if (end < 0) _fail('unclosed markup');
    _position = end + (_startsWith('<!--') ? 3 : (_startsWith('<?') ? 2 : 1));
  }

  String _name() {
    final start = _position;
    while (_position < _xml.length && !_isNameEnd(_xml.codeUnitAt(_position))) {
      _position++;
    }
    if (_position == start) _fail('a name was expected');
    return _xml.substring(start, _position);
  }

  String _quoted() {
    if (_position >= _xml.length) _fail('an attribute value was expected');
    final quote = _xml[_position];
    if (quote != '"' && quote != "'") _fail('an attribute value is not quoted');
    final end = _xml.indexOf(quote, _position + 1);
    if (end < 0) _fail('unclosed attribute value');
    final value = unescape(_xml.substring(_position + 1, end));
    _position = end + 1;
    return value;
  }

  void _skipSpaces() {
    while (_position < _xml.length && _isSpace(_xml.codeUnitAt(_position))) {
      _position++;
    }
  }

  void _expect(String text) {
    if (!_startsWith(text)) _fail('"$text" was expected');
    _position += text.length;
  }

  bool _startsWith(String text) => _xml.startsWith(text, _position);

  Never _fail(String reason) =>
      throw FormatException('Malformed XML: $reason', _xml, _position);

  static String _localName(String name) {
    final colon = name.indexOf(':');
    return colon < 0 ? name : name.substring(colon + 1);
  }

  static bool _isSpace(int c) =>
      c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;

  static bool _isNameEnd(int c) =>
      _isSpace(c) ||
      c == 0x2F /* / */ ||
      c == 0x3E /* > */ ||
      c == 0x3D /* = */;

  static final RegExp _entity = RegExp(
    r'&(#x[0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos);',
  );

  /// [value] with its XML entities decoded (`&amp;`, `&quot;`, `&#34;`,
  /// `&#x22;`…).
  static String unescape(String value) =>
      value.replaceAllMapped(_entity, (match) {
        final entity = match.group(1)!;
        return switch (entity) {
          'amp' => '&',
          'lt' => '<',
          'gt' => '>',
          'quot' => '"',
          'apos' => "'",
          _ when entity.startsWith('#x') => String.fromCharCode(
            int.parse(entity.substring(2), radix: 16),
          ),
          _ => String.fromCharCode(int.parse(entity.substring(1))),
        };
      });
}
