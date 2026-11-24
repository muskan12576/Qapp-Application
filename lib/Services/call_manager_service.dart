import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qapp/Services/chat_socket_service.dart';
import 'package:qapp/Views/CallModule/widgets/incoming_call_dialog.dart';
import 'package:qapp/main.dart';

class CallManagerService {
  CallManagerService._();
  static final CallManagerService instance = CallManagerService._();

  StreamSubscription? _incomingCallSub;
  bool _isDialogShowing = false;
  String? _activeCallId;

  /// Initialize global listener for incoming voice and video calls
  void initialize() {
    _incomingCallSub?.cancel();
    _incomingCallSub = ChatSocketService.instance.onIncomingCall.listen((
      callData,
    ) {
      debugPrint(
        '📞 [CallManagerService] Incoming call event received: $callData',
      );
      handleIncomingCall(callData);
    });
    debugPrint(
      '📞 [CallManagerService] Initialized and listening for incoming calls',
    );
  }

  /// Handle incoming call payload from socket or push notification
  void handleIncomingCall(Map<String, dynamic> callData) {
    final callId = callData['callId']?.toString();
    if (_isDialogShowing && _activeCallId == callId) {
      debugPrint(
        '📞 [CallManagerService] Call dialog already visible for callId: $callId, ignoring duplicate',
      );
      return;
    }

    final context = GlobalVariable.navState.currentContext;
    if (context == null) {
      debugPrint(
        '⚠️ [CallManagerService] Cannot show incoming call dialog: navState.currentContext is null, retrying...',
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!_isDialogShowing &&
            GlobalVariable.navState.currentContext != null) {
          handleIncomingCall(callData);
        }
      });
      return;
    }

    _isDialogShowing = true;
    _activeCallId = callId;

    IncomingCallDialog.show(context, callData)
        .then((_) {
          _isDialogShowing = false;
          _activeCallId = null;
        })
        .catchError((err) {
          debugPrint('⚠️ [CallManagerService] Error showing dialog: $err');
          _isDialogShowing = false;
          _activeCallId = null;
        });
  }

  void dispose() {
    _incomingCallSub?.cancel();
    _incomingCallSub = null;
    _isDialogShowing = false;
    _activeCallId = null;
  }
}
