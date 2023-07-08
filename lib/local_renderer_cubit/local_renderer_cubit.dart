import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

part 'local_renderer_state.dart';

class LocalRendererCubit extends Cubit<LocalRendererState> {
  LocalRendererCubit() : super(LocalRendererInitial());
  MediaStream? localStream;
  late RTCVideoRenderer localRenderer;


  Future<void> initRenderer() async {

    emit(LocalRendererLoading());
     localStream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});

    localRenderer = RTCVideoRenderer();
    await localRenderer
        .initialize()
        ;

    localRenderer.setSrcObject(stream: localStream);
    emit(LocalRendererDone(localRenderer, localStream!));
  }


  void dispose() {
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localStream?.getVideoTracks().forEach((track) {
      track.stop();
    });
    localStream?.getTracks().forEach((track) {
      track.stop();
    });
    localStream?.getAudioTracks().forEach((track) {
      track.stop();
    });
    localRenderer.setSrcObject(stream: null);
    localRenderer.dispose();

  }
}
