import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';

///Datos del cajon de detalles de un objeto: sus cabeceras (`HEAD`) y, si es
///una imagen pequeña, sus bytes para la miniatura
class ObjectDetailsCubit extends Cubit<ObjectDetailsState> {
  ///Por encima de este tamaño no se descarga la imagen para la miniatura
  static const int maxThumbnailBytes = 5 * 1024 * 1024;

  final BrowserRepo _repo;
  final AuthCubit _auth;

  ObjectDetailsCubit(this._repo, this._auth)
    : super(const ObjectDetailsInitialState());

  Future<void> load({
    required String bucket,
    required String key,
    required int sizeBytes,
  }) async {
    emit(const ObjectDetailsLoadingInProgressState());
    try {
      final token = _auth.auth?.accessToken;
      final info = await _repo.headObject(
        bucket: bucket,
        key: key,
        token: token,
      );
      final isImage = (info.contentType ?? lookupMimeType(key) ?? '')
          .startsWith('image/');
      final thumbnail = isImage && sizeBytes <= maxThumbnailBytes
          ? (await _repo.getObject(
              bucket: bucket,
              key: key,
              token: token,
            )).bytes
          : null;
      emit(ObjectDetailsLoadingSuccessState(info: info, thumbnail: thumbnail));
    } catch (e) {
      emit(ObjectDetailsLoadingErrorState(ExceptionConverter.parse(e)));
    }
  }
}

abstract class ObjectDetailsState {
  const ObjectDetailsState();
}

class ObjectDetailsInitialState extends ObjectDetailsState {
  const ObjectDetailsInitialState();
}

//------------------------- LOADING -------------------------\\
class ObjectDetailsLoadingInProgressState extends ObjectDetailsState {
  const ObjectDetailsLoadingInProgressState();
}

class ObjectDetailsLoadingSuccessState extends ObjectDetailsState {
  final ObjectInfoModel info;

  ///Bytes de la imagen para la miniatura; null si no es imagen o es grande
  final List<int>? thumbnail;

  const ObjectDetailsLoadingSuccessState({required this.info, this.thumbnail});
}

class ObjectDetailsLoadingErrorState extends ObjectDetailsState {
  final GlobalException exception;

  const ObjectDetailsLoadingErrorState(this.exception);
}
