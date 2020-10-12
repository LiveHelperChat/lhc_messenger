part of 'fcmtoken_bloc.dart';

abstract class FcmTokenState extends Equatable {
  final String token;
  const FcmTokenState({this.token});

  @override
  List<Object> get props => [];
}

class FcmTokenInitial extends FcmTokenState {}

class FcmTokenReceived extends FcmTokenState {
  final String token;
  const FcmTokenReceived({@required this.token}) : super(token: token);

  @override
  List<Object> get props => [token];
}

class FcmTokenRefreshed extends FcmTokenState {
  final String token;
  const FcmTokenRefreshed({@required this.token}) : super(token: token);

  @override
  List<Object> get props => [token];
}

class ChatOpenedState extends FcmTokenState {
  final Chat chat;
  final String token;
  const ChatOpenedState({@required this.token, this.chat})
      : super(token: token);

  @override
  List<Object> get props => [token, chat];
}

class ChatClosedState extends FcmTokenState {
  final Chat chat;
  final String token;
  const ChatClosedState({@required this.token, this.chat})
      : super(token: token);

  @override
  List<Object> get props => [token, chat];
}

class MessageReceivedState extends FcmTokenState {
  final String fcmToken;
  final Map<String, dynamic> message;

  const MessageReceivedState({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken, message];
}

class OnLaunchedState extends FcmTokenState {
  final String fcmToken;
  final Map<String, dynamic> message;

  const OnLaunchedState({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken, message];
}

class OnResumeState extends FcmTokenState {
  final String fcmToken;
  final Map<String, dynamic> message;

  const OnResumeState({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken, message];
}
