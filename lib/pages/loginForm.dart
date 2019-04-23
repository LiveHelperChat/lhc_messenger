import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'package:async_loader/async_loader.dart';

import 'package:livehelp/model/server.dart';
import 'package:livehelp/utils/server_requests.dart';
import 'package:livehelp/data//database.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/pages/main_page.dart';
import 'package:livehelp/pages/loginForm.dart';
import 'package:livehelp/pages/server_details.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/utils/widget_utils.dart';

const TIMEOUT = const Duration(seconds: 5);

class LoginForm extends StatefulWidget {
  LoginForm({Key key, this.isNew = false}) : super(key: key);

  bool isNew;

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  BuildContext _context;

  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _scrollViewKey = new GlobalKey<ScaffoldState>();

  static final TextEditingController _nameController =
      new TextEditingController();
  static final TextEditingController _urlController =
      new TextEditingController();
  static final TextEditingController _userNameController =
      new TextEditingController();
  static final TextEditingController _passwordController =
      new TextEditingController();

  Server _currentServer = new Server();
  List<Server> savedServersList = new List<Server>();

  //ScrollController formScrollController = new ScrollController();
  DatabaseHelper dbHelper;
//  String _username, _password, _server_url, _server_name;
//  String get _username =>_userNameController.text;
//  String get _password =>_userNameController.text;
//  String get _server_url =>_urlController.text;
//  String get _server_name =>_nameController.text;

  String fcmToken = "";

  MainPage mainPage;

  final GlobalKey<AsyncLoaderState> _asyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  ServerRequest srvrRequest = new ServerRequest();

  bool _isLoading = false;
  bool _checkBoxUrlHasIndex = true;
  bool _isNewServer;

  @override
  initState() {
    super.initState();
   // _resetControllers();
    dbHelper = new DatabaseHelper();

    _isNewServer = widget?.isNew ?? false;

  }


  // Instantiate the Formfields.  Note we provide persisters for each.
  //
  @override
  Widget build(BuildContext context) {
    _context = context;

    //_getSavedServers();

    final tokenInherited = TokenInheritedWidget.of(context);
    setState(() {
      fcmToken = tokenInherited.token;
    });

    var loginBtn = new Container(
        padding: const EdgeInsets.only(top: 8.0),
        child: new RaisedButton(
          onPressed: () {
            _submit();
          },
          child: new Text("LOGIN",style: new TextStyle(color: Colors.white),),
          color: Theme.of(_context).primaryColor,
        ));
    var loginForm = new Column(
      children: <Widget>[

       new Offstage(
         offstage:savedServersList.length ==0,
         child:new DropdownButton(
         value: null,
         hint: new Text("Select Server"),
         items:savedServersList.length > 0 ? savedServersList.map((srv) {
           return  new DropdownMenuItem(
             value: srv,
             child: new Text('Dept: ${srv?.servername}'),
           );

         }).toList() :<DropdownMenuItem>[new DropdownMenuItem(
           value: null,
           child: new Text(''),
         )] ,
         onChanged: ((ssrv){
           setState(() {
             _currentServer = ssrv;
             _resetControllers();
           });
         }),
       ) ,) ,
        new Form(
          key: _formKey,
          child: new Column(
            children: <Widget>[
              new TextFormField(
                controller: _nameController,
                //      onSaved: (val) => _server_name = val,
                decoration: const InputDecoration(
                    icon: const Icon(Icons.web),
                    hintText: 'Name of site',
                    labelText: 'Server Name *'),
                //  onSaved: (String value) { person.name = value; },
                validator: (value){
                    if(value.isEmpty){
                        return 'A name is required for this server';
                       }
                }
              ),
              new TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.http),
                  hintText: 'http://yourdomain.com/lhc',
                  labelText: 'Url (no trailing slash /)*',
                ),
                keyboardType: TextInputType.url,
                //   onSaved: (val) => _server_url = val,
                 validator:(value){
                   if(value.isEmpty){
                     return 'Address cannot be empty';
                   }
                 } ,
             /*   // TextInputFormatters are applied in sequence.
                inputFormatters: <TextInputFormatter> [
                  WhitelistingTextInputFormatter.digitsOnly,
                  // Fit the validating format.
                  _phoneNumberFormatter,
                ],  */
              ),
              new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new Text('Append index.php to address'),
                    new Checkbox(
                        value: _checkBoxUrlHasIndex,
                        onChanged: (bool value) {
                          onCheckBoxChanged(value);
                        }),
                  ]),
              new TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: 'Username',
                  labelText: 'Username *',
                  ),
                validator:(value){
                  if(value.isEmpty){
                    return 'Username cannot be empty';
                  }
                },
                //   onSaved: (val) => _username = val,
              ),
              new TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.lock),
                  hintText: 'Password',
                  labelText: 'Password *',
                ),
                obscureText: true,
                  validator:(value){
                      if(value.isEmpty){
                        return 'Password cannot be empty';
                         }
                    },
                //          onSaved: (val) => _password = val,
              ),
              _isLoading ? new CircularProgressIndicator() : loginBtn,
              new Container(
                padding: const EdgeInsets.only(top: 8.0),
                child: new Text('* indicates required field',
                    style: Theme.of(_context).textTheme.caption),
              ),
            ],
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
    );

    var scaffoldLoginForm = new Scaffold(
      appBar:new AppBar(title: new Text("Login"),centerTitle: true,) ,
      key: _scaffoldKey,
      backgroundColor: Colors.teal,
      body: new Container(

          decoration: new BoxDecoration(
            gradient: new LinearGradient(colors: [Colors.teal,Colors.tealAccent],
              begin: new FractionalOffset(0.0, 0.0),
              end: new FractionalOffset(0.05, 0.05),
              stops: [0.0,1.0],
              tileMode: TileMode.clamp,

            ),
            //  color: Colors.tealAccent.shade200

          ),
        child: new Center(
          child: new ClipRect(
            child: new Container(
              child: new SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  key: _scrollViewKey,
                  scrollDirection: Axis.vertical,
                  child: loginForm),
              height: 450.0,
              width: 300.0,

            ),
          ),
        ),
      ),
    );

    var _asyncLoader = new AsyncLoader(
      key: _asyncLoaderState,
      initState: () async {
        await  _getSavedServers();
        return await alreadyLoggedIn();
        },
      renderLoad: () => new Scaffold(
            body: new Center(child: new CircularProgressIndicator()),
          ),
      renderError: ([error]) => new Scaffold(
          body: new Center(child: new Text('Something is wrong'))),
      renderSuccess: ({data})  {
        if (data == 0 || data == null || _isNewServer) {


          // TOken inheritedWidget is used to pass token around
          // the application
        //  print("AsyncToken: $fcmToken");
          return scaffoldLoginForm;
        } else {
          return new TokenInheritedWidget(
              token: fcmToken, child: new MainPage());
        }
      },
    );

    return _asyncLoader;
  }

  void _submit() async {

    final form = _formKey.currentState;
    if (form.validate()) {
      setState(() => _isLoading = true);
      form.save();

      //  await updateToken(recToken);

      await _getSavedServers();

      // check if server already exists
      if (savedServersList.length > 0) {
        Server found = savedServersList.firstWhere(
            (srvr) =>
                (srvr.url == _urlController.text &&
                    srvr.username == _userNameController.text) ||
                srvr.servername == _nameController.text,
            orElse: () {});

        if (found != null) {
          _currentServer.id = found.id;
          //TODO
          //Show dialog if want to update the server details
          //Update and login
       //   _showSnackBar("This server is already added");

          // show alert to proceed or not
          _showAlert();
        } else {
          _isNewServer = true;
          _login();
        }

        //TODO
        // Decide what to do if the server is already added
        // proceed to chatlist or server information page

      } else {
        _isNewServer = true;
        _login();
      }
    }
  }

  void _resetControllers(){
    _nameController.text = _currentServer?.servername ?? "";
    _urlController.text =_currentServer?.url ??  "";
    _userNameController.text =_currentServer?.username ??  "";
    _passwordController.text =_currentServer?.password ??   "";

  }

  Future<Null> _login() async {
    if(_isNewServer) _currentServer.id = null;
    _currentServer.servername = _nameController.text;
    _currentServer.url = _urlController.text;
    _currentServer.urlhasindex = _checkBoxUrlHasIndex;
    _currentServer.username = _userNameController.text;
    _currentServer.password = _passwordController.text;
    // _currentServer.fcm_token = fcmToken;

    Server srv = await srvrRequest.login(_currentServer);

    setState(() => _isLoading = false);

    if (srv.isloggedin == Server.LOGGED_IN) {
      // we use this to fetch the already saved serverid
      _currentServer =_isNewServer ? await dbHelper.upsertServer(
          srv, null,null) :
      await dbHelper.upsertServer(
          srv, "${Server.columns['db_id']} = ? ", [srv.id]) ;


   //   print("id: "+_currentServer.id.toString());
      try {
        // fetch installation id
        // used for unique identification
        _currentServer =  await srvrRequest.fetchInstallationId(_currentServer, fcmToken,"add");

        _currentServer = await dbHelper.upsertServer(_currentServer,
            "${Server.columns['db_id']} = ?", ['${_currentServer.id}']);

        if (_currentServer.installationid.isEmpty) {
        //  _showSnackBar("Couldn't find this app's extension at the given url");
        }
      } catch (e) {
        _showSnackBar("Couldn't find this app's extension at the given url");
        return;
      }

      if (_isNewServer) {}
      // fetch user data
      await srvrRequest.getUserFromServer(_currentServer).then((user) {
        if (user != null) {
          setState(() {
            _currentServer.userid = user['id'];
            _currentServer.firstname = user['name'];
            _currentServer.surname = user['surname'];
            _currentServer.operatoremail = user['email'];
            _currentServer.job_title = user['job_title'];
            _currentServer.all_departments = user['all_departments'];
            _currentServer.departments_ids = user['departments_ids'];
          });
        }
      });

      await dbHelper.upsertServer(
          _currentServer, "id=?", [_currentServer.id]).then((srvv) {
        Navigator.of(_context).pushReplacement(new FadeRoute(
              builder: (BuildContext context) => new TokenInheritedWidget(
                    token: fcmToken,
                    //TODO
                    //Should rather go to server details page
                    // so that user can set the online hours
                    child: new MainPage(),
                  ),
              settings:
                  new RouteSettings(name: MyRoutes.list, isInitialRoute: false),
            ));

        setState(() => _isNewServer = false);
      });
    } else
      _showSnackBar("Login was not successful");
  }

  void _showSnackBar(String text) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(text)));
  }

  void onCheckBoxChanged(bool value) {
    setState(() {
      _checkBoxUrlHasIndex = value;
    });
  }

  Future<Null> _getSavedServers() async {
    savedServersList?.clear();
    List<Map> savedRecs = await dbHelper.fetchAll(
        Server.tableName, "${Server.columns['db_id']}  ASC", null, null)
    ;
    if (savedRecs != null && savedRecs.length > 0) {
      savedRecs.forEach((item) {
        setState(() {
          savedServersList.add(new Server.fromMap(item));
          _currentServer = savedServersList.elementAt(0);
        });
      });
    } else {}

    return null;
  }

  Future<int> alreadyLoggedIn() async {
    // check if previously logged in
    return await dbHelper.countRecords(
        Server.tableName, "${Server.columns['db_isloggedin']} = ?", [1]);
  }

  Future<int> updateToken(String token) async {
    int id = 0;
    if (token.isNotEmpty) id = await dbHelper.upsertFCMToken(token);

    return id;
  }

  void _showAlert() {
    AlertDialog dialog = new AlertDialog(
      content: new Text(
        "The server already exists. What do you want to do?",
        style: new TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Cancel"),
            onPressed: () {
              setState(() {
                _isLoading = false;
              });
              Navigator.of(_context).pop();
            }),
        new MaterialButton(child: new Text("Login"), onPressed: (){
          _isNewServer = false;
          _login();}),
      ],
    );

    showDialog(context: _context, builder: (BuildContext context) => dialog);
  }

  void _showAlertMsg(String title,String msg) {
    SimpleDialog
    dialog =

    new SimpleDialog(
      title: new Text(title,
        style: new TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        new Text(msg,
          style: new TextStyle(fontSize: 14.0),
        )
      ],
    );

    showDialog(context: _context, builder: (BuildContext context) => dialog );
  }
}
