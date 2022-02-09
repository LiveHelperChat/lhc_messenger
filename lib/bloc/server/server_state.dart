part of 'server_bloc.dart';

abstract class ServerState extends Equatable {
  const ServerState();

  @override
  List<Object> get props => [];
}

class ServerInitial extends ServerState {}

class ServerListLoading extends ServerState {}

class ServerListFromDBLoaded extends ServerState {
  final List<Server> serverList;
  final Server? selectedServer;
  final bool isActionLoading;

  const ServerListFromDBLoaded(
      {this.serverList = const [],
        this.selectedServer,
        this.isActionLoading = false});

  ServerListFromDBLoaded copyWith(
      {List<Server>? serverList,
        Server? selectedServer,
        bool? isActionLoading}) {
    return ServerListFromDBLoaded(
        serverList: serverList ?? this.serverList,
        selectedServer: selectedServer ?? this.selectedServer,
        isActionLoading: isActionLoading ?? this.isActionLoading);
  }

  @override
  List<Object> get props =>
      [serverList, selectedServer ?? '', isActionLoading];
}

class ServerListLoadError extends ServerState {
  final String? message;
  const ServerListLoadError({this.message});

  @override
  List<Object> get props => [message!];
}

class ServerLoggedOut extends ServerState {
  final Server? server;
  const ServerLoggedOut({this.server});

  @override
  List<Object> get props => [server!];
}
