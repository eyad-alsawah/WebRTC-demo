// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:web_rtc/cubits/cubit/web_rtc_logic_cubit.dart';

// class WebRTCLogic {
//   late MediaStream localStream;
//   late MediaStream remoteStream;
//   late RTCVideoRenderer localRenderer;
//   late RTCVideoRenderer remoteRenderer;

//   static const Map<String, dynamic> _configuration = {
//     'iceServers': [
//       {
//         'urls': [
//           'stun:stun1.l.google.com:19302',
//           'stun:stun2.l.google.com:19302',
//           'numb.viagenie.ca:3478',
//           's1.taraba.net:3478'
//               's2.taraba.net:3478'
//         ],
//       },
//     ],
//   };

//   Future<void> init() async {
//     localStream = await navigator.mediaDevices
//         .getUserMedia({'video': true, 'audio': true});
//     localRenderer = RTCVideoRenderer();
//     remoteRenderer = RTCVideoRenderer();
//     await localRenderer.initialize();
//     await remoteRenderer.initialize();
//   }

//   // Future<void> createOffer() async {
//   //   RTCPeerConnection peerConnection =
//   //       await createPeerConnection(_configuration);
//   //       peerConnection.setLocalDescription(description)
//   //   remoteStream = MediaStream();
//   // }

//   void dispose() {
//     localRenderer.dispose();
//     remoteRenderer.dispose();
//   }
// }
