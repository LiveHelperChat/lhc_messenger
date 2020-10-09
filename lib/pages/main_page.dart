import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:after_layout/after_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/pages.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/services/twilio_service.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/widget/widget.dart';

import 'lists/chat_list_active.dart';

class MainPage extends StatefulWidget {
  const MainPage();

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

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final int extensionVersion = 12; //(0.1.2)

  TwilioService _twilioService = new TwilioService(httpClient: http.Client());

  List<Server> listServers = new List<Server>();
  List<Chat> _activeChatList = new List<Chat>();
  List<Chat> _pendingChatList = new List<Chat>();
  List<Chat> _transferedChatList = new List<Chat>();
  List<Chat> _twilioChatList = new List<Chat>();

  List<dynamic> activeChatStore = new List();
  List<dynamic> pendingChatStore = new List();
  List<dynamic> transferChatStore = new List();

  bool _actionLoading = false;

  Timer _timerChatList;
  String _fcmToken;
  Server _selectedServer;
  bool _user_online;
  bool _userOnlineLoading = false;

  bool _showUpdateNotice = false;
  bool initialized = false;
  bool isTwilioActive = false;
  DatabaseHelper dbHelper = DatabaseHelper();
  ServerApiClient _serverRequest;

  ChatslistBloc _chatListBloc;
  ServerBloc _serverBloc;

  @override
  void initState() {
    super.initState();
    _serverRequest = ServerApiClient(httpClient: http.Client());

    WidgetsBinding.instance.addObserver(this);

    _user_online = false;

    _serverBloc = context.bloc<ServerBloc>();
    _serverBloc.add(GetServerListFromDB(onlyLoggedIn: true));
    _chatListBloc = context.bloc<ChatslistBloc>();
    _loadChatList();

    _timerChatList = myTimer(5);
  }

  @override
  void dispose() {
    _timerChatList.cancel();

    WidgetsBinding.instance.removeObserver(this);
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
        if (!_timerChatList.isActive) {
          _timerChatList = myTimer(5);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_timerChatList.isActive) _timerChatList.cancel();
        break;
      default:
        break;
    }
  }

  //final String token;
  @override
  Widget build(BuildContext context) {
    if (_timerChatList == null) {
      _timerChatList = new Timer.periodic(
          new Duration(seconds: 10), (Timer timer) => _loadChatList()); //
    }

    var tabs = <Tab>[
      Tab(
        child: BlocBuilder<ChatslistBloc, ChatListState>(
            builder: (context, state) {
          if (state is ChatListLoaded) {
            return ChatNumberIndcator(
              title: "Active",
              offstage: state.activeChatList.length == 0,
              number: state.activeChatList.length.toString(),
            );
          }
          return ChatNumberIndcator(
            title: "Active",
            offstage: true,
            number: "0",
          );
        }),
      ),
      Tab(
        child: BlocBuilder<ChatslistBloc, ChatListState>(
            builder: (context, state) {
          if (state is ChatListLoaded) {
            return ChatNumberIndcator(
              title: "Pending",
              offstage: state.pendingChatList.length == 0,
              number: state.pendingChatList.length.toString(),
            );
          }
          return ChatNumberIndcator(
            title: "Pending",
            offstage: true,
            number: "0",
          );
        }),
      ),
      Tab(
        child: BlocBuilder<ChatslistBloc, ChatListState>(
            builder: (context, state) {
          if (state is ChatListLoaded) {
            return ChatNumberIndcator(
              title: "Transfer",
              offstage: state.transferChatList.length == 0,
              number: state.transferChatList.length.toString(),
            );
          }
          return ChatNumberIndcator(
            title: "Transfer",
            offstage: true,
            number: "0",
          );
        }),
      )
    ];

//TODO
/*   if (_selectedServer != null && _selectedServer.twilioInstalled == true) {
      tabs.add(Tab(
          child: new ChatNumberIndcator(
        title: "SMS",
        offstage: _twilioChatList?.length == 0,
        number: _twilioChatList?.length.toString(),
      )));
      bodyWidgets.add(ActiveListWidget(
        listOfServers: listServers,
        chatListStream: _chatsListBloc.twilioChatList$,
        loadingState: onActionLoading,
        refreshList: _initLists,
      ));
    }
*/
    var mainScaffold = DefaultTabController(
        length: tabs.length,
        child:
            BlocConsumer<ServerBloc, ServerState>(listener: (context, state) {
          if (state is ServerInitial) {
            _chatListBloc.add(ChatListInitialise());
          }

          if (state is ServerListFromDBLoaded) {
            listServers = state.serverList;
            if (state.serverList?.isNotEmpty ?? false) {
              _selectedServer = state.serverList.elementAt(0);
            } else {
              _loadServerManage(context);
            }
          }
        }, builder: (context, state) {
          if (state is ServerListFromDBLoaded) {
            return Scaffold(
              backgroundColor: Colors.white,
              key: _scaffoldKey,
              appBar: AppBar(
                title: Text("Chat Lists"),
                bottom: TabBar(tabs: tabs),
              ),
              drawer: Drawer(
                  child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    UserAccountsDrawerHeader(
                      accountName: Text(""),
                      accountEmail: Container(
                        child: DropdownButton(
                            isExpanded: true,
                            value: state.serverList.isNotEmpty
                                ? state.serverList.elementAt(0)
                                : null,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            items: listServers.map((srvr) {
                              return new DropdownMenuItem(
                                value: srvr,
                                child: new Text(
                                  '${srvr?.servername}',
                                  style: TextStyle(color: Colors.teal.shade900),
                                ),
                              );
                            }).toList(),
                            onChanged: (srv) {
                              _serverBloc.add(SelectServer(server: srv));
                            }),
                      ),
                      currentAccountPicture: GestureDetector(
                        child: new CircleAvatar(
                          child: new Text(
                            state.selectedServer?.servername?.substring(0, 1) ??
                                "",
                            style: TextStyle(
                                fontSize: 18.00, fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () => {},
                      ),
                      decoration: new BoxDecoration(
                          image: new DecorationImage(
                              image: new AssetImage('graphics/header.jpg'),
                              fit: BoxFit.fill)),
                    ),
                    Card(
                      child: new Container(
                        height: 150.0,
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            ListTile(
                              title: state.selectedServer?.url == null
                                  ? Text("")
                                  : Text(
                                      "${state.selectedServer?.url}",
                                      style: TextStyle(fontSize: 11.0),
                                      textAlign: TextAlign.left,
                                      overflow: TextOverflow.fade,
                                      maxLines: 2,
                                      softWrap: true,
                                    ),
                              subtitle: state.selectedServer?.loggedIn ?? false
                                  ? Text("Logged In",
                                      style: TextStyle(color: Colors.green))
                                  : Text("Logged Out",
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                            ),
                            ListTile(
                              title: Text(
                                  "${state.selectedServer?.firstname ?? ""} ${state.selectedServer?.surname ?? ""}"),
                              subtitle:
                                  state.selectedServer?.user_online == 1 ??
                                          false
                                      ? Text(
                                          "Operator Online",
                                          style: new TextStyle(fontSize: 10.0),
                                        )
                                      : Text("Operator Offline",
                                          style: new TextStyle(fontSize: 10.0)),
                              trailing: state.isActionLoading
                                  ? CircularProgressIndicator()
                                  : IconButton(
                                      icon: state.selectedServer?.user_online ==
                                                  1 ??
                                              false
                                          ? Icon(
                                              Icons.flash_on,
                                              color: Colors.green,
                                            )
                                          : Icon(
                                              Icons.flash_off,
                                              color: Colors.red,
                                            ),
                                      onPressed: () {
                                        if ((state.selectedServer?.loggedIn ??
                                            false)) {
                                          _serverBloc.add(SetUserOnlineStatus(
                                              server: state.selectedServer));
                                        } else {
                                          Navigator.of(context).pop();
                                          _showSnackBar(
                                              "You are not logged in to the server");
                                        }
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(),
                    ListTile(
                        title: Text("Server Details"),
                        leading: Icon(Icons.web),
                        onTap: () {
                          if (state.selectedServer.loggedIn) {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              FadeRoute(
                                builder: (BuildContext context) =>
                                    ServerDetails(
                                  server: state.selectedServer,
                                ),
                                settings: new RouteSettings(
                                  name: AppRoutes.serverDetails,
                                ),
                              ),
                            );
                          } else {
                            Navigator.of(context).pop();
                            _showSnackBar(
                                "You are not logged in to the server");
                          }
                        }),
                    ListTile(
                      title: Text("Manage Servers"),
                      leading: Icon(Icons.settings),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          FadeRoute(
                            builder: (BuildContext context) => ServersManage(
                              returnToList: true,
                            ),
                            settings: RouteSettings(
                              name: AppRoutes.serversManage,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(),
                    _isServerLoggedIn()
                        ? ListTile(
                            title: Text("Logout Server"),
                            leading: Icon(Icons.exit_to_app),
                            onTap: () {
                              if (_isServerLoggedIn()) {
                                Navigator.pop(context);
                                _showAlert(context, state.selectedServer);
                              } else {
                                Navigator.of(context).pop();
                                _showSnackBar(
                                    "You are not logged in to the server");
                              }
                            },
                          )
                        : ListTile(
                            title: Text("Login"),
                            leading: Icon(Icons.exit_to_app),
                            onTap: () {
                              Navigator.pop(context);
                              _addServer(server: state.selectedServer);
                            },
                          ),
                  ],
                ),
              )),
              body: _bodyBuilder(context, state),
              floatingActionButton: _speedDial(context),
            );
          }

          return Text("No active Server");
        }));

    return mainScaffold;
  }

  Widget _bodyBuilder(BuildContext context, ServerState state) {
    var bodyWidgets = <Widget>[
      ActiveListWidget(
        listOfServers: listServers,
        refreshList: _loadChatList,
        callbackCloseChat: (server, chat) {
          _chatListBloc.add(CloseChatMainPage(server: server, chat: chat));
        },
        callBackDeleteChat: (server, chat) {
          _chatListBloc.add(DeleteChatMainPage(server: server, chat: chat));
        },
      ),
      PendingListWidget(
        listOfServers: listServers,
        refreshList: _loadChatList,
        callBackDeleteChat: (server, chat) {
          _chatListBloc.add(DeleteChatMainPage(server: server, chat: chat));
        },
      ),
      TransferredListWidget(
        listOfServers: listServers,
        refreshList: _loadChatList,
      ),
    ];

    if (state is ServerInitial) {
      _loadChatList();
      return Center(child: CircularProgressIndicator());
    }

    if (state is ServerListFromDBLoaded) {
      if (state.serverList?.isNotEmpty ?? false) {
        print("Servers Length: ${state.serverList.length}");
        // _selectedServer = state.serverList.elementAt(0);
        listServers = state.serverList;

        // _loadChatList();
      }
    }
    if (state is ServerFromDBLoadError) {
      return ErrorReloadButton(
          message: state.message,
          onButtonPress: () {
            _loadChatList();
          },
          actionText: 'Reload');
    }

    return Stack(children: <Widget>[
      new TabBarView(children: bodyWidgets),
      BlocBuilder<ChatslistBloc, ChatListState>(builder: (context, state) {
        if (state is ChatListLoaded && state.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        return Container();
      })
    ]);
  }

  void _loadChatList() {
    listServers.forEach((server) {
      _chatListBloc.add(FetchChatsList(server: server));
    });
  }

  void _loadServerManage(BuildContext context) {
    // navigate to server management page if no server exists
    Navigator.of(context).pushAndRemoveUntil(
        FadeRoute(
          builder: (BuildContext context) => ServersManage(
            returnToList: false,
          ),
          settings: RouteSettings(
            name: AppRoutes.server,
          ),
        ),
        (Route<dynamic> route) => false);
  }

  void _addList(List<Chat> chatList, List<Chat> toAdd) {
    //Remove deleted chats
    chatList.removeWhere((chat) {
      return !(toAdd.any((toChat) =>
          (chat.id == toChat.id && chat.serverid == toChat.serverid)));
    });
  }

  Timer myTimer(int seconds) {
    //fetch list first

    return new Timer.periodic(
        new Duration(seconds: seconds), (Timer timer) => _loadChatList());
  }
/*
  void _closeChat(Server srv, Chat chat) async {
   // await _serverRepository.closeChat(srv, chat).then((loaded) {
      //TODO Update List
   // });
  } */

/*
  void deleteChat(Server srv, Chat chat) async {
    await _serverRequest.deleteChat(srv, chat).then((loaded) {
      //  widget.chatRemoved()
      //TODO Update List;
    });
  }  */

  void onActionLoading(bool val) {
    /*  if (mounted) {
      setState(() {
        _actionLoading = val;
      });
    }
    */
  }

  bool _isServerLoggedIn() {
    return _selectedServer?.loggedIn ?? false ? true : false;
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

  Future<bool> _checkTwilio(Server server) async {
    return await _serverRequest.isExtensionInstalled(server, "twilio");
  }

  void _showAlert(BuildContext context, Server server) {
    AlertDialog dialog = new AlertDialog(
      content: new Text(
        "Do you want to logout of the server? \n\nYou will not receive notifications for chats.",
        style: new TextStyle(fontSize: 14.0),
      ),
      actions: <Widget>[
        new MaterialButton(
            child: new Text("Yes"),
            onPressed: () async {
              context.bloc<LoginformBloc>().add(ServerLogout(
                  server: server,
                  fcmToken: context.bloc<FcmTokenBloc>().token));
              Navigator.of(context).pop();
            }),
        MaterialButton(
            child: new Text("No"),
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void _showSnackBar(String text) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _deleteServer() async {
    return dbHelper.deleteItem(Server.tableName, "id=?", [_selectedServer.id]);
  }

  Future<Null> _getTwilioStatus() async {
    _serverRequest
        .isExtensionInstalled(_selectedServer, "twilio")
        .then((isInstalled) {
      setState(() {
        _selectedServer.twilioInstalled = isInstalled;
      });
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      initialized = true;
    });

    // if (_selectedServer != null) showUpdateMsg();
  }

  void _addServer({Server server}) {
    Navigator.of(context).push(FadeRoute(
      builder: (BuildContext context) => TokenInheritedWidget(
          token: _fcmToken,
          child: LoginForm(
            isNew: true,
            server: server,
          )),
      settings: new RouteSettings(
        name: AppRoutes.login,
      ),
    ));
  }

  void _showAlertMsg(String title, String msg) {
    SimpleDialog dialog = new SimpleDialog(
      title: new Text(
        title,
        style: new TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        new Text(
          msg,
          style: new TextStyle(fontSize: 14.0),
        )
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  SpeedDial _speedDial(BuildContext context) {
    var children = [
      SpeedDialChild(
          child: Icon(Icons.refresh),
          backgroundColor: Theme.of(context).primaryColor,
          label: 'Reload list',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => _loadChatList())
    ];

    if (_selectedServer != null && _selectedServer.twilioInstalled == true) {
      children.add(SpeedDialChild(
        child: Icon(Icons.sms),
        backgroundColor: Theme.of(context).primaryColor,
        label: 'Twilio SMS/Chat',
        labelStyle: TextStyle(fontSize: 18.0),
        onTap: () async {
          onActionLoading(true);
          Navigator.of(context).push(FadeRoute(
            builder: (BuildContext context) => TwilioSMSChat(
              server: _selectedServer,
              refreshList: () {},
            ),
            settings: new RouteSettings(
              name: AppRoutes.twilio,
            ),
          ));
        },
      ));
    }

    return SpeedDial(
        // both default to 16
        marginRight: 18,
        marginBottom: 20,
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: IconThemeData(size: 22.0),
        // this is ignored if animatedIcon is non null
        // child: Icon(Icons.add),
        visible: true,
        // If true user is forced to close dial manually
        // by tapping main button and overlay is not rendered.
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () {},
        onClose: () {},
        tooltip: 'Actions',
        heroTag: 'speed-dial-hero-tag',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 8.0,
        shape: CircleBorder(),
        children: children);
  }
}
