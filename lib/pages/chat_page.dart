import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:async_loader/async_loader.dart';
import 'package:rxdart/rxdart.dart';

import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/widget/chat_bubble.dart';

import 'package:livehelp/utils/enum_menu_options.dart';
import 'package:livehelp/utils/server_requests.dart';

/// place: "/chats/chat"
class ChatPage extends StatefulWidget {
  ChatPage({Key key, this.server, this.chat,this.refreshList, @required this.isNewChat})
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
  final subject = new PublishSubject<String>();

  // used to track application lifecycle
  AppLifecycleState _lastLifecyleState;

  final GlobalKey<AsyncLoaderState> _mainAsyncLoaderState =
  new GlobalKey<AsyncLoaderState>();
  GlobalKey<ScaffoldState> _scaffoldState = new GlobalKey<ScaffoldState>();

  bool _isWriting = false;
  bool _syncAll = true; // for synching all chats or update
  bool _isNewChat; // is pending chat or not
  bool _isOwnerOfChat = false;
  bool _actionLoading = false;

  Chat _chatCopy;
  String _chatOwner;
  String _operator;
  String _chatStatus = "";

  List<dynamic> _cannedMsgs = new List();

  List<MsgHandler> _msgsHandlerList = <MsgHandler>[];
  TextEditingController _textController = new TextEditingController();
  ServerRequest _serverRequest;
  
   List<PopupMenuEntry<ChatItemMenuOption>> menuBuilder;

  Timer _msgsTimer;
  Timer _acceptTimer;

  BuildContext _context;

  @override
  initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _chatCopy = widget.chat; // copy chat so that we can update it later
    _isNewChat = widget.isNewChat;
    _serverRequest = new ServerRequest();
    _msgsTimer = new Timer.periodic(
        new Duration(seconds: 5), (Timer timer) => _syncMessages());

    subject.stream
        .debounce(new Duration(milliseconds: 500))
        .listen(_textChanged);

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

    subject.close();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkState() {
    switch (_lastLifecyleState) {
      case AppLifecycleState.resumed:
        _msgsTimer = new Timer.periodic(
            new Duration(seconds: 5), (Timer timer) => _syncMessages());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_msgsTimer.isActive) _msgsTimer.cancel();
      _cancelAccept();
        break;
      default:
        break;
    }
  }

  void _cancelAccept(){
    if (_acceptTimer != null && _acceptTimer.isActive) _acceptTimer.cancel();
  }


  @override
  Widget build(BuildContext context) {

    _context = context;

    TextStyle headerbottom = new TextStyle(
        fontSize: 12.0,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        );

    var _asyncLoader = new AsyncLoader(
      key: _mainAsyncLoaderState,
      initState: () async {
        await _syncMessages();
      },
      renderLoad: () => new Center(child: new CircularProgressIndicator()),
      renderError: ([error]) =>
       new Center(child: new Text('Could not load chat messages')),
      renderSuccess: ({data}) {
        return  new ListView.builder(
          reverse: true,
          padding: new EdgeInsets.all(6.0),
          itemBuilder: (_, int index) => _msgsHandlerList[index],
          itemCount: _msgsHandlerList.length,
        );
      },
    );
    
        var popupMenuBtn = PopupMenuButton<ChatItemMenuOption>(
              onSelected: (ChatItemMenuOption result) {
                onMenuOptionChanged(result);
              }, itemBuilder: (BuildContext context) {
            return _itemMenuBuilder();
          });



    Widget loadingIndicator =
    _actionLoading ? new CircularProgressIndicator() : new Container();


    var mainScaffold = new Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: new AppBar(
          title: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
           // mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Text(
                '${_chatCopy.nick}',
                style:
                new TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              new Text(
                '$_chatStatus',
                style: new TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w300),
              )
            ],
          ),
          elevation:
          Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
            new Offstage(
                offstage: !_isNewChat,
                child: new MaterialButton(
                  child: _actionLoading ?  CircularProgressIndicator(valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),) : new Text("ACCEPT"),
                  textColor: Colors.white,
                  onPressed: () {
                      setState(() {
                     _actionLoading = true;
                       });
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
                icon:  Icon(Icons.info_outline),
                onPressed: ()=>this._showChatInfo(context)),
                popupMenuBtn
                
          ],
        bottom: new PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: new Container(
              height: 48.0,
              padding:
              const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
              alignment: Alignment.centerLeft,
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(
                    'Owner: ${_chatOwner ??""}',
                    style: headerbottom,
                  ),
                  new Text(
                    'Server: ${widget.server.servername ??""}',
                    style: headerbottom,
                  ),
                ],
              ),
            )),
      ),

      body: Stack(children: <Widget>[
         Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
               Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child:_asyncLoader,
                  )),
              new Divider(
                height: 1.0,
              ),
              new Container(
                child: _buildComposer(),
                decoration: new BoxDecoration(color: Theme.of(context).cardColor),
              )
            ]),
          Center(child: loadingIndicator)
      ])

    );

    return mainScaffold;
  }

    // Generate Chat Menu options
    List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder(){

     List<PopupMenuEntry<ChatItemMenuOption>> menuItems =[];

    if(_chatCopy.status == 1){
/*
      menuItems.add(const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.TRANSFER,
        child: const Text('Transfer'),
      ));
*/
      menuItems.add( const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.CLOSE,
      child: const Text('Close'),
      ));

    }

    menuItems.add(
        const PopupMenuItem<ChatItemMenuOption>(
          value: ChatItemMenuOption.REJECT,
          child: const Text('Delete'),
        ));


return menuItems;
}

 void onMenuOptionChanged(ChatItemMenuOption result){
    switch(result){
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
 //       _showOperatorList(context,srv,chat);
        //_getOperatorList(ctx,srv,chat);
        break;
        */
    default:
      break;
    }
  }

   void _closeChat() async{

    _isLoading(true);
   var closed = await  _serverRequest.closeChat(widget.server,_chatCopy);

   //   widget.loadingState(false);
       if(closed){
         _isLoading(false);
         widget.refreshList();
         Navigator.pop(_context);
       }

  }

  
  void _deleteChat()async{
    _isLoading(true);
     var deleted = await _serverRequest.deleteChat(widget.server,_chatCopy);

       if(deleted){
         _isLoading(false);
         widget.refreshList();
         Navigator.pop(_context);
       }
  }


  void _showChatInfo(context){
    TextStyle styling = new TextStyle(fontFamily: 'Roboto', fontSize: 10.0);
      showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return new SingleChildScrollView(
                child: new Column(
                  children: <Widget>[
                    new ListTile(
                      leading: new Text("ID", style: styling),
                      title: new Text(_chatCopy.id.toString() ?? ""),
                      onTap: () {},
                    ),
                    new ListTile(
                      leading: new Text("Email", style: styling),
                      title: new Text(_chatCopy.email ?? ""),
                      onTap: () {},
                    ),
                    new ListTile(
                      leading: new Text("IP", style: styling),
                      title: new Text(_chatCopy.ip ?? ""),
                      onTap: () {},
                    ),
                    new ListTile(
                      leading: new Text("Country", style: styling),
                      title: new Text(_chatCopy.country_name ?? ""),
                      onTap: () {},
                    ),
                    new ListTile(
                      leading: new Text("From", style: styling),
                      title: new Text(_chatCopy.referrer ?? ""),
                      onTap: () {},
                    ),
                    new ListTile(
                      leading: new Text("User Agent", style: styling),
                      title: new Text(_chatCopy.uagent ?? ""),
                      onTap: () {},
                    ),
                  ],
                ));
          });

  }


  Widget _buildComposer() {
    var cupertinoButton = CupertinoButton(
        child:  Text("Send"),
        onPressed: _isWriting ? () => _submitMsg(_textController.text) : null);

    var iconButton = IconButton(
      icon: new Icon(Icons.message),
      onPressed: _isWriting ? () => _submitMsg(_textController.text) : null,
    );

    return  IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 9.0),
          child: new Row(
            children: <Widget>[
               IconButton(
                  icon: new Icon(Icons.list),
                  onPressed: () {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                              child:  Padding(
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
                                          setState(() => _textController.text =
                                              canMsg["msg"]);
                                          Navigator.pop(context);
                                          _isWriting = true;
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
                onChanged: (txt) => (subject.add(txt)),
                onSubmitted: _submitMsg,
                decoration: _isOwnerOfChat
                    ? new InputDecoration(hintText: "Enter a message to send")
                    : new InputDecoration(
                        hintText: "You are not the owner of this chat"),
              )),
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 3.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? cupertinoButton
                    : iconButton,
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

      _serverRequest.chatData(widget.server, _chatCopy)
          .then((chatData) {
        if (chatData != null) {
          setState(() {
            _chatCopy = new Chat.fromMap(chatData["chat"]);

            _chatOwner = chatData["ownerstring"];
            _operator = chatData["operator"];
            _cannedMsgs = Map
                .castFrom(chatData["canned_messages"])
                .values
                .toList();

            _isNewChat = false;
            _isOwnerOfChat = _operator == _chatOwner;
            // delete timer since chat is successfully accepted
            _cancelAccept();
          });


        }
        _isLoading(false);
      });
  }

  void _isLoading(bool loading){
    setState(() {
      _actionLoading = loading;
    });
  }

  void _submitMsg(String msg) {
    _textController.clear();
    setState(() {
      _isWriting = false;
    });

    //post message to server here
    _serverRequest.postMesssage(widget.server, widget.chat, msg);

    _operatorTyping();
    // _syncMessages();
  }

  void _textChanged(String text) {
    setState(() {
      _isWriting = text.length > 0;
    });
    _operatorTyping();
  }

  void _operatorTyping() async {
    await _serverRequest.setOperatorTyping(
        widget.server, _chatCopy.id, _isWriting);
  }

  Future<Null> _syncMessages() async {
    int lastMsgId =
        _msgsHandlerList.length > 0 ? _msgsHandlerList.first.msg.id : 0;

     _serverRequest
        .syncMessages(widget.server, _chatCopy, lastMsgId)
        .then((msgsStatusMap) {
      if (msgsStatusMap['messages'] != null) {
        List<Message> msgList = msgsStatusMap['messages'];
        msgList.forEach((message) {
          // print("ListMessage: " + message.toMap().toString());
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

      if(mounted){
        setState(() {
          _chatStatus = msgsStatusMap['chat_status'] ?? "";
        });
      }

      /* check if chat has been accepted
    * not a very good way to check but
    * can't find a better way

      if (_msgsHandlerList.any((handler) => handler.msg.user_id > 0))
        _isNewChat = false;
      */

    });
  }
}

class MsgHandler extends StatelessWidget {
  MsgHandler({this.chat, this.msg, this.animationController});
  final Message msg;
  final Chat chat;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    return new SizeTransition(
        sizeFactor: new CurvedAnimation(
            parent: animationController, curve: Curves.bounceOut),
        axisAlignment: 0.0,
        child: new Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Expanded(
                    child: new Bubble(
                      message: msg,
                    ),
                  )
                ])));
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
