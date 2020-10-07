import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'loginform_event.dart';
part 'loginform_state.dart';

class LoginformBloc extends Bloc<LoginformEvent, LoginformState> {
  LoginformBloc({@required this.serverRepository}) : super(LoginformInitial());

  final ServerRepository serverRepository;

  @override
  Stream<LoginformState> mapEventToState(
    LoginformEvent event,
  ) async* {
    if (event is SetServerLoginError) {
      yield ServerLoginError(message: event.message);
    } else if (event is ServerLogin) {
      yield ServerLoginStarted();
      yield* _login(event.server, event.fcmToken);
    }
  }

  Stream<LoginformState> _login(Server server, String fcmToken) async* {
    try {
      bool isNew = false;
      //  await updateToken(recToken);
      List<Server> savedServersList = await serverRepository.getServersFromDB();

      // check if server already exists
      if (savedServersList.length > 0) {
        Server found = savedServersList.firstWhere(
            (srvr) =>
                (srvr.url == server.url && srvr.username == server.username) ||
                srvr.servername == server.servername,
            orElse: () => null);

        if (found != null) {
          server.id = found.id;
          isNew = false;
        } else {
          isNew = true;
        }
      } else {
        isNew = true;
      }

      if (isNew) server.id = null;

      Server srv = await serverRepository.loginServer(server);

      yield ServerLoginFinished();

      if (srv.loggedIn) {
        if (await serverRepository.isExtensionInstalled(srv, "twilio")) {
          srv.twilioInstalled = true;
        }

        // we use this to fetch the already saved serverid
        srv = isNew
            ? await serverRepository.saveServerToDB(srv, null, null)
            : await serverRepository.saveServerToDB(
                srv, "${Server.columns['db_id']} = ? ", [srv.id]);

        // fetch installation id
        // used for unique identification
        srv = await serverRepository.fetchInstallationId(srv, fcmToken, "add");

        srv = await serverRepository.saveServerToDB(
            srv, "${Server.columns['db_id']} = ?", ['${srv.id}']);

        if (srv.installationid.isEmpty) {
          yield ServerLoginError(
              message: "Couldn't find this app's extension at the given url");
          return;
        }

        // fetch user data
        var user = await serverRepository.fetchUserFromServer(srv);
        if (user != null) {
          srv.userid = user['id'];
          srv.firstname = user['name'];
          srv.surname = user['surname'];
          srv.operatoremail = user['email'];
          srv.job_title = user['job_title'];
          srv.all_departments = user['all_departments'];
          srv.departments_ids = user['departments_ids'];
        }

        srv = await serverRepository.saveServerToDB(srv, "id=?", [srv.id]);

        yield ServerLoginSuccess(server: srv, isNew: isNew);
      } else {
        yield ServerLoginError(message: "Login was not successful");
      }
    } catch (ex) {
      yield ServerLoginError(message: "${ex?.message}");
    }
  }
}
