import 'package:flutter/material.dart';
// import 'package:flutter_callkeep/flutter_callkeep.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:new_rtc/call_state.dart';
import 'package:new_rtc/messaging.dart';
import 'package:new_rtc/signaling.dart';
import 'package:new_rtc/users/user.dart';
import 'package:new_rtc/users/view.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  late Signaling signaling;
  String? roomId;
  final nameController = TextEditingController();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final Messaging messaging = Messaging();
  UserModel? receiver;

  // Future<void> getCalls() async {
  //   List<CallKeepCallData> calls = await CallKeep.instance.activeCalls();
  //   if (calls.isNotEmpty) {
  //     roomId = calls[0].extra!['roomId'];

  //     await signaling.answer(roomId!, _localRenderer, _remoteRenderer);
  //     setState(() {});
  //   }
  // }

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    ref.read(userProvider.notifier).getUser();

    signaling = Signaling(
        onConnecting: () =>
            ref.read(callProvider.notifier).setCallState(CallState.loading),
        onConnected: () =>
            ref.read(callProvider.notifier).setCallState(CallState.active),
        onDisconnected: () async {
          messaging.sendEndedCall();
          signaling.closeMedia(_localRenderer, _remoteRenderer);
          ref.read(callProvider.notifier).setCallState(CallState.inactive);
        });

    messaging.setUp(signaling, _localRenderer, _remoteRenderer, context);

    signaling.onAddRemoteStream = ((stream) async {
      stream.getAudioTracks()[0].enableSpeakerphone(false);
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    // CallKeep.instance.onEvent.listen((event) async {
    //   if (event == null) return;
    //   if (event.type == CallKeepEventType.callAccept) {
    //     final data = event.data as CallKeepCallData;
    //     signaling.answer(
    //         data.extra!['roomId'], _localRenderer, _remoteRenderer);
    //   }
    // });

    // if (roomId == null) getCalls();

    super.initState();
  }

  Color getColor(CallState state) {
    if (state == CallState.loading) {
      return Colors.yellow;
    } else if (state == CallState.active) {
      return Colors.red;
    } else {
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final userState = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: getColor(callState),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UsersList(
              onTapped: (user) => setState(() {
                receiver = user;
              }),
              chosenUser: receiver,
              username: userState?.name,
            ),
            MaterialButton(
              child: Text('Sent message'),
              onPressed: () =>
                  messaging.sendMessage(receiver!.deviceId, 'test'),
            ),
            if (userState != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your name'),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(userState.name),
                ],
              ),
            if (userState == null)
              TextField(
                decoration:
                    const InputDecoration(label: Text('Enter your name')),
                controller: nameController,
                onSubmitted: (value) =>
                    ref.read(userProvider.notifier).setUser(value),
              ),
            Expanded(child: RTCVideoView(_localRenderer)),
            Expanded(child: RTCVideoView(_remoteRenderer)),
            if (receiver != null)
              MaterialButton(
                  child: const Text('Start call'),
                  onPressed: () async {
                    await signaling.startCall(
                        receiver!.deviceId,
                        _localRenderer,
                        _remoteRenderer,
                        true,
                        true,
                        userState!.name);
                    setState(() {});
                  }),
            MaterialButton(
                child: const Text('off'),
                onPressed: () async {
                  signaling.changeVideoState();
                  setState(() {});
                }),
            if (callState == CallState.active || callState == CallState.loading)
              Container(
                color: Colors.red,
                child: GestureDetector(
                  onTap: () {
                    signaling.hangUp(_localRenderer, _remoteRenderer);
                    messaging.sendEndedCall();
                    setState(() {});
                  },
                  child: const Text('End call'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
