import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CallState { inactive, loading, active }

class CallNotifier extends StateNotifier<CallState> {
  CallNotifier() : super(CallState.inactive);

  void setCallState(CallState callState) {
    state = callState;
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier();
});
