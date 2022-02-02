import 'dart:async';
import 'package:after_layout/after_layout.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/bloc/bloc.dart';

import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/services/server_repository.dart';

import 'package:rxdart/rxdart.dart';

import 'package:livehelp/model/model.dart';
import 'package:livehelp/widget/widget.dart';

import 'package:livehelp/utils/utils.dart';

import 'package:livehelp/globals.dart' as globals;

/// place: "/chats/chat"
class ChatPage extends StatefulWidget {
  ChatPage(
      {Key key,
      this.server,
      this.chat,
      this.refreshList,
      @required this.isNewChat})
      : super(key: key);

  final Chat chat; // not final because we will update it
  final Server server;
  final bool isNewChat; // used to determine pending or other chats

  final VoidCallback refreshList;

  @override
  ChatPageState createState() => new ChatPageState();
}

class ChatPageState extends State<ChatPage>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin<ChatPage>,
        RouteAware {
  final _writingSubject = new PublishSubject<String>();

  // used to track application lifecycle
  AppLifecycleState _lastLifecyleState;

  GlobalKey<ScaffoldState> _scaffoldState = new GlobalKey<ScaffoldState>();

  bool _isNewChat; // is pending chat or not
  bool _isOwnerOfChat = false;

  Chat _chatCopy;

  ChatMessagesBloc _chatPageBloc;
  ServerRepository _serverRepository;
  FcmTokenBloc _fcmTokenBloc;

  List<dynamic> _cannedMsgs = new List();

  List<MsgHandler> _msgsHandlerList = <MsgHandler>[];
  TextEditingController _textController = TextEditingController();
  ServerApiClient _serverApiClient;

  List<PopupMenuEntry<ChatItemMenuOption>> menuBuilder;

  Timer _msgsTimer;
  Timer _acceptTimer;
  Timer _operatorTimer;

  BehaviorSubject<bool> _isWritingSubject = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool> _isActionLoadingSubject =
      BehaviorSubject<bool>.seeded(false);

  set _isWriting(bool value) => _isWritingSubject.add(value);
  bool get _isWriting => _isWritingSubject.value;

  set _isActionLoading(bool value) => _isActionLoadingSubject.add(value);
  bool get _isActionLoading => _isActionLoadingSubject.value;

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _chatCopy = widget.chat; // copy chat so that we can update it later
    _isNewChat = widget.isNewChat;
    _serverApiClient = ServerApiClient(httpClient: http.Client());

    //subject.stream.debounce(new Duration(milliseconds: 300)).listen(_textChanged);
    _writingSubject.stream.listen(_textChanged);

    _serverRepository = context.repository<ServerRepository>();

    // stop sending notifications for this chat
    _fcmTokenBloc = context.bloc<FcmTokenBloc>()
      ..add(ChatOpenedEvent(chat: _chatCopy));

    // Chat page creates and manages it's own bloc.
    _chatPageBloc = ChatMessagesBloc(serverRepository: _serverRepository);

    _syncMessages();
    _msgsTimer = _syncMsgsTimer(5);
    if (!_isNewChat) {
      _acceptChat();
    }
  }

  @override
  void dispose() {
    for (MsgHandler msg in _msgsHandlerList) {
      msg.animationController.dispose();
    }
    _msgsTimer.cancel();

    if (_operatorTimer != null && _operatorTimer.isActive) {
      _operatorTimer.cancel();
    }

    _writingSubject.close();
    _isWritingSubject.close();
    _isActionLoadingSubject.close();
    _fcmTokenBloc.add(ChatClosedEvent(chat: _chatCopy));
    WidgetsBinding.instance.removeObserver(this);
    globals.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    globals.routeObserver.subscribe(this, ModalRoute.of(context));
  }

// Called when the current route has been pushed.
  @override
  void didPush() {
    // stop sending notifications for this chat
    _fcmTokenBloc.add(ChatOpenedEvent(chat: _chatCopy));
  }

  // Called when the current route has been pushed.
  @override
  void didPop() {
    _fcmTokenBloc.add(ChatClosedEvent(chat: _chatCopy));
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
        // stop sending notifications for this chat
        _fcmTokenBloc.add(ChatOpenedEvent(chat: _chatCopy));
        _syncMessages();
        _msgsTimer = _syncMsgsTimer(5);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        //allow showing notifications for this chat
        _fcmTokenBloc.add(ChatPausedEvent(chat: _chatCopy));
        if (_msgsTimer.isActive) _msgsTimer.cancel();
        if (_operatorTimer != null && _operatorTimer.isActive)
          _operatorTimer.cancel();
        _cancelAccept();
        break;
      default:
        break;
    }
  }

  Timer _syncMsgsTimer(int seconds) {
    return Timer.periodic(
        Duration(seconds: seconds), (Timer timer) => _syncMessages());
  }

  void _cancelAccept() {
    if (_acceptTimer != null && _acceptTimer.isActive) _acceptTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle headerbottom = new TextStyle(
      fontSize: 12.0,
      height: 1,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    );

    var msgsStreamBuilder = BlocBuilder<ChatMessagesBloc, ChatMessagesState>(
        builder: (context, state) {
      if (state is ChatMessagesInitial) {
        return Center(
          child: CircularProgressIndicator(),
        );
      }

      if (state is ChatMessagesLoadError) {
        return Center(child: Text('Error: ${state.message}'));
      }
      if (state is ChatMessagesLoaded) {
        _addMessages(state.messages);

        return ListView.builder(
          scrollDirection: Axis.vertical,
          reverse: true,
          padding: new EdgeInsets.all(6.0),
          itemBuilder: (BuildContext context, int index) {
            return _msgsHandlerList[index];
          },
          itemCount: _msgsHandlerList.length,
        );
      }
      return Text("No messages");
    });

    var popupMenuBtn = PopupMenuButton<ChatItemMenuOption>(
        onSelected: (ChatItemMenuOption result) {
      onMenuOptionChanged(result);
    }, itemBuilder: (BuildContext context) {
      return _itemMenuBuilder();
    });

    Widget loadingIndicator =
        _isActionLoading ? CircularProgressIndicator() : Container();

    var mainScaffold = BlocProvider<ChatMessagesBloc>(
        create: (context) => _chatPageBloc,
        child: Scaffold(
            backgroundColor: Colors.blueGrey.shade50,
            appBar: AppBar(
              key: _scaffoldState,
              title: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                // mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                            style: TextStyle(height: 1, fontSize: 17),
                            child: BlocBuilder<ChatMessagesBloc,
                                ChatMessagesState>(builder: (context, state) {
                              if (state is ChatMessagesLoaded) {
                                return Icon(Icons.person,
                                    size: 14,
                                    color: state.chatStatusCode == 0
                                        ? Colors.green.shade400
                                        : (state.chatStatusCode == 2
                                            ? Colors.yellow.shade400
                                            : Colors.red.shade400));
                              }
                              return Icon(Icons.person,
                                  size: 14, color: Colors.green.shade400);
                            })),
                        TextSpan(
                          style: TextStyle(height: 2, fontSize: 15),
                          text: ' ${_chatCopy.nick}',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.people,
                        size: 17,
                        color: Colors.white,
                      ),
                      Text(
                        ' ${_chatCopy.owner ?? " - "}',
                        style: headerbottom,
                      ),
                    ],
                  ),
                ],
              ),
              elevation: Theme.of(context).platform == TargetPlatform.android
                  ? 6.0
                  : 0.0,
              actions: <Widget>[
                new Offstage(
                    offstage: !_isNewChat,
                    child: new MaterialButton(
                      child: _isActionLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : new Text("ACCEPT"),
                      textColor: Colors.white,
                      onPressed: () {
                        _isActionLoading = true;
                        _acceptChat();
                      },
                    )),
                new IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () => this._showChatInfo(context)),
                popupMenuBtn
              ],
              bottom: new PreferredSize(
                  preferredSize: const Size.fromHeight(25.0),
                  child: new Container(
                      height: 28.0,
                      padding: const EdgeInsets.only(
                          top: 0.0, left: 73.0, right: 8.0),
                      alignment: Alignment.centerLeft,
                      child: BlocBuilder<ChatMessagesBloc, ChatMessagesState>(
                        builder: (context, state) {
                          if (state is ChatMessagesLoaded) {
                            return Text(
                              '${state.chatStatus}' ?? "",
                              softWrap: true,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w300),
                            );
                          }
                          return Text("");
                        },
                      ))),
            ),
            body: BlocConsumer<ChatMessagesBloc, ChatMessagesState>(
              listener: (context, state) {
                if (state is ChatMessagesLoaded) {
                  if (state.isChatClosed) {
                    widget.refreshList();
                    Navigator.of(context).pop();
                  }
                }
              },
              builder: (context, state) {
                return Stack(children: <Widget>[
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: msgsStreamBuilder,
                        )),
                        new Divider(
                          height: 1.0,
                        ),
                        new Container(
                          child: _buildComposer(),
                          decoration: new BoxDecoration(
                              color: Theme.of(context).cardColor),
                        )
                      ]),
                  if (state is ChatMessagesLoaded && state.isLoading)
                    Center(child: loadingIndicator)
                ]);
              },
            )));

    return new GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: mainScaffold);
  }

  void _addMessages(List<Message> messages) {
    messages.forEach((message) {
      if (!_msgsHandlerList
          .any((msghandle) => msghandle.msg.id == message.id)) {
        MsgHandler msgHandle = new MsgHandler(
          chat: _chatCopy,
          msg: message,
          animationController: new AnimationController(
              vsync: this, duration: new Duration(microseconds: 700)),
        );

        _msgsHandlerList.insert(0, msgHandle);
        msgHandle.animationController.forward();
      }
    });
  }

  // Generate Chat Menu options
  List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder() {
    List<PopupMenuEntry<ChatItemMenuOption>> menuItems = [];

    if (_chatCopy.status == 1) {
/*
      menuItems.add(const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.TRANSFER,
        child: const Text('Transfer'),
      ));
*/
      menuItems.add(const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.CLOSE,
        child: const Text('Close'),
      ));
    }

    menuItems.add(const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.REJECT,
      child: const Text('Delete'),
    ));
    return menuItems;
  }

  void onMenuOptionChanged(ChatItemMenuOption result) {
    switch (result) {
      case ChatItemMenuOption.CLOSE:
        //     widget.loadingState(true);
        _closeChat();
        break;
      case ChatItemMenuOption.REJECT:
        //   widget.loadingState(true);
        _deleteChat();
        break;
      /*   case ChatItemMenuOption.TRANSFER:
      // widget.loadingState(true);
      // _showOperatorList(context,srv,chat);
        //_getOperatorList(ctx,srv,chat);
        break;
        */
      default:
        break;
    }
  }

  void _closeChat() async {
    _chatPageBloc.add(CloseChat(server: widget.server, chat: _chatCopy));
  }

  void _deleteChat() async {
    _chatPageBloc.add(DeleteChat(server: widget.server, chat: _chatCopy));
  }

  void _showChatInfo(context) {
    TextStyle styling = new TextStyle(
        fontFamily: 'Roboto', fontSize: 16.0, fontWeight: FontWeight.bold);
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new SingleChildScrollView(
              child: new Column(
            children: <Widget>[
              ListTile(
                leading: new Text("Server", style: styling),
                title: new Text("${widget.server.servername}"),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("ID", style: styling),
                title: new Text(_chatCopy.id.toString() ?? ""),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("Email", style: styling),
                title: new Text(_chatCopy.email ?? ""),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("Phone", style: styling),
                title: new Text(_chatCopy.phone ?? ""),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("IP", style: styling),
                title: new Text(_chatCopy.ip ?? ""),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("Country", style: styling),
                title: new Text(_chatCopy.country_name ?? ""),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("From", style: styling),
                title: new Text(_chatCopy.referrer ?? ""),
                onTap: () {},
              ),
              ListTile(
                leading: new Text("User Agent", style: styling),
                title: new Text(_chatCopy.uagent ?? ""),
                onTap: () {},
              ),
            ],
          ));
        });
  }

  Widget _buildComposer() {
    /*var cupertinoButton = CupertinoButton(
        child: Text("Send"),
        onPressed: _isWriting ? () => _submitMsg(_textController.text) : null);*/

    var iconButton = IconButton(
        icon: new Icon(Icons.send),
        onPressed: () {
          if (_textController.text.length > 0) _submitMsg(_textController.text);
        });

    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0),
          child: new Row(
            children: <Widget>[
              IconButton(
                  icon: new Icon(Icons.list),
                  onPressed: () {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                              child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ListView.builder(
                                    reverse: false,
                                    padding: EdgeInsets.all(6.0),
                                    itemCount: _cannedMsgs.length,
                                    itemBuilder: (_, int index) {
                                      Map canMsg = _cannedMsgs[index];
                                      return Container(
                                          child: new ListTile(
                                        title: new Text(canMsg["title"]),
                                        isThreeLine: true,
                                        subtitle: new Text(canMsg["msg"]),
                                        onTap: () {
                                          _textController.text = canMsg["msg"];
                                          Navigator.pop(context);
                                        },
                                      ));
                                    },
                                  )));
                        });
                  }),
              Flexible(
                  child: new TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                enableInteractiveSelection: true,
                onChanged: (txt) => (_writingSubject.add(txt)),
                onSubmitted: _submitMsg,
                decoration: _isOwnerOfChat
                    ? new InputDecoration(
                        hintText: "Enter a message to send",
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none)
                    : new InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: "You are not the owner of this chat"),
              )),
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 0.0),
                child:
                    iconButton /*Theme.of(context).platform == TargetPlatform.iOS
                    ? cupertinoButton
                    : iconButton*/
                ,
              )
            ],
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border: new Border(top: new BorderSide(color: Colors.brown)))
              : null),
    );
  }

  void _acceptChat() async {
    _serverApiClient.chatData(widget.server, _chatCopy).then((chatData) {
      if (chatData != null) {
        setState(() {
          var newChat = new Chat.fromJson(chatData["chat"]);
          // update chat with new data
          _chatCopy = newChat.copyWith(owner: chatData["ownerstring"]);

          _cannedMsgs =
              Map.castFrom(chatData["canned_messages"]).values.toList();

          _isNewChat = false;
          _isOwnerOfChat =
              _chatCopy.user_id.toString() == widget.server.userid.toString();

          _cancelAccept();
        });
      }
      _isLoading(false);
    });
  }

  void _isLoading(bool loading) {
    _isActionLoading = loading;
  }

  void _submitMsg(String msg) {
    _textController.clear();
    _isWriting = false;
    //post message to server and update messages instantly
    _chatPageBloc.add(
        PostMessage(server: widget.server, chat: widget.chat, message: msg));
  }

  void _textChanged(String text) {
    if (_isWriting == false && text.length > 0) {
      _isWriting = true;

      _operatorTyping();
    } else if (_isWriting == true && text.length == 0) {
      _isWriting = false;
    }

    // Cancel present
    if (_operatorTimer != null && _operatorTimer.isActive)
      _operatorTimer.cancel();

    _operatorTimer = Timer(Duration(seconds: 3), () {
      _isWriting = false;
      _operatorTyping();
    });
  }

  void _operatorTyping() async {
    await _serverApiClient.setOperatorTyping(
        widget.server, _chatCopy.id, _isWriting);
  }

  Future<Null> _syncMessages() async {
    _chatPageBloc
        ?.add(FetchChatMessages(server: widget.server, chat: _chatCopy));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _syncMessages();
  }
}

class MsgHandler extends StatelessWidget {
  MsgHandler({this.chat, this.msg, this.animationController});
  final Message msg;
  final Chat chat;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: new Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Expanded(
                child: new Bubble(
                  message: msg,
                ),
              )
            ]));

    /*new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animationController, curve: Curves.bounceOut),
        axisAlignment: 0.0,
        child:
                ); */
  }
}

class ChatDetailTile extends StatelessWidget {
  const ChatDetailTile({this.leading, this.info});

  final String leading;
  final String info;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
            margin: const EdgeInsetsDirectional.only(end: 16.0),
            width: 40.0,
            child: new Text(leading)),
        Expanded(
            child: new Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              new Text(info,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).accentTextTheme.subtitle2),
            ]))
      ],
    );
  }
}
