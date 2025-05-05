// In lib/pages/chat/chat_page.dart

import 'dart:async';
import 'dart:developer';
import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/globals.dart' as globals;
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/widget/chat_bubble_experiment.dart';
import 'package:livehelp/widget/sendMessageRowWidget.dart';
import 'package:rxdart/rxdart.dart';

/// place: "/chats/chat"
class ChatPage extends StatefulWidget {
  ChatPage({
    Key? key,
    this.server,
    this.chat,
    this.refreshList,
    required this.isNewChat,
  }) : super(
    key: key,
  );

  Chat? chat; // not final because we will update it
  Server? server;
  bool? isNewChat; // used to determine pending or other chats
  VoidCallback? refreshList;
  Key key = ValueKey("audioRecordingWidget");

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin<ChatPage>,
        RouteAware {
  final _writingSubject = PublishSubject<String>();
  // used to track application lifecycle
  AppLifecycleState? _lastLifecyleState;

  final GlobalKey<ScaffoldState> _scaffoldState = new GlobalKey<ScaffoldState>();

  bool? _isNewChat; // is pending chat or not
  bool _isOwnerOfChat = false;

  Chat? _chatCopy;

  ChatMessagesBloc? _chatPageBloc;
  ServerRepository? _serverRepository;
  FcmTokenBloc? _fcmTokenBloc;

  List<dynamic> _cannedMsgs = <dynamic>[];

  List<MsgHandler> _msgsHandlerList = <MsgHandler>[];
  ServerApiClient? _serverApiClient;

  List<PopupMenuEntry<ChatItemMenuOption>>? menuBuilder;

  Timer? _msgsTimer;
  Timer? _acceptTimer;
  Timer? _operatorTimer;
  bool _showingChatInfo = false;

  BehaviorSubject<bool> _isWritingSubject = BehaviorSubject<bool>.seeded(false);
  BehaviorSubject<bool> _isActionLoadingSubject =
  BehaviorSubject<bool>.seeded(false);

  set _isWriting(bool value) => _isWritingSubject.add(value);
  bool get _isWriting => _isWritingSubject.value;
  set _isActionLoading(bool value) => _isActionLoadingSubject.add(value);
  bool get _isActionLoading => _isActionLoadingSubject.value;
  String? departmentName;
  bool isChatAccepted = false;

  bool isChatLoaded = false;
  bool isAcceptingChat = false;
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatCopy = widget.chat; // copy chat so that we can update it later
    _isNewChat = widget.isNewChat;
    _serverApiClient = ServerApiClient(httpClient: http.Client());
    //subject.stream.debounce(new Duration(milliseconds: 300)).listen(_textChanged);
    _writingSubject.stream.listen(_textChanged);
    // stop sending notifications for this chat
    _fcmTokenBloc = context.read<FcmTokenBloc>()
      ..add(ChatOpenedEvent(chat: _chatCopy!));
    _syncMessages();
    _fetchCannedResponses();
    _msgsTimer = _syncMsgsTimer(5);

    if(widget.chat?.user_id.toString()==widget.server!.userid.toString()){
      _isOwnerOfChat=true;
    }

    /*if(widget.chat?.owner==widget.server?.username){
      _isOwnerOfChat=true;
    }*/


    // if (!_isNewChat!) {
    //   _acceptChat();
    // }
  }

  @override
  void dispose() {
    for (MsgHandler msg in _msgsHandlerList) {
      msg.animationController!.dispose();
    }
    _msgsTimer!.cancel();

    if (_operatorTimer != null && _operatorTimer!.isActive) {
      _operatorTimer!.cancel();
    }

    _writingSubject.close();
    _isWritingSubject.close();
    _isActionLoadingSubject.close();
    _fcmTokenBloc!.add(ChatClosedEvent(chat: _chatCopy!));
    WidgetsBinding.instance.removeObserver(this);
    globals.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    globals.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

// Called when the current route has been pushed.
  @override
  void didPush() {
    // stop sending notifications for this chat
    _fcmTokenBloc!.add(ChatOpenedEvent(chat: _chatCopy!));
  }

  // Called when the current route has been pushed.
  @override
  void didPop() {
    _fcmTokenBloc!.add(ChatClosedEvent(chat: _chatCopy!));
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
        _fcmTokenBloc?.add(ChatOpenedEvent(chat: _chatCopy!));
        _syncMessages();
        _msgsTimer = _syncMsgsTimer(5);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      //allow showing notifications for this chat
        _fcmTokenBloc?.add(ChatPausedEvent(chat: _chatCopy!));
        if (_msgsTimer!.isActive) _msgsTimer!.cancel();
        if (_operatorTimer != null && _operatorTimer!.isActive) {
          _operatorTimer!.cancel();
        }
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
    if (_acceptTimer != null && _acceptTimer!.isActive) _acceptTimer!.cancel();
  }

  @override
  Widget build(BuildContext context) {
    _serverRepository = context.watch<ServerRepository>();

    // Chat page creates and manages it's own bloc.
    if (_chatPageBloc == null) {
      _chatPageBloc = ChatMessagesBloc(serverRepository: _serverRepository!);
    }

    TextStyle headerbottom = const TextStyle(
      fontSize: 12.0,
      height: 1,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    );

    var msgsStreamBuilder = BlocBuilder<ChatMessagesBloc, ChatMessagesState>(
        bloc: _chatPageBloc,
        builder: (context, state) {
          if (state is ChatMessagesInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ChatMessagesLoadError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is ChatMessagesLoaded) {
            // Only add messages if not showing info dialog to prevent reload
            if (!_showingChatInfo) {
              _addMessages(state.messages);
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque, // Important to capture all taps
              onTap: () {
                // Hide keyboard when tapping on the message list
                FocusScope.of(context).unfocus();
              },
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                reverse: true,
                padding: const EdgeInsets.all(6.0),
                itemBuilder: (BuildContext context, int index) {
                  return _msgsHandlerList[index];
                },
                itemCount: _msgsHandlerList.length,
              ),
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
    _isActionLoading ? const CircularProgressIndicator() : Container();

    var mainScaffold = BlocProvider<ChatMessagesBloc>(
      create: (context) => _chatPageBloc!,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade50,
        appBar: AppBar(
          key: _scaffoldState,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            // mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      WidgetSpan(
                        style: const TextStyle(height: 1, fontSize: 17),
                        child: BlocBuilder<ChatMessagesBloc, ChatMessagesState>(
                          bloc: _chatPageBloc,
                          builder: (context, state) {
                            if (state is ChatMessagesLoaded) {
                              isChatLoaded = true;
                              return Icon(
                                Icons.person,
                                size: 17,
                                color: state.chatStatusCode == 0
                                    ? Colors.green.shade400
                                    : (state.chatStatusCode == 2
                                    ? Colors.yellow.shade400
                                    : Colors.red.shade400),
                              );
                            }
                            return Icon(Icons.person,
                                size: 17, color: Colors.green.shade400);
                          },
                        ),
                      ),
                      TextSpan(
                        style: const TextStyle(
                          height: 2,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        text: ' ${_chatCopy!.nick}',
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.people,
                    size: 17,
                    color: Colors.white,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      _chatCopy!.owner != null
                          ? ' ${_chatCopy!.owner}'
                          : " Pending",
                      style: headerbottom,
                    ),
                  ),
                ],
              ),
            ],
          ),
          elevation:
          Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showChatInfo(context),
            ),
            popupMenuBtn
          ],
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(25.0),
              child: Container(
                  height: 28.0,
                  // padding: const EdgeInsets.only(
                  //     top: 0.0, left: 73.0, right: 8.0),
                  alignment: Alignment.centerLeft,
                  child: BlocBuilder<ChatMessagesBloc, ChatMessagesState>(
                    bloc: _chatPageBloc,
                    builder: (context, state) {
                      if (state is ChatMessagesLoaded) {
                        return Center(
                          child: Text(
                            state.chatStatus,
                            softWrap: true,
                            style: const TextStyle(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w300),
                          ),
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
                widget.refreshList!();
                Navigator.of(context).pop();
              }
            }
          },
          builder: (context, state) {
            return Stack(
                children: <Widget>[
                  GestureDetector(
                    behavior: HitTestBehavior.translucent, // Important for capturing taps
                    onTap: () {
                      // This will hide the keyboard when tapping anywhere on the screen
                      FocusScope.of(context).unfocus();
                    },
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: msgsStreamBuilder,
                            ),
                          ),
                          const Divider(
                            height: 1.0,
                          ),
                          Container(
                            child: _buildComposer(),
                            decoration: BoxDecoration(color: Theme.of(context).cardColor),
                          )
                        ]
                    ),
                  ),
                  if (state is ChatMessagesLoaded && state.isLoading)
                    Center(child: loadingIndicator),
                ]
            );
          },
        ),
      ),
    );

    return GestureDetector(
        onTap: () {
           FocusScope.of(context).unfocus();
        },
        child: mainScaffold);
  }

  void _addMessages(List<Message> messages) {
    for (var message in messages) {
      if (!_msgsHandlerList
          .any((msghandle) => msghandle.msg!.id == message.id)) {
        MsgHandler msgHandle = MsgHandler(
          server: widget.server,
          chat: _chatCopy!,
          msg: message,
          animationController: AnimationController(
              vsync: this, duration: const Duration(microseconds: 700)),
        );

        _msgsHandlerList.insert(0, msgHandle);
        msgHandle.animationController!.forward();
      }
    }
  }

  // Generate Chat Menu options
  List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder() {
    List<PopupMenuEntry<ChatItemMenuOption>> menuItems = [];

    if (_chatCopy!.status == 1) {
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
    _chatPageBloc!.add(CloseChat(server: widget.server!, chat: _chatCopy!));
  }

  void _deleteChat() async {
    _chatPageBloc!.add(DeleteChat(server: widget.server!, chat: _chatCopy!));
    Navigator.pop(context);
  }

  void _showChatInfo(context) {
    // Set flag to prevent messages reload
    setState(() {
      _showingChatInfo = true;
    });

    TextStyle styling = const TextStyle(
        fontFamily: 'Roboto', fontSize: 16.0, fontWeight: FontWeight.bold);
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Text("Server", style: styling),
                    title: Text("${widget.server!.servername}"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Text("ID", style: styling),
                    title: Text(_chatCopy!.id.toString()),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Text("Email", style: styling),
                    title: Text(_chatCopy!.email ?? ""),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Text("Phone", style: styling),
                    title: Text(_chatCopy!.phone ?? ""),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Text("IP", style: styling),
                    title: new Text(_chatCopy!.ip ?? ""),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: new Text("Country", style: styling),
                    title: new Text(_chatCopy!.country_name ?? ""),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: new Text("From", style: styling),
                    title: new Text(_chatCopy!.referrer ?? ""),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: new Text("User Agent", style: styling),
                    title: new Text(_chatCopy!.uagent ?? ""),
                    onTap: () {},
                  ),
                ],
              ));
        }).then((_) {
      // Reset flag after modal is closed
      setState(() {
        _showingChatInfo = false;
      });
    });
  }

  Widget _buildComposer() {
    /*var cupertinoButton = CupertinoButton(
        child: Text("Send"),
        onPressed: _isWriting ? () => _submitMsg(_textController.text) : null);*/

    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.0),
          child: isAcceptingChat
              ? LinearProgressIndicator()
              : _isNewChat!
              ? InkWell(
            onTap: () {
              setState(() {
                isAcceptingChat = true;
              });
              _acceptChat();
            },
            child: Container(
              color: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 15),
              alignment: Alignment.center,
              child: Text(
                "Accept Chat",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
              : SendMessageRowWidget(
            key: widget.key,
            server: widget.server!,
            chat: _chatCopy,
            isOwnerOfChat: _isOwnerOfChat,
            submitMessage: submitMsg,
            cannedMsgs: _cannedMsgs,
          ),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.brown,
              ),
            ),
          )
              : null),
    );
  }

  void _fetchCannedResponses() async {
    _serverApiClient!.cannedResponses(widget.server!, _chatCopy!).then((chatData) {
      setState(() {
        _cannedMsgs = List<dynamic>.from(chatData["canned_messages"]);
      });
    });
  }

  void _acceptChat() async {
    _serverApiClient!.chatData(widget.server!, _chatCopy!).then((chatData) {
      setState(() {
        var newChat = Chat.fromJson(chatData["chat"]);
        // update chat with new data
        _chatCopy = newChat.copyWith(owner: chatData["ownerstring"]);
        _isNewChat = false;
        _isOwnerOfChat =
            _chatCopy!.user_id.toString() == widget.server!.userid.toString();
        _cancelAccept();
        isChatAccepted = true;
        isAcceptingChat = false;

      });
      _isLoading(false);
    });
  }

  void _isLoading(bool loading) {
    _isActionLoading = loading;
  }

  void submitMsg(String msg,{String? sender}) {
    // _textController.clear();
    _isWriting = false;
    if (_isNewChat! == true) {
      FunctionUtils.showErrorMessage(
          message: "Pending chat! Please accept first");
      return;
    }
    //post message to server and update messages instantly
    _chatPageBloc!.add(
        PostMessage(server: widget.server!, chat: widget.chat!, message: msg,sender: sender,));
  }

  void _textChanged(String text) {
    if (_isWriting == false && text.length > 0) {
      _isWriting = true;

      _operatorTyping();
    } else if (_isWriting == true && text.length == 0) {
      _isWriting = false;
    }

    // Cancel present
    if (_operatorTimer != null && _operatorTimer!.isActive)
      _operatorTimer!.cancel();

    _operatorTimer = Timer(Duration(seconds: 3), () {
      _isWriting = false;
      _operatorTyping();
    });
  }

  void _operatorTyping() async {
    await _serverApiClient!
        .setOperatorTyping(widget.server!, _chatCopy!.id!, _isWriting);
  }

  Future<Null> _syncMessages() async {
    // Skip syncing messages while showing info modal to prevent reload
    if (!_showingChatInfo) {
      _chatPageBloc
          ?.add(FetchChatMessages(server: widget.server!, chat: _chatCopy!));
    }
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _syncMessages();
  }
}

class MsgHandler extends StatelessWidget {
  MsgHandler({required this.server,required this.chat, this.msg, this.animationController});
  final Server? server;
  final Message? msg;
  final Chat? chat;

  final AnimationController? animationController;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: new Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Expanded(
            child: new ChatBubbleExperiment(
              server:server,
              chat: chat,
              message: msg!,
            ),
          )
        ],
      ),
    );
  }
}