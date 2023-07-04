part of 'remote_renderer_cubit.dart';

abstract class RemoteRendererState {}

class RemoteRendererInitial extends RemoteRendererState {}

class RemoteRendererLoading extends RemoteRendererState {}



class RemoteRendererDone extends RemoteRendererState {
  final RTCVideoRenderer remoteRenderer;
  final MediaStream remoteStream;

  RemoteRendererDone(this.remoteRenderer, this.remoteStream);
}


class RemoteRendererError extends RemoteRendererState {}
