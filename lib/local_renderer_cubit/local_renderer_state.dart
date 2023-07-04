part of 'local_renderer_cubit.dart';


abstract class LocalRendererState {}

class LocalRendererInitial extends LocalRendererState {}

class LocalRendererLoading extends LocalRendererState {}

class LocalRendererDone extends LocalRendererState {
  final RTCVideoRenderer localRenderer;
  final MediaStream localStream;

  LocalRendererDone(this.localRenderer, this.localStream);
}

class LocalRendererError extends LocalRendererState {}
