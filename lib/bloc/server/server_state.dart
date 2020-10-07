part of 'server_bloc.dart';

abstract class ServerState extends Equatable {
  const ServerState();

  @override
  List<Object> get props => [];
}

class ServerInitial extends ServerState {}

class ServerListFromDBLoading extends ServerState {}

class ServerListFromDBLoaded extends ServerState {
  final List<Server> serverList;

  const ServerListFromDBLoaded({this.serverList});

  @override
  List<Object> get props => [serverList];
}

class ServerFromDBLoadError extends ServerState {}

class ServerSelected extends ServerState {
  final Server server;

  const ServerSelected({this.server}) : assert(server != null);

  @override
  List<Object> get props => [server];
}

class UserOnlineStatus extends ServerState {
  final bool isUserOnline;

  const UserOnlineStatus({this.isUserOnline = false});

  @override
  List<Object> get props => [isUserOnline];
}
