import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:webrtc_flutter/signaling.dart';
import 'package:flutter/material.dart';

enum VideoSource {
  Camera,
  Screen,
}


class webSocket {
  late Socket socket;
  String socketId = '';


  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ],
      },
      {
        'url': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'url': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'url': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
    ]
  };

  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  List<MediaStream> _remoteStreams = <MediaStream>[];
  List<RTCRtpSender> _senders = <RTCRtpSender>[];
  VideoSource _videoSource = VideoSource.Camera;
  Function(MediaStream stream)? onLocalStream;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  Future<void> connectToServer() async {
    try {
      //Configure socket transports must be sepecified
      socket = io(
          'https://143.198.86.130/',
          OptionBuilder()
              .setTransports(['websocket']) // for Flutter or Dart VM
              .disableAutoConnect() // disable auto-connection
              //.setExtraHeaders({'foo': 'bar'}) // optional
              .build());

      // Handle socket events
      socket.on('connect', (_) {
        socketId = socket.id.toString();
        print('connect_IO: ${socket.id}');
      });
      socket.on('disconnect', (_) => print('disconnect'));
      socket.on('fromServer', (_) => print(_));

      socket.on('kulonuwun', (data) {
        Map<String, dynamic> monggoData = {
          "from_client_id": socketId,
          "to_client_id": data['client_id'],
          "room": data['room'],
          "username": "Janoko",
          "share": data['share']
        };
        socket.emit("monggo", monggoData);
      });
      socket.on('monggo', (data) {
        print('monggo = $data');
        createPeer(data['from_client_id'], data['share']);
        //sendWebRTCOffer(data);
      });
      socket.on('ada_panggilan', (_) => print('ada_panggilan'));
      socket.on('client-name', (_) => print('client-name'));
      socket.on('webRTC-signaling', (data) {
        print(data);
        switch (data['type']) {
          case "OFFER":
            {
              print("---------handle OFFER--------");
              //print(data);
              handleWebRTCOffer(data);
            }
            break;

          case "ANSWER":
            {
              print("---------handle ANSWER--------");
              //print(data);
              handleWebRTCAnswer(data);
            }
            break;

          case "ICE_CANDIDATE":
            {
              print("---------handle ICE_CANDIDATE--------");
              //print(data);
              handleWebRTCCandidate(data);
            }
            break;

          default:
            {
              //statements;
            }
            break;
        }
      });
      socket.on('update-client-mic', (_) => print('update-client-mic'));
      socket.on('screen-sharing', (_) => print('screen-sharing'));
      socket.on('stop-sharing', (_) => print('stop-sharing'));
      socket.on('on_scroll_share', (_) => print('on_scroll_share'));
      socket.on('on_show-hide', (_) => print('on_show-hide'));
      socket.on('update-jam', (_) => print('update-jam'));
      socket.on(
          'on-show-prev-next-page', (_) => print('on-show-prev-next-page'));
      socket.on('on-show-signature', (_) => print('on-show-signature'));
      socket.on('on-reload-pdf', (_) => print('on-reload-pdf'));
      socket.on('on-reset-pdf', (_) => print('on-reset-pdf'));
      socket.on('user-hanged-up', (_) => print('user-hanged-up'));
      socket.on('host-hanged-up', (_) => print('host-hanged-up'));

      socket.on('connect_error', (data) {
        print('Error Koe: $data');
      });
      socket.connect();
    } catch (e) {
      print('Iki Error' + e.toString());
    }
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {

    Map<String, dynamic> data = {
      "client_id": socketId,
      "room": 'hAviGvtRl',
      "username": "Yugo",
      "client_type": "pembeli",
      "host": false,
      "share": false
    };

    socket.emit('join-room', data);
  }

  //======================= WEBRTC ==========================

  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': true});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  void createPeer(String client_id, bool share) async {
    peerConnection = await createPeerConnection(configuration);
    registerPeerConnectionListeners();


    // Code for collecting ICE candidates below
    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // if (candidate == null) {
      //   print('onIceCandidate: complete!');
      //   return;
      // }
      print('onIceCandidate IKI: ${candidate.toMap()}');
      Map<String, dynamic> data = {
        "from_client_id": socketId,
        "to_client_id": client_id,
        "username": "Yugo",
        "type": "ICE_CANDIDATE",
        "candidate": {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex
        },
        "sdpMid": candidate.sdpMid,
        "sdpMLineIndex": candidate.sdpMLineIndex,
        "share": false
      };
      socket.emit("webRTC-signaling", data);
    };
    // Code for collecting ICE candidate above

    peerConnection?.onTrack = (RTCTrackEvent event) {
      print('Got remote track: ${event.streams[0]}');
      event.streams[0].getTracks().forEach((track) {
        print('Add a track to the remoteStream: $track');
        remoteStream?.addTrack(track);
      });
    };

    localStream?.getTracks().forEach((track) async {
      //peerConnection?.addTrack(track, localStream!);
      _senders.add(await peerConnection!.addTrack(track, localStream!));
    });

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    print('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {
      'offer': {'type': offer.type, 'sdp': offer.sdp}
    };

    Map<String, dynamic> sendData = {
      "from_client_id": socketId,
      "to_client_id": client_id,
      "username": "Janoko",
      "type": "OFFER",
      "offer": {'type': offer.type, 'sdp': offer.sdp},
      "offerSdp": offer.sdp,
      "offerType": offer.type,
    };
    print('send data offer -------------------------->');
    socket.emit("webRTC-signaling", sendData);
    print('terkirim -------------------------->');
  }

  void sendWebRTCOffer(data) async {
    var offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> sendData = {
      "from_client_id": socketId,
      "to_client_id": data['from_client_id'],
      "username": "Janoko",
      "type": "OFFER",
      "sdp": {'type': offer.type, 'sdp': offer.sdp},
      "offer": offer,
      "offerType": offer.type,
    };
    socket.emit("webRTC-signaling", sendData);
  }

  void handleWebRTCOffer(data) async {
    await peerConnection?.setRemoteDescription(
      RTCSessionDescription(
        data['offerSdp'],
        data['offerType'],
      ),
    );

    //await peerConnection?.setRemoteDescription(data['offer']);
    var answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);

    Map<String, dynamic> dataAnswer = {
      "from_client_id": socketId,
      "to_client_id": data['from_client_id'],
      "username": "Janoko",
      "type": "ANSWER",
      "answer": {'type': answer.type, 'sdp': answer.sdp},
      "answerSdp": answer.sdp,
      "answerType": answer.type,
    };
    socket.emit("webRTC-signaling", dataAnswer);
  }

  void handleWebRTCAnswer(dynamic data) async {
    print('answersdp');
    // print(data['answer']['sdp']);
    // await peerConnection?.setRemoteDescription(
    //   RTCSessionDescription(
    //     data['answer']['sdp'],
    //     data['answer']['type'],
    //   ),
    // );
    //await peerConnection?.setRemoteDescription(data['offer']);
    var answer = RTCSessionDescription(
      data['answer']['sdp'],
      data['answer']['type'],
    );

    print("Someone tried to connect");
    await peerConnection?.setRemoteDescription(answer);
  }

  void handleWebRTCCandidate(dynamic data) async {
    peerConnection!.addCandidate(
      RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      ),
    );
    print('handleCandidate');
  }


  void switchCamera() {
    print('Switch Camera');
    if (localStream != null) {
      var videoSender = peerConnection?.getSenders();
      // peerConnection.getSenders()
      //     .filter((sender) => sender.track.kind === "video")[0];
      if (_videoSource != VideoSource.Camera) {
        _senders.forEach((sender) {
          if (sender.track!.kind == 'video') {
            sender.replaceTrack(localStream!.getVideoTracks()[0]);
          }
        });
        _videoSource = VideoSource.Camera;
        onLocalStream?.call(localStream!);
      } else {
        Helper.switchCamera(localStream!.getVideoTracks()[0]);
      }
    }
  }

  void switchToScreenSharing(MediaStream stream, RTCVideoRenderer _localRenderer ) {
    //if (_localStream != null && _videoSource != VideoSource.Screen) {
      _senders.forEach((sender) {
        if (sender.track!.kind == 'video') {
          sender.replaceTrack(stream.getVideoTracks()[0]);
        }
      });
      localStream=stream;
      _localRenderer.srcObject = localStream;
      //_videoSource = VideoSource.Screen;
    //}
  }

  // void switchToScreenSharing() async {
  //   // late MediaStream stream;
  //   // final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};
  //   // stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
  //   // if (localStream != null && _videoSource != VideoSource.Screen) {
  //   //   _senders.forEach((sender) {
  //   //     if (sender.track!.kind == 'video') {
  //   //       sender.replaceTrack(stream.getVideoTracks()[0]);
  //   //     }
  //   //   });
  //   //   onLocalStream?.call(stream);
  //   //   _videoSource = VideoSource.Screen;
  //   // }
  //
  //   // final mediaConstraints = <String, dynamic>{'audio': true, 'video': true};
  //   //
  //   // try {
  //   //   var stream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);
  //   //   _localStream = stream;
  //   //   _localRenderer.srcObject = _localStream;
  //   // } catch (e) {
  //   //   print(e.toString());
  //   // }
  //
  //
  //
  // }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
