import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


part 'remote_renderer_state.dart';

class RemoteRendererCubit extends Cubit<RemoteRendererState> {
  RemoteRendererCubit() : super(RemoteRendererInitial());
  RTCVideoRenderer? remoteRenderer;


  Future<void> initRenderer({required MediaStream remoteStream}) async {
    emit(RemoteRendererLoading());
    remoteRenderer = RTCVideoRenderer();
    await remoteRenderer
        ?.initialize();
    remoteRenderer!.setSrcObject(stream: remoteStream);
    emit(RemoteRendererDone(remoteRenderer!, remoteStream));
  }

  void dispose() {

    if (remoteRenderer != null) {
      remoteRenderer!.dispose();
    }
  }
}
