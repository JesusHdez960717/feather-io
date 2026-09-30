import 'package:console/app_exporter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

///Enlace para compartir un objeto: lo genera el servicio con la caducidad elegida
class ShareLinkCubit extends Cubit<ShareLinkState> {
  final BrowserRepo _repo;
  final AuthCubit _auth;

  ShareLinkCubit(this._repo, this._auth) : super(const ShareLinkInitialState());

  Future<void> generate({
    required String bucket,
    required String key,
    required ShareLinkExpiration expiration,
  }) async {
    emit(ShareLinkLoadingInProgressState(expiration: expiration));
    try {
      final link = await _repo.presign(
        bucket: bucket,
        key: key,
        expiresIn: expiration.duration,
        token: _auth.auth?.accessToken,
      );
      //si mientras tanto se eligio otra caducidad, este enlace ya no vale
      if (state.expiration != expiration) return;
      emit(ShareLinkLoadingSuccessState(expiration: expiration, link: link));
    } catch (e) {
      if (state.expiration != expiration) return;
      emit(
        ShareLinkLoadingErrorState(
          ExceptionConverter.parse(e),
          expiration: expiration,
        ),
      );
    }
  }
}

abstract class ShareLinkState {
  final ShareLinkExpiration expiration;

  const ShareLinkState({this.expiration = ShareLinkExpiration.day});
}

class ShareLinkInitialState extends ShareLinkState {
  const ShareLinkInitialState();
}

//------------------------- LOADING -------------------------\\
class ShareLinkLoadingInProgressState extends ShareLinkState {
  const ShareLinkLoadingInProgressState({super.expiration});
}

class ShareLinkLoadingSuccessState extends ShareLinkState {
  final SharedLinkModel link;

  const ShareLinkLoadingSuccessState({required this.link, super.expiration});
}

class ShareLinkLoadingErrorState extends ShareLinkState {
  final GlobalException exception;

  const ShareLinkLoadingErrorState(this.exception, {super.expiration});
}
