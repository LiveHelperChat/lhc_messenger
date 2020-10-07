part of 'fcmtoken_bloc.dart';

abstract class FcmTokenEvent extends Equatable {
  const FcmTokenEvent();

  @override
  List<Object> get props => [];
}

class FcmTokenReceive extends FcmTokenEvent {
  final String fcmToken;

  const FcmTokenReceive({this.fcmToken});

  @override
  List<Object> get props => [fcmToken];
}

class FcmTokenRefresh extends FcmTokenEvent {
  final String fcmToken;

  const FcmTokenRefresh({this.fcmToken});

  @override
  List<Object> get props => [fcmToken];
}
