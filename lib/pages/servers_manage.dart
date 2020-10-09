import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/login_form.dart';
import 'package:livehelp/utils/routes.dart' as LHCRouter;
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/widget/widget.dart';
import 'package:livehelp/utils/enum_menu_options.dart';

class ServersManage extends StatefulWidget {
  ServersManage({this.returnToList = false});
  final bool returnToList;
  @override
  ServersManageState createState() => new ServersManageState();
}

class ServersManageState extends State<ServersManage> {
  DatabaseHelper dbHelper;
  ServerApiClient _serverRequest;

  List<Server> listServers = List<Server>();

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  ValueChanged<TimeOfDay> selectTime;

  TimeOfDay selectedTime;

  String _fcmToken;

  var _tapPosition;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tokenInherited = TokenInheritedWidget.of(context);
    setState(() {
      _fcmToken = tokenInherited?.token;
    });

    var scaffold = new Scaffold(
      backgroundColor: Colors.grey.shade300,
      key: _scaffoldKey,
      appBar: new AppBar(
        title: Text("Manage Servers"),
        elevation:
            Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
        actions: <Widget>[],
      ),
      body: BlocConsumer<ServerBloc, ServerState>(
          listener: (context, state) {
            if (state is ServerInitial || state is ServerListFromDBLoading) {
              context.bloc<ServerBloc>().add(GetServerListFromDB());
            }
            if (state is ServerLoggedOut) {
              context.bloc<ServerBloc>().add(InitializeServers());
            }
          },
          builder: _bodyBuilder),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(Icons.add),
        onPressed: () {
          _addServer();
        },
      ),
    );
/*
    var _asyncLoader = new AsyncLoader(
      key: _asyncLoaderState,
      initState: () async =>  await _alreadyLoggedIn(),
      renderLoad: () => new Scaffold(
            body: new Center(child: new CircularProgressIndicator()),
          ),
      renderError: ([error]) => new Scaffold(
            body: new Center(
              child: new Text('Something is wrong'),
            ),
          ),
      renderSuccess: ({data}) {
         if (data == 0 || data == null || widget.manage) {
          return scaff;
        } else {
          return new TokenInheritedWidget(
              token: _fcmToken, child: new MainPage());
        }
       
      },
    );
    */

    return scaffold;
  }

  Widget _bodyBuilder(BuildContext context, ServerState state) {
    if (state is ServerInitial || state is ServerListFromDBLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    if (state is ServerListFromDBLoaded) {
      return new ListView.builder(
          itemCount: state.serverList.length,
          itemBuilder: (context, index) {
            Server server = state.serverList[index];
            return new GestureDetector(
              child: ServerItemWidget(
                  server: server,
                  menuBuilder: _itemMenuBuilder(),
                  onMenuSelected: (selectedOption) {}),
              onTap: () {
                if (server.loggedIn) {
                  if (widget.returnToList) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                        LHCRouter.Router.generateRoute(new RouteSettings(
                            name: LHCRouter.AppRoutes.main,
                            arguments: LHCRouter.RouteArguments())));
                  }
                } else {
                  _showAlertMsg("Not Logged In",
                      "You are logged out of this server.\n\nLongPress Server for options");
                }
              },
              onLongPress: () {
                _showCustomMenu(server);
              },
              onTapDown: _storePosition,
            );
          });
    }
    return Container();
  }

  void _addServer({Server svr}) {
    //Navigator.of(context).pop();
    Navigator.of(context).push(LHCRouter.FadeRoute(
      builder: (BuildContext context) {
        return LoginForm(
          isNew: true,
          server: svr,
        );
      },
      settings: new RouteSettings(
        name: LHCRouter.AppRoutes.login,
      ),
    ));
  }

  void _showCustomMenu(Server sv) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();

    showMenu(
            context: context,
            items: _itemMenuBuilder(),
            position: RelativeRect.fromRect(_tapPosition & Size(40, 40),
                Offset.zero & overlay.semanticBounds.size))
        // This is how you handle user selection
        .then<void>((ServerItemMenuOption option) {
      //  if (option == null) return;
      switch (option) {
        case ServerItemMenuOption.MODIFY:
          _addServer(svr: sv);
          break;
        case ServerItemMenuOption.REMOVE:
          _showAlert(context, sv);
          break;
        default:
          break;
      }
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

/*
  Future<Null> _getSavedServers() async {
    setState(() {
      listServers.clear();
    });

    List<Map> savedRecs = await dbHelper.fetchAll(
        Server.tableName, "${Server.columns['db_id']}  ASC", null, null);

    if (savedRecs != null && savedRecs.length > 0) {
      savedRecs.forEach((item) {
        if (!(listServers.any((serv) =>
            serv.servername == item['servername'] &&
            serv.url == item['url'] &&
            serv.username == item['username']))) {
          setState(() {
            listServers.add(new Server.fromMap(item));
          });
        }
      });
    }
  }  */

  List<PopupMenuEntry<ServerItemMenuOption>> _itemMenuBuilder() {
    return <PopupMenuEntry<ServerItemMenuOption>>[
      const PopupMenuItem<ServerItemMenuOption>(
        value: ServerItemMenuOption.MODIFY,
        child: const Text('Modify / Login'),
      ),
      const PopupMenuItem<ServerItemMenuOption>(
        value: ServerItemMenuOption.REMOVE,
        child: const Text('Remove'),
      ),
    ];
  }

  void _showAlert(BuildContext context, Server srvr) {
    AlertDialog dialog = new AlertDialog(
      content: new Text(
        "Do you want to remove the server?",
        style: new TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Yes"),
            onPressed: () async {
              String fcmToken = context.bloc<FcmTokenBloc>().token;
              //TODO: Show loading indicator
              context.bloc<ServerBloc>().add(LogoutServer(
                  server: srvr, fcmToken: fcmToken, deleteServer: true));
              Navigator.of(context).pop();
            }),
        MaterialButton(
            child: new Text("No"),
            onPressed: () async {
              Navigator.of(context).pop();
            }),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  Future<bool> _deleteServer(Server srvr) async {
    return dbHelper.deleteItem(Server.tableName, "id=?", [srvr.id]);
  }

  void _showAlertMsg(String title, String msg) {
    SimpleDialog dialog = new SimpleDialog(
      titlePadding: const EdgeInsets.fromLTRB(16.00, 8.00, 16.00, 8.00),
      contentPadding: const EdgeInsets.fromLTRB(8.00, 0.00, 16.00, 8.00),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.00),
          child: Text(
            msg,
            style: TextStyle(fontSize: 14.0),
          ),
        ),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }
}
