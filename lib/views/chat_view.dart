import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:toast/toast.dart';
import 'package:web_rtc/cubits/cubit/peer_connection_cubit.dart';
import 'package:web_rtc/firebase_data_source.dart';
import 'package:web_rtc/init_remote_renderers_cubit/remote_renderer_cubit.dart';
import 'package:web_rtc/local_renderer_cubit/local_renderer_cubit.dart';

class ChatView extends StatefulWidget {
  // when null a room will be created
  final String? roomId;

  const ChatView({super.key, required this.roomId});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  LocalRendererCubit localRendererCubit = LocalRendererCubit();
  RemoteRendererCubit remoteRendererCubit = RemoteRendererCubit();
  late PeerConnectionCubit peerConnectionCubit;
  FirebaseDataSource dataSource = FirebaseDataSource();

  @override
  void initState() {
    super.initState();


    localRendererCubit = LocalRendererCubit()..initRenderer();

    peerConnectionCubit =
        PeerConnectionCubit(onAddRemoteStream: (remoteStream) async {
      remoteRendererCubit.initRenderer(remoteStream: remoteStream);

    },onConnectionDisconnected: (){
          Navigator.of(context).pop();
        });
  }


  @override
  void deactivate() {
    super.deactivate();

    peerConnectionCubit.dispose();
    localRendererCubit.dispose();
    remoteRendererCubit.dispose();
    // delete the room in case it was created (roomId == null)
    widget.roomId == null
        ? peerConnectionCubit.deleteRoom(roomId: peerConnectionCubit.roomId)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'WebRTC Demo',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Local Stream:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: BlocConsumer(
                bloc: localRendererCubit,
                listener: (context, state) {
                  if (state is LocalRendererDone) {
                    if (widget.roomId != null) {
                      peerConnectionCubit.joinRoom(
                        joinedRoomId: widget.roomId!,
                        localStream: state.localStream,
                      );
                    }else{
                      peerConnectionCubit.createRoom(
                        localStream: state.localStream,
                      );
                    }
                  }
                },
                builder: (context, state) {
                  if (state is LocalRendererLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (state is LocalRendererDone) {
                    return RTCVideoView(
                      placeholderBuilder: (context) {
                        return Container(
                          color: Colors.red,
                        );
                      },
                      state.localRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            const Text(
              'Remote Stream:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 3,
              child: BlocConsumer(
                bloc: remoteRendererCubit,
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is RemoteRendererLoading) {
                    return const CircularProgressIndicator();
                  }
                  if (state is RemoteRendererDone) {
                    return RTCVideoView(
                      placeholderBuilder: (context) {
                        return Container(
                          color: Colors.green,
                        );
                      },
                      state.remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
