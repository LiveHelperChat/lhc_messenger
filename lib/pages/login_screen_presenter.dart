import 'package:livehelp/model/server.dart';
import 'package:livehelp/utils/server_requests.dart';


abstract class LoginScreenContract {
  void onLoginSuccess(Server server);
  void onLoginError(String errorTxt);
}

class LoginScreenPresenter {
  LoginScreenContract _view;
  ServerRequest srvrRequest;
  LoginScreenPresenter(this._view);

  doLogin(String username, String password) {
  /*  srvrRequest.login(Server).then((Server server) {
      _view.onLoginSuccess(server);
    }).catchError((Exception error) => _view.onLoginError(error.toString()));
*/
  }

}