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

class MessageReceivedEvent extends FcmTokenEvent {
  final String fcmToken;
  final Map<String, dynamic> message;

  const MessageReceivedEvent({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken, message];
}

class OnLaunchedEvent extends FcmTokenEvent {
  final String fcmToken;
  final Map<String, dynamic> message;

  const OnLaunchedEvent({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken, message];
}

class OnResumeEvent extends FcmTokenEvent {
  final String fcmToken;
  final Map<String, dynamic> message;

  const OnResumeEvent({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken, message];
}

class ChatOpenedEvent extends FcmTokenEvent {
  final Chat chat;
  const ChatOpenedEvent({this.chat});

  @override
  List<Object> get props => [chat];
}

class ChatClosedEvent extends FcmTokenEvent {
  final Chat chat;
  const ChatClosedEvent({this.chat});

  @override
  List<Object> get props => [chat];
}