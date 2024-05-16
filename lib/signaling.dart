import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'messaging.dart';

class Signaling {
  final void Function() onConnecting;
  final void Function() onConnected;
  final void Function() onDisconnected;
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': "stun:stun.relay.metered.ca:80",
      },
      {
        'urls': "turn:a.relay.metered.ca:80",
        'username': "52d5d802afb01dd4ee20f179",
        'credential': "U051hgTpI3ZyjGla",
      },
      {
        'urls': "turn:a.relay.metered.ca:80?transport=tcp",
        'username': "52d5d802afb01dd4ee20f179",
        'credential': "U051hgTpI3ZyjGla",
      },
      {
        'urls': "turn:a.relay.metered.ca:443",
        'username': "52d5d802afb01dd4ee20f179",
        'credential': "U051hgTpI3ZyjGla",
      },
      {
        'urls': "turn:a.relay.metered.ca:443?transport=tcp",
        'username': "52d5d802afb01dd4ee20f179",
        'credential': "U051hgTpI3ZyjGla",
      },
    ],
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  void Function(MediaStream stream)? onAddRemoteStream;

  Signaling(
      {required this.onConnecting,
      required this.onConnected,
      required this.onDisconnected});

  Future<void> startCall(
      String receiverToken,
      RTCVideoRenderer localRenderer,
      RTCVideoRenderer remoteRenderer,
      bool video,
      bool audio,
      String caller) async {
    await openUserMedia(localRenderer, remoteRenderer, video, audio);
    String roomId = await createRoom();
    await Messaging().sendStartCall(receiverToken, roomId, caller, video);
  }

  Future<void> answer(String roomId, RTCVideoRenderer localRenderer,
      RTCVideoRenderer remoteRenderer, bool video) async {
    await openUserMedia(localRenderer, remoteRenderer, video, true);
    await joinRoom(
      roomId,
      localRenderer,
      remoteRenderer,
    );
  }

  Future<String> createRoom() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc();
    peerConnection = await createPeerConnection(configuration);
    // peerConnection?.createDataChannel('text', RTCDataChannelInit());
    registerPeerConnectionListeners();
    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });
    var callerCandidatesCollection = roomRef.collection('callerCandidates');
    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap());
    };
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};
    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    currentRoomText = 'Current room is $roomId - You are the caller!';
    peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    };

    roomRef.snapshots().listen((snapshot) async {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await peerConnection?.setRemoteDescription(answer);
      }
    });

    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return roomId;
  }

  Future<void> joinRoom(
    String roomId,
    RTCVideoRenderer localRenderer,
    RTCVideoRenderer remoteRenderer,
  ) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      peerConnection?.onTrack = (RTCTrackEvent event) {
        event.streams[0].getTracks().forEach((track) {
          remoteStream?.addTrack(track);
        });
      };

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    } else {}
  }

  Future<void> openUserMedia(RTCVideoRenderer localVideo,
      RTCVideoRenderer remoteVideo, bool video, bool sound) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': video, 'audio': sound});
    localVideo.srcObject?.dispose();
    localVideo.setSrcObject(stream: stream);
    localVideo.srcObject = stream;
    localStream = stream;
    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  void changeVideoState() {
    var videoTrack = localStream?.getVideoTracks();
    if (videoTrack?.isEmpty ?? true) {
      startVideo();
    } else {
      stopVideo();
    }
  }

  void stopVideo() {
    var videoTrack = localStream?.getVideoTracks()[0];
    videoTrack?.enabled = false;
  }

  void startVideo() async {
    var stream = await navigator.mediaDevices.getUserMedia({'video': true});
    var videoTrack = stream.getVideoTracks()[0];
    localStream?.addTrack(videoTrack);
    remoteStream?.addTrack(videoTrack);
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {};
    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        onConnecting();
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onConnected();
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onDisconnected();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        peerConnection?.restartIce();
      }
    };
    peerConnection?.onSignalingState = (RTCSignalingState state) {};
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {};
    peerConnection?.onAddStream = (MediaStream stream) {
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
      registerInterlocutorTracksChange(stream);
    };
  }

  void registerInterlocutorTracksChange(MediaStream stream) {
    stream.onRemoveTrack = ((track) {
      print('track removed $track');
    });
    stream.onAddTrack = ((track) {
      print('track added $track');
    });
  }

  Future<void> hangUp(
      RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var document in calleeCandidates.docs) {
        document.reference.delete();
      }

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    }
  }

  void closeMedia(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo) {
    localStream?.dispose();
    remoteStream?.dispose();
    remoteVideo.setSrcObject();
    localVideo.setSrcObject();
  }
}
