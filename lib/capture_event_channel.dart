import 'dart:async';

import 'package:flutter/services.dart';

class CaptureEventChannel {
  CaptureEventChannel._();

  // New Event Channel
  static const EventChannel _captureChannel = EventChannel('capture_channel');

  // Capture stream.
  static Stream<bool> get captureStream {
    return _captureChannel.receiveBroadcastStream().cast();
  }
}
