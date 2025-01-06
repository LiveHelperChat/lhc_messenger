part of 'server_bloc.dart';

abstract class ServerEvent extends Equatable {
  const ServerEvent();

  @override
  List<Object> get props => [];
}

class InitServers extends ServerEvent {
  const InitServers();

  @override
  List<Object> get props => [];
}

class GetServerListFromDB extends ServerEvent {
  final bool onlyLoggedIn;

  const GetServerListFromDB({this.onlyLoggedIn = false});

  @override
  List<Object> get props => [onlyLoggedIn];
}

class SelectServer extends ServerEvent {
  final Server server;

  const SelectServer({required this.server});

  @override
  List<Object> get props => [server];
}

class GetUserOnlineStatus extends ServerEvent {
  final Server server;
  final bool isActionLoading;

  const GetUserOnlineStatus({required this.server, this.isActionLoading = false});

  @override
  List<Object> get props => [server, isActionLoading];
}

class SetUserOnlineStatus extends ServerEvent {
  final Server server;
  final bool isOnline;

  const SetUserOnlineStatus({required this.server, this.isOnline = false});

  @override
  List<Object> get props => [server];
}

class LogoutServer extends ServerEvent {
  final Server server;
  final String? fcmToken;
  final bool deleteServer;

  const LogoutServer(
      {required this.server, this.fcmToken, this.deleteServer = false});

  @override
  List<Object> get props => [server, fcmToken!, deleteServer];
}
