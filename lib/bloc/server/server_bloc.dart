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
    if (event is InitializeServers) {
      yield (ServerListFromDBLoading());
    }
    if (event is GetServerListFromDB) {
      var servers = await serverRepository.getServersFromDB(
          onlyLoggedIn: event.onlyLoggedIn);
      yield ServerListFromDBLoaded(serverList: servers);
    } else if (event is SelectServer) {
      yield ServerSelected(server: event.server);
    } else if (event is GetUserOnlineStatus) {
      bool online = await serverRepository.getUserOnlineStatus(event.server);
      int isOnline = online ? 1 : 0;

      event.server.user_online = isOnline;
      await serverRepository
          .saveServerToDB(event.server, "id=?", [event.server.id]);
      yield UserOnlineStatus(isUserOnline: online);
    }
  }

  Future<Server> _logout(Server server, String fcmToken) async {
    await serverRepository.fetchInstallationId(server, fcmToken, "logout");
    server.isloggedin = 0;
    return await serverRepository.saveServerToDB(server, "id=?", [server.id]);
  }
}
