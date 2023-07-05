import 'package:bloc/bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:web_rtc/firebase_data_source.dart';
import 'package:flutter_webrtc/src/native/media_stream_impl.dart';

part 'peer_connection_state.dart';

class PeerConnectionCubit extends Cubit<PeerConnectionState> {
  PeerConnectionCubit({required this.onAddRemoteStream})
      : super(PeerConnectionInitial());
  FirebaseDataSource firebaseDataSource = FirebaseDataSource();
  var logger = Logger(
    printer: PrettyPrinter(),
  );
  late RTCPeerConnection peerConnection;
  late RTCSessionDescription sdpOffer;
  late String roomId;
  MediaStream? remoteStream;
  Future<void> Function(MediaStream remoteStream) onAddRemoteStream;

  static const Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  Future<void> joinRoom({
    required String joinedRoomId,
    required MediaStream localStream,
  }) async {
    roomId = joinedRoomId;
    //----------------------------------
    await _createPeerConnection();
    _registerPeerConnectionStateListeners();
    //----------------
    _registerRemoteStreamListener();
    //--------------------------
    await addLocalStreamTracksToPeerConnection(localStream: localStream);
    //-----------------
    await trickleIceCandidates();
    //------------------------------
    registerRemoteTracksListener();
    //-----------------------------------
    RTCSessionDescription offer =
        await firebaseDataSource.getOffer(roomId: joinedRoomId);
    peerConnection.setRemoteDescription(offer);
    //------------------------
    RTCSessionDescription answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
    await firebaseDataSource.setAnswer(roomId: joinedRoomId, answer: answer);
    //-----------------------------
    await listenForRemoteIceCandidates(roomId: joinedRoomId);
  }

  Future<void> createRoom({required MediaStream localStream}) async {
    String testRoomID = const Uuid().v1().toString();
    String createdRoomId = testRoomID;
    roomId = createdRoomId;
    //----------
    await _createPeerConnection();
    _registerPeerConnectionStateListeners();
    //----------------
    _registerRemoteStreamListener();
    //-----------------------
    await addLocalStreamTracksToPeerConnection(localStream: localStream);
    //-----------------
    await trickleIceCandidates();
    //--------------
    RTCSessionDescription offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);
    //----------------
      await firebaseDataSource.createRoom(offer: offer,roomId: testRoomID);

    //---------------------------
    registerRemoteTracksListener();
    //------------------------------
    waitForAnswerThenSetRemoteDescription(roomId: createdRoomId);
    await listenForRemoteIceCandidates(roomId: createdRoomId);
  }

  void deleteRoom({required String roomId}) {
    firebaseDataSource.deleteRoom(roomId: roomId);
  }

  /// --------------------------------------------------------------------------
  Future<void> _createPeerConnection() async {
    peerConnection = await createPeerConnection(_configuration);
    peerConnection.setConfiguration(_configuration);
  }

  /// -------------------------------------Ice Candidates ---------------------------------
  Future<void> listenForRemoteIceCandidates({required String roomId}) async {
    firebaseDataSource
        .listenToRemoteIceCandidates(roomId: roomId)
        .listen((candidates) {
      if (candidates.isNotEmpty) {
        for (var candidate in candidates) {
          peerConnection.addCandidate(candidate);
          logger.d('adding a remote candidate to peer connection');
        }
      } else {}
    });
  }

  /// -----------------------------------Answer/Offer------------------------------------------
  void waitForAnswerThenSetRemoteDescription({required String roomId}) {
    firebaseDataSource
        .listenForAnswer(roomId: roomId)
        .stream
        .listen((answer) async {
      print("got an answer: ${answer.type}");
      if (answer.type == 'answer') {
        await peerConnection.setRemoteDescription(answer);
      } else {}
    });
  }



  // -------------------------------------Media Streams-------------------------------------
  Future<void> addLocalStreamTracksToPeerConnection(
      {required MediaStream localStream}) async {
    localStream.getTracks().forEach((track) {
      peerConnection.addTrack(track, localStream);
      logger.d('adding local track to peer connection');
    });
  }

  //-------------------event listeners------------------------

  void _registerRemoteStreamListener() {

    peerConnection.onAddStream = (stream) {
      logger.e('on add stream was called');
      remoteStream = stream;
      onAddRemoteStream(remoteStream!);

      print("remote stream was added");


    };
  }

  void registerRemoteTracksListener() {
    // Triggered when the remote peer adds a new media track (audio or video) to the connection
    peerConnection.onTrack = (event) {
      logger.i('received an onTrack event');
      event.streams[0].getTracks().forEach((track) {
        logger.d('adding remote track to remote Stream');
        remoteStream?.addTrack(track);
        logger.i('remote tracks were added to remote stream');
      });
      onAddRemoteStream(remoteStream!);
    };
  }

  Future<void> trickleIceCandidates() async {
    peerConnection.onIceCandidate = (event) async {
      if (event.candidate != null) {
        logger.i('received a candidate');
        // trickling ice instead of sending them at once
        await firebaseDataSource.addCandidateToRoom(
            roomId: roomId, candidate: event);
      } else {
        logger.w('received a null candidate');
      }
    };
  }

  void _registerPeerConnectionStateListeners() {
    peerConnection.onSignalingState = (state) {
      logger.w('signaling state: $state');
    };

    peerConnection.onConnectionState = (state) {
      logger.w('connection state: $state');
    };

    peerConnection.onIceConnectionState = (state) {
      logger.w('ice connection state: $state');
    };

    peerConnection.onIceGatheringState = (state) {
      logger.w('ice gathering state: $state');
    };

    peerConnection.onRemoveStream = (stream) {
      logger.w('stream with id: ${stream.id} was remove');
    };
  }
}
