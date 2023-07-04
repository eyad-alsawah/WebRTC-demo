import 'package:bloc/bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:web_rtc/firebase_data_source.dart';

part 'peer_connection_state.dart';

class PeerConnectionCubit extends Cubit<PeerConnectionState> {
  PeerConnectionCubit({required this.onRemoteStreamSet}) : super(PeerConnectionInitial());
  FirebaseDataSource firebaseDataSource = FirebaseDataSource();
  var logger = Logger(
    printer: PrettyPrinter(),
  );
  late RTCPeerConnection peerConnection;
  late RTCSessionDescription sdpOffer;
  late String roomId;
  Future<void> Function(MediaStream remoteStream) onRemoteStreamSet;

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

  Future<void> joinRoom(
      {required String joinedRoomId,
      required MediaStream localStream,
   }) async {
    roomId =joinedRoomId;

    await _createPeerConnection();
    addLocalStreamTracksToPeerConnection(localStream: localStream);
    _registerPeerConnectionListeners(roomId: joinedRoomId
    );
    RTCSessionDescription offer =
        await firebaseDataSource.getOffer(roomId: joinedRoomId);
    peerConnection.setRemoteDescription(offer);
    RTCSessionDescription answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);
   await firebaseDataSource.setAnswer(roomId: joinedRoomId, answer: answer);
    await addRemoteIceCandidatesToPeerConnection(roomId: joinedRoomId);
    await firebaseDataSource.clearRemoteCandidates(roomId: joinedRoomId);
    logger.wtf(peerConnection.signalingState);
  }

  Future<void> createRoom(
      {required MediaStream localStream}) async {
    await _createPeerConnection();
    addLocalStreamTracksToPeerConnection(localStream: localStream);
    RTCSessionDescription offer = await _createOfferAndSendToDatabase();
    String createdRoomId = await firebaseDataSource.createRoom(offer: offer);
    roomId =createdRoomId;
    waitForAnswerThenSetRemoteDescription(roomId: createdRoomId);
    _registerPeerConnectionListeners(roomId: createdRoomId
    );
    await peerConnection.setLocalDescription(offer);
    await addRemoteIceCandidatesToPeerConnection(roomId: createdRoomId);
    logger.e('signaling state: ${peerConnection.signalingState}');
  }

  void deleteRoom({required String roomId}) {
    firebaseDataSource.deleteRoom(roomId: roomId);
  }


  /// --------------------------------------------------------------------------
  Future<void> _createPeerConnection() async {
    peerConnection = await createPeerConnection(_configuration);
    logger.i('created peer connection');
  }
  /// -------------------------------------Ice Candidates ---------------------------------
  Future<void> addRemoteIceCandidatesToPeerConnection(
      {required String roomId}) async {
    firebaseDataSource
        .listenToRemoteIceCandidates(roomId: roomId)
        .listen((candidates) {
      if (candidates.isNotEmpty) {
        for (var candidate in candidates) {
          peerConnection.addCandidate(candidate);
          logger.d('adding a remote candidate to peer connection');
        }
        logger.i('remote candidates were added');
      } else {
        logger.w("received empty candidates");
      }
    });
  }


  /// -----------------------------------Answer/Offer------------------------------------------
  void waitForAnswerThenSetRemoteDescription({required String roomId}){

       firebaseDataSource.listenForAnswer(roomId: roomId).stream.listen((answer) async{


           print("got an answer: ${answer.type}");
           if(answer.type == 'answer'){
             logger.i('received an answer');
             await peerConnection.setRemoteDescription(answer);
             logger.i('remote description was set');
           }else{
             logger.e('received ${answer.type} instead of an answer');


       }});


  }

  Future<RTCSessionDescription> _createOfferAndSendToDatabase() async {
    sdpOffer = await peerConnection.createOffer();
    logger.i('offer was created');
    return sdpOffer;
  }
  // -------------------------------------Media Streams-------------------------------------
  void addLocalStreamTracksToPeerConnection(
      {required MediaStream localStream}) {
    localStream.getTracks().forEach((track) {
      peerConnection.addTrack(track, localStream);
      logger.d('adding local track to peer connection');
    });
    logger.i('local tracks were added');
  }
  //-------------------event listeners------------------------
  void _registerPeerConnectionListeners({required String roomId}) {
    MediaStream? remoteStream; // Make the remoteStream nullable

    // An ice candidate event is sent to an RTCPeerConnection when an RTCIceCandidate has been identified and added to the local peer by a call to RTCPeerConnection.setLocalDescription().
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

    // A function which handles addstream events. These events, of type MediaStreamEvent , are sent when streams are added to the connection by the remote peer
    peerConnection.onAddStream = (stream) {
      logger.e('on add stream was called');
      remoteStream = stream;
      print("remote stream was added");
      onRemoteStreamSet(remoteStream!); // Assert non-null since it should be set here
    };

    // Triggered when the remote peer adds a new media track (audio or video) to the connection
    peerConnection.onTrack = (event) {
      logger.i('received an onTrack event');

      if (remoteStream != null) {
        event.streams[0]
            .getTracks()
            .forEach((track) {
          logger.d('adding remote track to remote Stream');
          remoteStream!.addTrack(track);
          logger.i('remote tracks were added to remote stream');
        });
      } else {
        logger.w('remoteStream is null. Cannot add tracks.');
      }
    };
  }




}
