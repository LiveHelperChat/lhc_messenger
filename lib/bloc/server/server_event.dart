part of 'server_bloc.dart';

abstract class ServerEvent extends Equatable {
  const ServerEvent();

  @override
  List<Object> get props => [];
}

class InitializeServers extends ServerEvent {
  const InitializeServers();

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

  const SelectServer({@required this.server}) : assert(server != null);

  @override
  List<Object> get props => [server];
}

class GetUserOnlineStatus extends ServerEvent {
  final Server server;

  const GetUserOnlineStatus({@required this.server}) : assert(server != null);

  @override
  List<Object> get props => [server];
}

class SetUserOnlineStatus extends ServerEvent {
  final Server server;
  final bool isOnline;

  const SetUserOnlineStatus({@required this.server, this.isOnline = false})
      : assert(server != null);

  @override
  List<Object> get props => [server];
}

class LogoutServer extends ServerEvent {
  final Server server;
  final String fcmToken;
  final bool deleteServer;

  const LogoutServer(
      {@required this.server, this.fcmToken, this.deleteServer = false})
      : assert(server != null);
}
