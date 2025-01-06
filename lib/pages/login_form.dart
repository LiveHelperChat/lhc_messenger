import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/main.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/main_page.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/utils/utils.dart';

const TIMEOUT = const Duration(seconds: 5);

class LoginForm extends StatefulWidget {
  LoginForm({Key? key, this.server}) : super(key: key);

  final Server? server;

  @override
  State<StatefulWidget> createState() {
    return new LoginFormState();
  }
}

class LoginFormState extends State<LoginForm> {
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _scrollViewKey = new GlobalKey<ScaffoldState>();

  final TextEditingController _nameController = new TextEditingController();
  final TextEditingController _urlController = new TextEditingController();
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _passwordController = new TextEditingController();

  Server? _currentServer;
  DatabaseHelper? _dbHelper;

  ServerApiClient srvrRequest = new ServerApiClient(httpClient: http.Client());

  bool _checkBoxUrlHasIndex = true;
  @override
  initState() {
    super.initState();
    // _resetControllers();
    _dbHelper = new DatabaseHelper();

    _initServer(widget.server);
  }

  // Instantiate the Formfields.  Note we provide persisters for each.
  //
  @override
  Widget build(BuildContext context) {
    var loginBtn = Container(
        width: 150,
        padding: const EdgeInsets.only(top: 8.0),
        child: new ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => Colors.grey.shade500,
            ),
          ),
          onPressed: () {
            _submit(context);
          },
          child: new Text(
            "LOGIN",
            style: new TextStyle(color: Colors.white),
          ),
        ));

    var loginDemoBtn = Container(
        width: 150,
        padding: const EdgeInsets.only(top: 8.0),
        child: new ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => Colors.grey.shade500,
            ),
          ),
          onPressed: () {
            _fillDemo(context);
          },
          child: new Text(
            "Demo logins",
            style: new TextStyle(color: Colors.white),
          ),
          // color: Colors.grey.shade500,
        ));

    var loginForm = Column(
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                  controller: _nameController,
                  //      onSaved: (val) => _server_name = val,
                  decoration: const InputDecoration(
                      icon: const Icon(Icons.web),
                      hintText: 'Name of site',
                      labelText: 'Server Name *'),
                  //  onSaved: (String value) { person.name = value; },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'A name is required for this server';
                    }
                    return null;
                  }),
              TextFormField(
                controller: _urlController,
                onChanged: (value) {},
                decoration: const InputDecoration(
                  icon: const Icon(Icons.http),
                  hintText: 'http://yourdomain.com/',
                  labelText: 'Url (no trailing slash /)*',
                ),
                keyboardType: TextInputType.url,
                onSaved: (val) {},
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Address cannot be empty';
                  }
                  return null;
                },
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Checkbox(
                        value: _checkBoxUrlHasIndex,
                        onChanged: (bool? value) {
                          onCheckBoxUrlHasIndexChanged(value!);
                        }),
                    Text('Append index.php to address'),
                  ]),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: 'Username',
                  labelText: 'Username *',
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Username cannot be empty';
                  }
                  return null;
                },
                //   onSaved: (val) => _username = val,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  icon: const Icon(Icons.lock),
                  hintText: 'Password',
                  labelText: 'Password *',
                ),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Password cannot be empty';
                  }
                  return null;
                },
                //          onSaved: (val) => _password = val,
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('* indicates required field',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              SizedBox(
                height: 10,
              ),
              BlocBuilder<LoginformBloc, LoginformState>(
                  builder: (context, state) {
                if (state is ServerLoginStarted) {
                  return CircularProgressIndicator();
                } else {
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        loginBtn,
                        SizedBox(
                          width: 10,
                        ),
                        loginDemoBtn,
                      ]);
                }
              })
            ],
          ),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.center,
    );

    var scaffoldLoginForm = Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Login"),
        centerTitle: true,
      ),
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            key: _scrollViewKey,
            scrollDirection: Axis.vertical,
            child: Container(
              decoration: new BoxDecoration(color: Colors.white),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: loginForm,
                width: MediaQuery.of(context).size.width,
              ),
            )),
      ),
    );

    return BlocConsumer<LoginformBloc, LoginformState>(
        listener: (context, state) {
      if (state is ServerLoginError) {
        //Show Error message
        _showSnackBar(state.message!);
      }
      if (state is LoginServerSelected) {
        _currentServer = state.server;
      }
      if (state is ServerLoginSuccess) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          sharedPreferences?.setBool("isLoggedIn", true);
          Navigator.of(context).pushAndRemoveUntil(
              FadeRoute(
                builder: (BuildContext context) => MainPage(),
                settings: RouteSettings(
                  name: AppRoutes.home,
                ),
              ),
              (Route<dynamic> route) => false);
        });
      }
    }, builder: (context, state) {
      return scaffoldLoginForm;
    });
  }

  void _fillDemo(BuildContext context) async {
    _nameController.text = 'Live Helper Chat Demo';
    _userNameController.text = 'admin';
    _passwordController.text = 'demo';
    _urlController.text = 'https://demo.livehelperchat.com';
  }

  void _submit(BuildContext context) async {
    try {
      final form = _formKey.currentState;
      if (form!.validate()) {
        form.save();

        _currentServer!.servername = _nameController.text;
        _currentServer!.url = _urlController.text;
        _currentServer!.appendIndexToUrl = _checkBoxUrlHasIndex;
        _currentServer!.username = _userNameController.text;
        _currentServer!.password = _passwordController.text;

        String fcmtoken = context.read<FcmTokenBloc>().token;
        context
            .read<LoginformBloc>()
            .add(ServerLogin(server: _currentServer!, fcmToken: fcmtoken));
      }
    } catch (ex) {}
  }

  void _resetControllers() {
    _nameController.text = _currentServer?.servername ?? "";
    _urlController.text = _currentServer?.url ?? "";
    _userNameController.text = _currentServer?.username ?? "";
    _passwordController.text = _currentServer?.password ?? "";
  }

  void _initServer(server) {
    if (server != null) {
      setState(() {
        _currentServer = server;
        _resetControllers();
      });
    } else
      _currentServer = new Server();
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  void onCheckBoxUrlHasIndexChanged(bool value) {
    setState(() {
      _checkBoxUrlHasIndex = value;
    });
  }

  Future<int?> updateToken(String token) async {
    int? id = 0;
    if (token.isNotEmpty) id = await _dbHelper?.upsertFCMToken(token);

    return id;
  }

  // void _showAlertMsg(String title, String msg) {
  //   SimpleDialog dialog = new SimpleDialog(
  //     title: new Text(
  //       title,
  //       style: new TextStyle(fontSize: 14.0),
  //     ),
  //     children: <Widget>[
  //       new Text(
  //         msg,
  //         style: new TextStyle(fontSize: 14.0),
  //       )
  //     ],
  //   );

  //   showDialog(context: context, builder: (BuildContext context) => dialog);
  // }
}
