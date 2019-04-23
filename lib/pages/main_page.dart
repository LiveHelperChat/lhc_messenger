import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';

import 'package:async_loader/async_loader.dart';
import 'package:after_layout/after_layout.dart';

import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/utils/server_requests.dart';
import 'package:livehelp/pages/loginForm.dart';
import 'package:livehelp/pages/chat_list_active.dart';
import 'package:livehelp/pages/chat_list_pending.dart';
import 'package:livehelp/pages/chat_list_transferred.dart';
import 'package:livehelp/pages/server_details.dart';
import 'package:livehelp/widget/chat_number_indicator.dart';
import 'package:livehelp/widget/expansion_panel.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin<MainPage> {
  // used to track application lifecycle
  AppLifecycleState _lastLifecyleState;
  BuildContext _context;

  final GlobalKey<AsyncLoaderState> _mainAsyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final int extensionVersion = 12; //(0.1.2)

  TabController tabBarController;

  ServerRequest _serverRequest = new ServerRequest();
  DatabaseHelper dbHelper;

  List<Server> listServers = new List<Server>();
  List<Chat> _activeChatList = new List<Chat>();
  List<Chat> _pendingChatList = new List<Chat>();
  List<Chat> _transferedChatList = new List<Chat>();

  List<dynamic> activeChatStore = new List();
  List<dynamic> pendingChatStore = new List();
  List<dynamic> transferChatStore = new List();

  bool _actionLoading = false;

  Timer _timer;
  String _fcmToken;
  Server _selectedServer;
  bool _user_online;
  bool _userOnlineLoading = false;

  bool _showUpdateNotice = false;
  bool initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // for controlling the tabbar
    tabBarController = new TabController(length: 3, vsync: this);

    dbHelper = new DatabaseHelper();

    _timer = myTimer(15);

    _user_online = false;

    // _getChatList();
  }

  @override
  void dispose() {
    tabBarController.dispose();

    _timer.cancel();

    WidgetsBinding.instance.removeObserver(this);
    _serverRequest.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecyleState = state;
    });

    _checkState();
  }

  void _checkState() {
    switch (_lastLifecyleState) {
      case AppLifecycleState.resumed:
        _timer = myTimer(15);
        //  showUpdateMsg();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_timer.isActive) _timer.cancel();
        break;
      default:
        break;
    }
  }

  //final String token;
  @override
  Widget build(BuildContext context) {

   // dbHelper.debug();

    _context = context;
    final tokenInherited = TokenInheritedWidget.of(_context);
    _fcmToken = tokenInherited.token;

    // get user online status
    // if (_selectedServer != null)_getOnlineStatus();

    Widget loadingIndicator =
        _actionLoading ? new CircularProgressIndicator() : new Container();

    var mainScaffold = new Scaffold(
      backgroundColor: Colors.black26,
        appBar: new AppBar(
          title: new Text("Chat Lists"),
          bottom: new TabBar(controller: tabBarController, tabs: <Tab>[
            new Tab(
              child: new ChatNumberIndcator(
                title: "Active",
                offstage: _activeChatList.length == 0,
                number: _activeChatList.length.toString(),
              ),
            ),
            new Tab(
              child: new ChatNumberIndcator(
                title: "Pending",
                offstage: _pendingChatList.length == 0,
                number: _pendingChatList.length.toString(),
              ),
            ),
            new Tab(
                child: new ChatNumberIndcator(
              title: "Transferred",
              offstage: _transferedChatList.length == 0,
              number: _transferedChatList.length.toString(),
            )),
          ]),
        ),
        drawer: new Drawer(
            child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              new UserAccountsDrawerHeader(
                accountName: new Text(
                  _selectedServer?.servername ?? "",
                  style: new TextStyle(color: Colors.deepOrange),
                ),
                accountEmail: _selectedServer?.isloggedin == 1 ?? false
                    ? new Text("Logged In")
                    : new Text("Logged Out"),
                currentAccountPicture: new GestureDetector(
                  child: new CircleAvatar(
                    child: new Text(
                        _selectedServer?.servername?.substring(0, 1) ?? ""),
                  ),
                  onTap: () => {},
                ),
                /*  otherAccountsPictures: <Widget>[
                new GestureDetector(
                  child: new CircleAvatar(
                    child: new Text(_selectedServer?.servername?.substring(0, 1) ?? ""),
                  ),
                  onTap: () {},
                ),
              ],  */
                decoration: new BoxDecoration(
                    image: new DecorationImage(
                        image: new AssetImage('graphics/header.jpg'),
                        fit: BoxFit.fill)),
              ),

              new AnimateExpanded(
                title: _selectedServer?.servername,
                subtitle: _selectedServer?.url,
                contentWidgetList: <Widget>[
                  new Expanded(
                    child: new ListView.builder(
                        itemCount: listServers.length,
                        itemBuilder: (_, index) {
                          Server ssrvr = listServers[index];
                          return new Offstage(
                            offstage: _selectedServer == ssrvr,
                            child: new ListTile(
                              title: new Text(ssrvr.servername ?? ""),
                              subtitle: new Text(
                                ssrvr.url ?? "",
                                style: new TextStyle(fontSize: 10.0),
                                overflow: TextOverflow.fade,
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedServer = ssrvr;
                                  showUpdateMsg();
                                });
                              },
                            ),
                          );
                        }),
                  ),
                ],
              ),
              new Divider(),
              new Card(
                child: new Container(
                  height: 65.0,
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new Expanded(
                        child: new ListTile(
                          title: new Text(
                              "${_selectedServer?.firstname ?? ""} ${_selectedServer?.surname ?? ""}"),
                          subtitle: _selectedServer?.user_online == 1 ?? false
                              ? new Text(
                                  "Operator Online",
                                  style: new TextStyle(fontSize: 10.0),
                                )
                              : new Text("Operator Offline",
                                  style: new TextStyle(fontSize: 10.0)),
                          trailing: _userOnlineLoading
                              ? new CircularProgressIndicator()
                              : new IconButton(
                                  icon:
                                      _selectedServer?.user_online == 1 ?? false
                                          ? new Icon(Icons.flash_on)
                                          : new Icon(Icons.flash_off),
                                  onPressed: () {
                                    setState(() {
                                      _userOnlineLoading = true;
                                    });
                                    _setOnlineStatus();
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              new ListTile(
                  title: new Text("Server Info"),
                  leading: new Icon(Icons.web),
                  onTap: () {
                    Navigator.of(_context).pop();
                    Navigator.of(_context).push(
                      new FadeRoute(
                        builder: (BuildContext context) =>
                            new TokenInheritedWidget(
                                token: _fcmToken,
                                //TODO
                                //Should rather go to server details page
                                // so that user can set the online hours
                                child: new ServerDetails(
                                  server: _selectedServer,
                                )),
                        settings: new RouteSettings(
                            name: "/server", isInitialRoute: false),
                      ),
                    );
                  }),
              new Divider(),
              new ListTile(
                leading: new Icon(Icons.add),
                title: new Text("Add New Server"),
                onTap: () => _addServer(),
              ),

              /*    new ListTile(
              title: new Text("Settings"),
              leading: new Icon(Icons.settings),
              onTap: () {
                Navigator.of(_context).pop();
                Navigator.of(_context).push(
                  new FadeRoute(
                    builder: (BuildContext context) =>
                     new ServerSettings(
                          server: _selectedServer,
                        ),
                    settings: new RouteSettings(
                        name: "/server/settings", isInitialRoute: false),
                  ),
                );
              } ,
            ),*/
              new Divider(),
              new ListTile(
                title: new Text("Logout"),
                trailing: new Icon(Icons.cancel),
                onTap: () {
                  Navigator.pop(_context);
                  _showAlert();
                },
              ),

// TODO move version number to main and inherit it
              /*           Expanded(
                child:Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Text("v1.2.3"),
                )
            )
            */
            ],
          ),
        )),
        body: new Stack(children: <Widget>[
          new TabBarView(
              controller: tabBarController,
              children: <Widget>[
            Container(
              color: Colors.black26,
              child: new ActiveListWidget(
                listOfServers: listServers,
                listToAdd: _activeChatList,
                loadingState: onActionLoading,
                refreshList: _getChatList,
              ),
            ),

            new PendingListWidget(
              listOfServers: listServers,
              listToAdd: _pendingChatList,
              loadingState: onActionLoading,
            ),
            new TransferredListWidget(
              listOfServers: listServers,
              listToAdd: _transferedChatList,
              loadingState: onActionLoading,
            )
          ]),
          new Center(child: loadingIndicator),
        ]),
        floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.refresh),
          onPressed: () {
            /*    setState(() {
              _actionLoading = true;
            });  */
            _getChatList();
          },

        ),
        bottomNavigationBar: Offstage(
          child: GestureDetector(
            onTap: () => _showBottomSheet(context),
            child: PreferredSize(
              preferredSize: const Size.fromHeight(48.0),
              child: Theme(
                data: Theme.of(context).copyWith(accentColor: Colors.white),
                child: Container(
                  color: Colors.red,
                  height: 48.0,
                  alignment: Alignment.center,
                  child: Text(
                    'Extension Update: Click me for more details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          offstage: !_showUpdateNotice,
        ));

    var _asyncLoader = new AsyncLoader(
      key: _mainAsyncLoaderState,
      initState: () async {
        //TODO added return (might not be needed)
        // await _getSavedServers();
        return _getChatList();
      },
      renderLoad: () => new Scaffold(
            body: new Center(child: new CircularProgressIndicator()),
          ),
      renderError: ([error]) =>
          new Scaffold(body: new Center(child: new Text('Something is wrong'))),
      renderSuccess: ({data}) {
        return mainScaffold;
      },
    );

    return _asyncLoader;
  }

  void _addServer() {
    Navigator.of(_context).pop();
    Navigator.of(_context).pushReplacement(new FadeRoute(
      builder: (BuildContext context) => new TokenInheritedWidget(
          token: _fcmToken, child: new LoginForm(isNew: true)),
      settings: new RouteSettings(name: MyRoutes.list, isInitialRoute: false),
    ));
  }

  Timer myTimer(int seconds) {
    //fetch list first
    new Timer(const Duration(milliseconds: 3000), () => _getChatList(istimer: true));

    return new Timer.periodic(
        new Duration(seconds: seconds), (Timer timer) => _getChatList(istimer: true));
  }

  void onActionLoading(bool val) {
    setState(() {
      _actionLoading = val;
    });
  }

  // TODO Remove
  void onChatRemoved(Chat chat) {
    assert(chat != null);
    switch (chat.status.toString()) {
      case '1':
        setState(() {
          this._activeChatList.removeWhere((cht) => cht.id == chat.id);
        });
        break;
    }
  }

  Future<Null> _getChatList({istimer=false}) async {
    if (!_actionLoading && initialized) {


     if(!istimer) onActionLoading(true);

      // TODO remove this line
      await _getSavedServers();

      listServers.forEach((server) async {
        if (server.isloggedin == 1) {
          //getChatList
           _serverRequest.getChatLists(server).then((srvr) {
            if (srvr.activeChatList != null && srvr.activeChatList.length > 0) {
              setState(() {
                _activeChatList =
                    cleanUpLists(_activeChatList, srvr.activeChatList);
                _activeChatList
                    .sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
              });
            } else {
              setState(() {
                _activeChatList
                    ?.removeWhere((chat) => chat.serverid == server.id);
              });
            }

            if (srvr.pendingChatList != null && srvr.pendingChatList.length > 0) {
              setState(() {
                _pendingChatList = cleanUpLists(_pendingChatList, srvr.pendingChatList);
                _pendingChatList.sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
              });
            } else {
              setState(() {
                _pendingChatList?.removeWhere((chat) => chat.serverid == server.id);
              });
            }

            if (srvr.transferChatList != null &&
                srvr.transferChatList.length > 0) {
              //transferChatStore.addAll(srvr.transferChatList);
              setState(() {
                _transferedChatList = cleanUpLists(_transferedChatList, srvr.transferChatList);
                _transferedChatList.sort((a, b) => a.last_msg_id.compareTo(b.last_msg_id));
              });
            } else {
              _transferedChatList?.removeWhere((chat) => chat.serverid == server.id);
            }

            onActionLoading(false);
          });
        }
      });

    }
  }

  List<Chat> cleanUpLists(
      List<Chat> chatToClean, List<dynamic> listFromServer) {
    listFromServer.map((map) => new Chat.fromMap(map));
    listFromServer.forEach((map) {
      // Chat tempChat = new Chat.fromMap(map);

      // print("ListMessage: " + message.toMap().toString());
      if (chatToClean
          .any((chat) => chat.id == map.id && chat.serverid == map.serverid)) {
        int index = chatToClean.indexWhere(
            (chat) => chat.id == map.id && chat.serverid == map.serverid);
        chatToClean[index] = map;
        // print("Active_ " + map.toString());
      } else {
        chatToClean.add(map);
      }

      // cleanup  list

      if (chatToClean.length > 0 && listFromServer.length > 0) {
        List<int> removedIndices = new List();
        chatToClean.forEach((chat) {
          if (!listFromServer.any(
              (map) => map.id == chat.id && map.serverid == chat.serverid)) {
            int index = chatToClean.indexOf(chat);
            // print("index: " + index.toString());
            removedIndices.add(index);
          }
        });
        //remove the chats
        if (removedIndices != null && removedIndices.length > 0) {
          removedIndices.sort();
          removedIndices.reversed.toList().forEach(chatToClean.removeAt);
          removedIndices.clear();
        }
      }
    });
    return chatToClean;
  }

  Future<Null> _getSavedServers() async {
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
        if (_selectedServer == null) {
          setState(() {
            _selectedServer = listServers.elementAt(0);
          });
          _getOnlineStatus();

          //TODO Remove in future updates
          // check extension update
          showUpdateMsg();
        }
      });
    } else {}
  }

  Future<Null> _logout() async {
    _selectedServer.isloggedin = 0;

    await dbHelper.upsertServer(
        _selectedServer, "id=?", [_selectedServer.id]).then((srv) {});
  }

  void _showAlert() {
    AlertDialog dialog = new AlertDialog(
      content: new Text(
        "Logged out successfully. Do you want to remove the server?",
        style: new TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Keep Server"),
            onPressed: () async {
              Navigator.of(_context).pop();
               _logout().then((_) => _addServer());
            }),
        new MaterialButton(
            child: new Text("Remove Server"),
            onPressed: () async {
               _deleteServer().then((_) => _addServer());
            //  Navigator.of(_context).pop();
            }),
      ],
    );

    showDialog(context: _context, builder: (BuildContext context) => dialog);
  }

  Future<Null> _deleteServer() async {
    await _serverRequest
        .fetchInstallationId(_selectedServer, _fcmToken, "logout")
        .then((srv) {
      dbHelper.deleteItem(Server.tableName, "id=?", [_selectedServer.id]);
    });
  }

  Future<Null> _getOnlineStatus() async {
    _serverRequest.getUserOnlineStatus(_selectedServer).then((isOnline) {
      if (_user_online != isOnline) {
        setState(() {
          _user_online = isOnline;
          _selectedServer.user_online = isOnline ? 1 : 0;
        });

        dbHelper.upsertServer(_selectedServer, "id=?", [_selectedServer.id]);
      }
    });
  }

  Future<Null> _setOnlineStatus() async {
    await _serverRequest.setUserOnlineStatus(_selectedServer).then((online) {
      setState(() {
        _selectedServer.user_online = online ? 1 : 0;
      });
    });
    await dbHelper
        .upsertServer(_selectedServer, "id=?", [_selectedServer.id]).then(
            (ssrv) => setState(() {
                  _selectedServer = ssrv;
                }));

    setState(() {
      _userOnlineLoading = false;
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      initialized = true;
    });
    if (_selectedServer != null) showUpdateMsg();
  }

  showUpdateMsg() async {
    // fetch extension version from Database
   Map<String,dynamic> configs = await  dbHelper.fetchItem(dbHelper.configTable, null, null);

   String storedVS = configs !=null ? configs[dbHelper.extVersionColumn] : null;

   _serverRequest.fetchVersionExt(_selectedServer).then((version) {
     if (version != null) {

       if(storedVS != null ){
     if(storedVS.isNotEmpty){
       // returned format is 0.1.2
       // remove the . and parse to int and compare
       num installVersion = num.tryParse(_parseVersion(version));
       num oldVersion  = num.tryParse(_parseVersion(storedVS));

       if (installVersion != null && installVersion >= oldVersion) {
         // print(vss.toString());
         _showUpdateNotice = false;
       } else {
         _showUpdateNotice = true;
         //_showBottomSheet(version);
       }
     }

       }
       else {
         var vsMap = {dbHelper.extVersionColumn:version};
         // Upsert config table
         dbHelper.upsertGeneral(dbHelper.configTable, vsMap); }

     } else {
       // _showUpdateNotice = true;
     }
   });

  }

  String _parseVersion(String vs){
   return vs.replaceAll(new RegExp(r'\.'), '');
  }

  _showBottomSheet(BuildContext ctx) {
    showModalBottomSheet<void>(
        context: ctx,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(10.0),
            height: 300.0,
            color: Colors.green,
            child: Center(
              child: new Text(
                "You can now receive notifications when the app is active.\n\nPlease update the Extension on your server to receive notifications. You can simply replace all the content in \'/extension/gcm\' with the new one from github. \n\n Visit: \n https://github.com/samapraku/lhc_gcm_extension \n\n\nDon't forget to clear your LHC cache for the update to reflect.",
                style: TextStyle(color: Colors.white),
                softWrap: true,
              ),
            ),
          );
        });
  }
}
