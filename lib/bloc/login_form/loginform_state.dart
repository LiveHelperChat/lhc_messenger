part of 'loginform_bloc.dart';

abstract class LoginformState extends Equatable {
  const LoginformState();

  @override
  List<Object> get props => [];
}

class LoginformInitial extends LoginformState {}

class ServerLoginStarted extends LoginformState {}

class ServerLoginFinished extends LoginformState {}

class ServerLoginSuccess extends LoginformState {
  final bool isNew;
  final Server server;

  const ServerLoginSuccess({required this.server, this.isNew = false});

  @override
  List<Object> get props => [server, isNew];
}

class ServerLoginError extends LoginformState {
  final String? message;

  const ServerLoginError({this.message}) : assert(message != null);

  @override
  List<Object> get props => [message!];
}

class LoginServerSelected extends LoginformState {
  final Server? server;

  const LoginServerSelected({this.server}) : assert(server != null);

  @override
  List<Object> get props => [server!];
}
