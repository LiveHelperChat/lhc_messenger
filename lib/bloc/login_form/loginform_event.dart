part of 'loginform_bloc.dart';

abstract class LoginformEvent extends Equatable {
  const LoginformEvent();

  @override
  List<Object> get props => [];
}

class ServerLogin extends LoginformEvent {
  final Server server;
  final bool isNew;
  final String fcmToken;

  const ServerLogin({@required this.server, this.isNew = false, this.fcmToken})
      : assert(server != null);

  @override
  List<Object> get props => [server];
}

class ServerLogout extends LoginformEvent {
  final Server server;
  final String fcmToken;

  const ServerLogout({@required this.server, this.fcmToken})
      : assert(server != null);

  @override
  List<Object> get props => [server];
}

class SetServerLoginError extends LoginformEvent {
  final String message;

  const SetServerLoginError({@required this.message}) : assert(message != null);

  @override
  List<Object> get props => [message];
}
