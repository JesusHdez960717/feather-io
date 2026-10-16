import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';

/// Data of an object's details drawer: its headers (`HEAD`) and, if it is a
/// small image, its bytes for the thumbnail
class ObjectDetailsCubit extends Cubit<ObjectDetailsState> {
  /// Above this size the image is not downloaded for the thumbnail
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
      final type = info.contentType ?? lookupMimeType(key) ?? '';
      final isImage = type.startsWith('image/');
      final thumbnail = isImage && sizeBytes <= maxThumbnailBytes
          ? (await _repo.getObject(
              bucket: bucket,
              key: key,
              token: token,
            )).bytes
          : null;
      emit(
        ObjectDetailsLoadingSuccessState(
          info: info,
          thumbnail: thumbnail,
          thumbnailIsSvg: type.startsWith('image/svg'),
        ),
      );
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

  /// Image bytes for the thumbnail; null if it is not an image or it is big
  final List<int>? thumbnail;

  /// The thumbnail is an SVG, which `Image.memory` can't decode
  final bool thumbnailIsSvg;

  const ObjectDetailsLoadingSuccessState({
    required this.info,
    this.thumbnail,
    this.thumbnailIsSvg = false,
  });
}

class ObjectDetailsLoadingErrorState extends ObjectDetailsState {
  final GlobalException exception;

  const ObjectDetailsLoadingErrorState(this.exception);
}
