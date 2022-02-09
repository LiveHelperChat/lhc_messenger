part of 'fcmtoken_bloc.dart';

abstract class FcmTokenState extends Equatable {
  final String? token;
  const FcmTokenState({this.token});

  @override
  List<Object> get props => [];
}

class FcmTokenInitial extends FcmTokenState {}

class FcmTokenReceived extends FcmTokenState {
  final String token;
  const FcmTokenReceived({required this.token}) : super(token: token);

  @override
  List<Object> get props => [token];
}

class FcmTokenRefreshed extends FcmTokenState {
  final String token;
  const FcmTokenRefreshed({required this.token}) : super(token: token);

  @override
  List<Object> get props => [token];
}

class ChatOpenedState extends FcmTokenState {
  final Chat? chat;
  final String token;
  const ChatOpenedState({required this.token, this.chat})
      : super(token: token);

  ChatOpenedState copyWith({Chat? chat, String? token}) {
    return ChatOpenedState(chat: chat ?? this.chat, token: token ?? this.token);
  }

  @override
  List<Object> get props => [token, chat!];
}

class ChatOperatorsOpenedState extends FcmTokenState {
  final User? chat;
  final String token;
  const ChatOperatorsOpenedState({required this.token, this.chat})
      : super(token: token);

  ChatOperatorsOpenedState copyWith({User? chat, String? token}) {
    return ChatOperatorsOpenedState(chat: chat ?? this.chat, token: token ?? this.token);
  }

  @override
  List<Object> get props => [token, chat!];
}

class ChatPausedState extends ChatOpenedState {
  final Chat? chat;
  final String token;
  const ChatPausedState({this.chat, required this.token})
      : super(chat: chat, token: token);

  @override
  List<Object> get props => [token, chat!];
}

class ChatClosedState extends FcmTokenState {
  final Chat? chat;
  final String token;
  const ChatClosedState({required this.token, this.chat})
      : super(token: token);

  @override
  List<Object> get props => [token, chat!];
}

class ChatOperatorsClosedState extends FcmTokenState {
  final User? chat;
  final String token;
  const ChatOperatorsClosedState({required this.token, this.chat})
      : super(token: token);

  @override
  List<Object> get props => [token, chat!];
}

class MessageReceivedState extends FcmTokenState {
  final String? fcmToken;
  final Map<String, dynamic>? message;

  const MessageReceivedState({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken!, message!];
}

class OnLaunchedState extends FcmTokenState {
  final String? fcmToken;
  final Map<String, dynamic>? message;

  const OnLaunchedState({this.fcmToken, this.message});

  @override
  List<Object> get props => [fcmToken!, message!];
}

class NotificationClicked extends FcmTokenState {
  final ReceivedNotification? notification;
  final Chat? openedChat;

  const NotificationClicked({this.notification,this.openedChat});

  @override
  List<Object> get props => [notification!, openedChat!];
}
