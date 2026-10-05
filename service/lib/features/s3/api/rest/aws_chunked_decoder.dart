import 'dart:convert';
import 'dart:math';

import 'package:service/feather.dart';

/// `aws-chunked` body: what clients that sign with SigV4 by chunks send
/// (`x-amz-content-sha256: STREAMING-…`; mc and recent AWS SDKs and CLI do).
/// Each chunk is `<hex size>[;chunk-signature=…]\r\n<data>\r\n`, the last one
/// has size 0 and may be followed by trailers (`x-amz-checksum-crc32:…`) and an
/// empty line.
///
/// Only the framing is removed, while streaming: neither the chunk signatures
/// nor the checksums are verified.
class AwsChunkedDecoder {
  /// A size or trailer line shouldn't be any longer.
  static const int _maxLineLength = 8 * 1024;

  final List<int> _line = [];
  _State _state = _State.size;
  int _remaining = 0;

  AwsChunkedDecoder._();

  static bool appliesTo(RequestEntity request) =>
      (request.headers['x-amz-content-sha256'] ?? '').startsWith(
        'STREAMING-',
      ) ||
      (request.headers['content-encoding'] ?? '').contains('aws-chunked');

  /// The content of [body]. A malformed body fails with `IncompleteBody`, but
  /// only after reading all of it: if the request body isn't read to the end,
  /// the connection drops and the client wouldn't get the error.
  static Stream<List<int>> decode(Stream<List<int>> body) async* {
    final decoder = AwsChunkedDecoder._();
    S3Exception? error;
    await for (final chunk in body) {
      if (error != null) continue;
      try {
        for (final data in decoder._feed(chunk)) {
          yield data;
        }
      } on S3Exception catch (e) {
        error = e;
      }
    }
    // Without the final empty line it is also fine: trailers are optional
    if (error == null &&
        decoder._state != _State.done &&
        decoder._state != _State.trailer) {
      error = _malformed();
    }
    if (error != null) throw error;
  }

  /// The data in [chunk]; keeps what is left halfway for the next one.
  List<List<int>> _feed(List<int> chunk) {
    final output = <List<int>>[];
    var i = 0;
    while (i < chunk.length && _state != _State.done) {
      switch (_state) {
        case _State.size || _State.trailer:
          final newline = chunk.indexOf(10, i);
          final end = newline == -1 ? chunk.length : newline;
          _line.addAll(chunk.getRange(i, end));
          if (_line.length > _maxLineLength) throw _malformed();
          i = newline == -1 ? end : end + 1;
          if (newline != -1) _endLine();
        case _State.data:
          final take = min(_remaining, chunk.length - i);
          output.add(chunk.sublist(i, i + take));
          i += take;
          _remaining -= take;
          if (_remaining == 0) _state = _State.dataEnd;
        case _State.dataEnd:
          final byte = chunk[i++];
          if (byte == 10) {
            _state = _State.size;
          } else if (byte != 13) {
            throw _malformed();
          }
        case _State.done:
          break;
      }
    }
    return output;
  }

  /// Ends a size or trailer line.
  void _endLine() {
    final text = latin1.decode(_line).trim();
    _line.clear();
    if (_state == _State.trailer) {
      if (text.isEmpty) _state = _State.done;
      return;
    }
    final size = int.tryParse(text.split(';').first.trim(), radix: 16);
    if (size == null || size < 0) throw _malformed();
    _remaining = size;
    _state = size == 0 ? _State.trailer : _State.data;
  }

  static S3Exception _malformed() => S3Exception(
    S3ErrorCode.incompleteBody,
    message: intl.errors.s3.incompleteChunkedBody,
  );
}

enum _State { size, data, dataEnd, trailer, done }
