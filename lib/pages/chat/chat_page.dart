import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:livehelp/bloc/chat_page_bloc.dart';
import 'package:livehelp/services/chat_messages_service.dart';

import 'package:rxdart/rxdart.dart';

import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/widget/chat_bubble.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _writingSubject = new PublishSubject<String>();

  // used to track application lifecycle
  AppLifecycleState _lastLifecyleState;

  GlobalKey<ScaffoldState> _scaffoldState = new GlobalKey<ScaffoldState>();

  ChatPageBloc _chatPageBloc;

  bool _isNewChat; // is pending chat or not
  bool _isOwnerOfChat = false;

  Chat _chatCopy;
  String _chatOwner;
  String _operator;
  String _chatStatus = "";
  int _chat_scode = 0;

  List<dynamic> _cannedMsgs = new List();

  List<MsgHandler> _msgsHandlerList = <MsgHandler>[];
  TextEditingController _textController = TextEditingController();
  ChatMessagesService _chatMessagesService;

  List<PopupMenuEntry<ChatItemMenuOption>> menuBuilder;

  Timer _msgsTimer;
  Timer _acceptTimer;
  Timer _operatorTimer;

  BehaviorSubject<bool> _isWritingSubject = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool> _isActionLoadingSubject =
      BehaviorSubject<bool>.seeded(false);

  BuildContext _context;

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
    _chatMessagesService = new ChatMessagesService();
    _msgsTimer = new Timer.periodic(
        new Duration(seconds: 5), (Timer timer) {}); //_syncMessages()

    //subject.stream.debounce(new Duration(milliseconds: 300)).listen(_textChanged);
    _writingSubject.stream.listen(_textChanged);

    _chatPageBloc =
        ChatPageBloc(_chatMessagesService, widget.server, widget.chat);
    if (!_isNewChat) _acceptChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lastLifecyleState = state;
    });

    _checkState();
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
    _chatPageBloc.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkState() {
    switch (_lastLifecyleState) {
      case AppLifecycleState.resumed:
        _chatPageBloc.resume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_msgsTimer.isActive) _msgsTimer.cancel();
        if (_operatorTimer != null && _operatorTimer.isActive)
          _operatorTimer.cancel();
        _cancelAccept();
        _chatPageBloc.pause();
        break;
      default:
        break;
    }
  }

  void _cancelAccept() {
    if (_acceptTimer != null && _acceptTimer.isActive) _acceptTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

    _chatPageBloc.inSyncMsgs.add(0);

    TextStyle headerbottom = new TextStyle(
      fontSize: 12.0,
      height: 1,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    );

    var msgsStreamBuilder = StreamBuilder(
        stream: _chatPageBloc.chatMessages$,
        builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );

          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              break;
            case ConnectionState.active:
            case ConnectionState.done:
              _addMessages(snapshot.data);
          }

          return ListView.builder(
            scrollDirection: Axis.vertical,
            reverse: true,
            padding: new EdgeInsets.all(6.0),
            itemBuilder: (BuildContext context, int index) {
              return _msgsHandlerList[index];
            },
            itemCount: _msgsHandlerList.length,
          );
        });

    var popupMenuBtn = PopupMenuButton<ChatItemMenuOption>(
        onSelected: (ChatItemMenuOption result) {
      onMenuOptionChanged(result);
    }, itemBuilder: (BuildContext context) {
      return _itemMenuBuilder();
    });

    Widget loadingIndicator =
        _isActionLoading ? CircularProgressIndicator() : Container();

    var mainScaffold = Scaffold(
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
                      child: Icon(Icons.person,
                          size: 14,
                          color: _chat_scode == 0
                              ? Colors.green.shade400
                              : (_chat_scode == 2
                                  ? Colors.yellow.shade400
                                  : Colors.red.shade400)),
                    ),
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
                    ' ${_chatOwner ?? " - "}',
                    style: headerbottom,
                  ),
                ],
              ),
            ],
          ),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
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
                    // Use timer to accept the chat. To handle problematic network connection
                    /*       _acceptTimer = new Timer.periodic(
                  new Duration(seconds: 10), (Timer timer){
                    if (!_isOwnerOfChat)_acceptChat();
                    else _cancelAccept();
                  });
                    */
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
                  padding:
                      const EdgeInsets.only(top: 0.0, left: 73.0, right: 8.0),
                  alignment: Alignment.centerLeft,
                  child: StreamBuilder(
                    stream: _chatPageBloc.chatStatus$,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      return Text(
                        '${snapshot?.data}' ?? "",
                        softWrap: true,
                        style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w300),
                      );
                    },
                  ))),
        ),
        body: Stack(children: <Widget>[
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
                  decoration:
                      new BoxDecoration(color: Theme.of(context).cardColor),
                )
              ]),
          Center(child: loadingIndicator)
        ]));

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
    _isLoading(true);
    var closed = await _chatMessagesService.closeChat(widget.server, _chatCopy);
    _isLoading(false);
    if (closed) {
      widget.refreshList();
      Navigator.of(_context).pop();
    }
  }

  void _deleteChat() async {
    _isLoading(true);
    var deleted =
        await _chatMessagesService.deleteChat(widget.server, _chatCopy);
    _isLoading(false);
    if (deleted) {
      widget.refreshList();
      Navigator.pop(_context);
    }
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
    _chatMessagesService.chatData(widget.server, _chatCopy).then((chatData) {
      if (chatData != null) {
        setState(() {
          _chatCopy = new Chat.fromMap(chatData["chat"]);

          _chatOwner = chatData["ownerstring"];
          _operator = chatData["operator"];
          _cannedMsgs =
              Map.castFrom(chatData["canned_messages"]).values.toList();

          _isNewChat = false;
          _isOwnerOfChat = chatData['chat']['user_id'].toString() ==
              widget.server.userid.toString();

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
    _chatMessagesService
        .postMesssage(widget.server, widget.chat, msg)
        .then((value) {
      _chatPageBloc.syncMessages();
    });
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
    await _chatMessagesService.setOperatorTyping(
        widget.server, _chatCopy.id, _isWriting);
  }

/*
  Future<Null> _syncMessages() async {
    int lastMsgId =
        _msgsHandlerList.length > 0 ? _msgsHandlerList.first.msg.id : 0;

    _chatMessagesService
        .syncMessages(widget.server, _chatCopy, lastMsgId)
        .then((msgsStatusMap) {
      if (msgsStatusMap['messages'] != null) {
        List<Message> msgList = msgsStatusMap['messages'];
        msgList.forEach((message) {
          if (!_msgsHandlerList
              .any((msghandle) => msghandle.msg.id == message.id)) {
            MsgHandler msgHandle = new MsgHandler(
              chat: _chatCopy,
              msg: message,
              animationController: new AnimationController(
                  vsync: this, duration: new Duration(microseconds: 700)),
            );
            if (mounted) {
              setState(() {
                _msgsHandlerList.insert(0, msgHandle);
              });
              msgHandle.animationController.forward();
            }
          }
        });
      }

      if (mounted) {
        setState(() {
          _chatStatus = msgsStatusMap['chat_status'] ?? "";
          _chat_scode = msgsStatusMap['chat_scode'] ?? 0;
        });
      }
    });
  }  */
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
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        new Container(
            margin: const EdgeInsetsDirectional.only(end: 16.0),
            width: 40.0,
            child: new Text(leading)),
        new Expanded(
            child: new Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              new Text(info,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).accentTextTheme.subhead),
            ]))
      ],
    );
  }
}
