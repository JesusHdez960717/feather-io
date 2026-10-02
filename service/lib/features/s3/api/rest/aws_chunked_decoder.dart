import 'dart:convert';
import 'dart:math';

import 'package:service/feather.dart';

/// Cuerpo `aws-chunked`: el que mandan los clientes que firman con SigV4 por
/// trozos (`x-amz-content-sha256: STREAMING-…`, lo hacen mc y los SDKs y la
/// CLI de AWS recientes). Cada trozo es
/// `<tamaño en hex>[;chunk-signature=…]\r\n<datos>\r\n`, el ultimo es de tamaño
/// 0 y le pueden seguir trailers (`x-amz-checksum-crc32:…`) y una linea vacia.
///
/// Solo se quita el formato, en streaming: ni las firmas de cada trozo ni los
/// checksums se comprueban (tampoco se valida `x-amz-content-sha256`)
class AwsChunkedDecoder {
  /// Una linea de tamaño o de trailer no deberia ser mas larga
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

  /// El contenido de [body]. Si esta mal formado falla con `IncompleteBody`,
  /// pero despues de leerlo entero: dejar de leer el cuerpo de la peticion
  /// corta la conexion y el cliente no recibiria el error
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
    //sin la linea vacia final tambien vale: los trailers son opcionales
    if (error == null &&
        decoder._state != _State.done &&
        decoder._state != _State.trailer) {
      error = _malformed();
    }
    if (error != null) throw error;
  }

  /// Los datos que trae [chunk]; guarda lo que queda a medias para el siguiente
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

  /// Termina una linea de tamaño o de trailer
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
    message: 'El cuerpo aws-chunked está incompleto o mal formado.',
  );
}

enum _State { size, data, dataEnd, trailer, done }
