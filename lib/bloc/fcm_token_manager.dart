import 'dart:async';

class FcmTokenManager {
  
  FcmTokenManager(token) {
    _fcmToken.add(token);
  }

  final StreamController<String> _fcmToken = StreamController<String>();
  Stream<String> get fcmToken => _fcmToken.stream;
}
