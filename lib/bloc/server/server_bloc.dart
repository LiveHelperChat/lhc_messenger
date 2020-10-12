import 'dart:async';
import 'package:meta/meta.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'server_event.dart';
part 'server_state.dart';

class ServerBloc extends Bloc<ServerEvent, ServerState> {
  final ServerRepository serverRepository;
  ServerBloc({@required this.serverRepository})
      : assert(serverRepository != null),
        super(ServerInitial());

  @override
  Stream<ServerState> mapEventToState(
    ServerEvent event,
  ) async* {
    final currentState = state;
    if (event is InitServers) {
      yield (ServerInitial());
    } else if (event is GetServerListFromDB) {
      yield* mapGetListToState(event, state);
    } else if (event is SelectServer) {
      if (currentState is ServerListFromDBLoaded) {
        yield (state as ServerListFromDBLoaded)
            .copyWith(selectedServer: event.server);
      }
    } else if (event is SetUserOnlineStatus) {
      yield* mapSetOnlineToState(event, state);
    } else if (event is GetUserOnlineStatus) {
      if (state is ServerListFromDBLoaded) {
        if (event.server != null) {
          var server = await serverRepository.getUserOnlineStatus(event.server);

          yield (state as ServerListFromDBLoaded)
              .copyWith(selectedServer: server, isActionLoading: false);
        } else {
          List<Server> listServer = await Future.wait(
              (state as ServerListFromDBLoaded).serverList.map((server) async {
            if (server.isLoggedIn) {
              return await serverRepository.getUserOnlineStatus(server);
            } else
              return server;
          }).toList());
          yield (state as ServerListFromDBLoaded).copyWith(
              serverList: listServer,
              isActionLoading: false,
              selectedServer: listServer.elementAt(0));
        }
      }
    } else if (event is LogoutServer) {
      var servr = await _logout(event.server, event.fcmToken);
      if (event.deleteServer) {
        await _deleteServer(servr);
      }
      yield ServerLoggedOut(server: servr);
    }
  }

  Future<Server> _logout(Server server, String fcmToken) async {
    await serverRepository.fetchInstallationId(server, fcmToken, "logout");
    server.isLoggedIn = false;
    return serverRepository.saveServerToDB(server, "id=?", [server.id]);
  }

  Future<bool> _deleteServer(Server server) async {
    return serverRepository.deleteServer(server);
  }

  Stream<ServerState> mapGetListToState(
      GetServerListFromDB event, ServerState currentState) async* {
    var servers = await serverRepository.getServersFromDB(
        onlyLoggedIn: event.onlyLoggedIn);
    if (servers.length > 0)
      yield ServerListFromDBLoaded(
          serverList: servers, selectedServer: servers.elementAt(0));
    else
      yield ServerListFromDBLoaded();
  }

  Stream<ServerState> mapSetOnlineToState(
      SetUserOnlineStatus event, ServerState currentState) async* {
    if (state is ServerListFromDBLoaded) {
      if (state is ServerListFromDBLoaded) {
        yield (state as ServerListFromDBLoaded).copyWith(isActionLoading: true);
        try {
          var server = await serverRepository.setUserOnlineStatus(event.server);
          yield (state as ServerListFromDBLoaded)
              .copyWith(selectedServer: server, isActionLoading: false);
        } catch (ex) {
          yield ServerListLoadError(message: "${ex?.message}");
        }
      }
    }
  }
}
