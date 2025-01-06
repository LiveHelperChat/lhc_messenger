import 'dart:async';
import 'package:livehelp/main.dart';
import 'package:meta/meta.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'server_event.dart';
part 'server_state.dart';

class ServerBloc extends Bloc<ServerEvent, ServerState> {
  final ServerRepository? serverRepository;
  ServerBloc({
    @required this.serverRepository,
  })  : assert(serverRepository != null),
        super(ServerInitial()) {
    on<InitServers>(_onInitServers);
    on<GetServerListFromDB>(_onGetServerListFromDB);
    on<SelectServer>(_onSelectServer);
    on<SetUserOnlineStatus>(_onSetUserOnlineStatus);
    on<GetUserOnlineStatus>(_onGetUserOnlineStatus);
    on<LogoutServer>(_onLogoutServer);
  }

  _onInitServers(InitServers event, Emitter<ServerState> emit) {
    emit(ServerInitial());
  }

  Future<void> _onGetServerListFromDB(
      GetServerListFromDB event, Emitter<ServerState> emit) async {
    var servers = await serverRepository!
        .getServersFromDB(onlyLoggedIn: event.onlyLoggedIn);
    if (servers.isNotEmpty) {
      emit(ServerListFromDBLoaded(
          serverList: servers, selectedServer: servers.elementAt(0)));
    } else {
      emit(const ServerListFromDBLoaded());
    }
  }

  _onSelectServer(SelectServer event, Emitter<ServerState> emit) {
    final currentState = state;
    if (currentState is ServerListFromDBLoaded) {
      emit(currentState.copyWith(selectedServer: event.server));
    }
  }

  Future<void> _onSetUserOnlineStatus(
      SetUserOnlineStatus event, Emitter<ServerState> emit) async {
    if (state is ServerListFromDBLoaded) {
      if (state is ServerListFromDBLoaded) {
        emit((state as ServerListFromDBLoaded).copyWith(isActionLoading: true));
        try {
          var server =
              await serverRepository!.setUserOnlineStatus(event.server);
          emit((state as ServerListFromDBLoaded)
              .copyWith(selectedServer: server, isActionLoading: false));
        } catch (ex) {
          emit(ServerListLoadError(message: ex.toString()));
        }
      }
    }
  }

  Future<void> _onGetUserOnlineStatus(
      GetUserOnlineStatus event, Emitter<ServerState> emit) async {
    final currentState = state;
    if (currentState is ServerListFromDBLoaded) {
      if (event.isActionLoading) {
        emit(currentState.copyWith(isActionLoading: true));
      }
      if (event.server.id != null) {
        var server = await serverRepository!.getUserOnlineStatus(event.server);

        emit(currentState.copyWith(
            selectedServer: server, isActionLoading: false));
      } else {
        List<Server> listServer =
            await Future.wait(currentState.serverList.map((server) async {
          if (server.isLoggedIn) {
            return await serverRepository!.getUserOnlineStatus(server);
          } else {
            return server;
          }
        }).toList());

        if (listServer.isEmpty) {
          return;
        }

        emit(currentState.copyWith(
            serverList: listServer,
            isActionLoading: false,
            selectedServer: listServer.elementAt(0)));
      }
    }
  }

  _onLogoutServer(LogoutServer event, Emitter<ServerState> emit) async {
    var servr = await _logout(event.server, event.fcmToken!);
    if (event.deleteServer) {
      await _deleteServer(servr);
    }
    sharedPreferences?.setBool("isLoggedIn", false);
    emit(ServerLoggedOut(server: servr));
  }

  Future<Server> _logout(Server server, String fcmToken) async {
    await serverRepository!.fetchInstallationId(server, fcmToken, "logout");
    server.isLoggedIn = false;
    return serverRepository!.saveServerToDB(server, "id=?", [server.id]);
  }

  Future<bool> _deleteServer(Server server) async {
    return serverRepository!.deleteServer(server);
  }
}
