import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

part 'loginform_event.dart';
part 'loginform_state.dart';

class LoginformBloc extends Bloc<LoginformEvent, LoginformState> {
  LoginformBloc({required this.serverRepository}) : super(LoginformInitial()) {
    on<SetServerLoginError>(_onSetServerLoginError);
    on<ServerLogin>(_onServerLogin);
  }

  final ServerRepository serverRepository;

  Future<void> _onSetServerLoginError(
      SetServerLoginError event, Emitter<LoginformState> emit) async {
    emit(ServerLoginError(message: event.message));
  }

  Future<void> _onServerLogin(
      ServerLogin event, Emitter<LoginformState> emit) async {
    emit(ServerLoginStarted());
    final server = event.server;
    final fcmToken = event.fcmToken!;
    try {
      bool isNew = false;
      //  await updateToken(recToken);
      List<Server> savedServersList = await serverRepository.getServersFromDB();

      // check if server already exists
      if (savedServersList.isNotEmpty) {
        Server found = savedServersList.firstWhere(
            (srvr) =>
                (srvr.url == server.url && srvr.username == server.username) ||
                srvr.servername == server.servername,
            orElse: () => Server());

        if (found.id != null) {
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

      emit(ServerLoginFinished());
      if (srv.isLoggedIn) {
        srv.twilioInstalled = await serverRepository.isExtensionInstalled(srv, "twilio");
        srv.fbInstalled = await serverRepository.isExtensionInstalled(srv, "fbmessenger");

        // we use this to fetch the already saved serverid
        srv = isNew
            ? await serverRepository.saveServerToDB(srv, null, [])
            : await serverRepository.saveServerToDB(
                srv, "${Server.columns['db_id']} = ? ", [srv.id]);

        // fetch installation id
        // used for unique identification
        srv = await serverRepository.fetchInstallationId(srv, fcmToken, "add");

        srv = await serverRepository.saveServerToDB(
            srv, "${Server.columns['db_id']} = ?", ['${srv.id}']);

        if (srv.installationid!.isEmpty) {
          emit(const ServerLoginError(
              message: "Couldn't find this app's extension at the given url"));
          return;
        }

        // fetch user data
        var user = await serverRepository.fetchUserFromServer(srv);
        srv.userid = user['id'];
        srv.firstname = user['name'];
        srv.surname = user['surname'];
        srv.operatoremail = user['email'];
        srv.job_title = user['job_title'];
        srv.all_departments = user['all_departments'];
        srv.departments_ids = user['departments_ids'];

        srv = await serverRepository.saveServerToDB(srv, "id=?", [srv.id]);

        emit(ServerLoginSuccess(server: srv, isNew: isNew));
      } else {
        emit(const ServerLoginError(message: "Login was not successful"));
      }
    } catch (ex) {
      emit(ServerLoginError(message: ex.toString()));
    }
  }
}
