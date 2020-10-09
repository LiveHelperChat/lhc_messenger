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
  final bool isUserOnline;
  final Server selectedServer;
  final bool isActionLoading;

  ServerListFromDBLoaded(
      {this.serverList = const [],
      this.isUserOnline = false,
      this.selectedServer,
      this.isActionLoading = false});

  ServerListFromDBLoaded copyWith(
      {List<Server> serverList,
      bool isUserOnline,
      Server selectedServer,
      bool isActionLoading}) {
    return ServerListFromDBLoaded(
        serverList: serverList ?? this.serverList,
        isUserOnline: isUserOnline ?? this.isUserOnline,
        selectedServer: selectedServer ?? this.selectedServer,
        isActionLoading: isActionLoading ?? this.isActionLoading);
  }

  @override
  List<Object> get props =>
      [serverList, isUserOnline, selectedServer, isActionLoading];
}

class ServerFromDBLoadError extends ServerState {
  final String message;
  const ServerFromDBLoadError({this.message});

  @override
  List<Object> get props => [message];
}

class ServerLoggedOut extends ServerState {
  final Server server;
  const ServerLoggedOut({this.server});

  @override
  List<Object> get props => [server];
}

class UserOnlineStatus extends ServerState {
  final bool isUserOnline;

  const UserOnlineStatus({this.isUserOnline = false});

  @override
  List<Object> get props => [isUserOnline];
}
