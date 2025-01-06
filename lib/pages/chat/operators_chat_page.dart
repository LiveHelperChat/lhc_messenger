// ignore_for_file: unused_field

import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/bloc/bloc.dart';
import 'package:livehelp/globals.dart' as globals;
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/widget/widget.dart';
import 'package:rxdart/rxdart.dart';

/// place: "/chats/operatorschat"
class OperatorsChatPage extends StatefulWidget {
  OperatorsChatPage(
      {Key? key,
      this.server,
      this.chat,
      this.refreshList,
      required this.isNewChat})
      : super(key: key);

  final User? chat; // not final because we will update it
  final Server? server;
  final bool? isNewChat; // used to determine pending or other chats

  final VoidCallback? refreshList;

  @override
  OperatorsChatPageState createState() => OperatorsChatPageState();
}

class OperatorsChatPageState extends State<OperatorsChatPage>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AfterLayoutMixin<OperatorsChatPage>,
        RouteAware {
  final _writingSubject = PublishSubject<String>();

  // used to track application lifecycle
  AppLifecycleState? _lastLifecyleState;

  GlobalKey<ScaffoldState> _scaffoldState = new GlobalKey<ScaffoldState>();

  bool? _isNewChat; // is pending chat or not
  bool _isOwnerOfChat = false;

  User? _chatCopy;

  ChatOperatorsMessagesBloc? _chatPageBloc;
  FcmTokenBloc? _fcmTokenBloc;

  List<dynamic> _cannedMsgs = List.empty();

  List<OperatorsMsgHandler> _msgsHandlerList = <OperatorsMsgHandler>[];
  TextEditingController _textController = TextEditingController();
  ServerApiClient? _serverApiClient;

  List<PopupMenuEntry<ChatItemMenuOption>>? menuBuilder;

  Timer? _msgsTimer;
  Timer? _acceptTimer;
  Timer? _operatorTimer;

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

    // stop sending notifications for this chat
    _fcmTokenBloc = context.read<FcmTokenBloc>()
      ..add(OperatorsChatOpenedEvent(chat: _chatCopy!));

    _acceptChat();
  }

  @override
  void dispose() {
    for (OperatorsMsgHandler msg in _msgsHandlerList) {
      msg.animationController!.dispose();
    }

    if (_msgsTimer != null && _msgsTimer!.isActive) {
      _msgsTimer!.cancel();
    }

    if (_operatorTimer != null && _operatorTimer!.isActive) {
      _operatorTimer!.cancel();
    }

    _writingSubject.close();
    _isWritingSubject.close();
    _isActionLoadingSubject.close();
    _fcmTokenBloc!.add(OperatorsChatClosedEvent(chat: _chatCopy!));
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
    _fcmTokenBloc!.add(OperatorsChatOpenedEvent(chat: _chatCopy!));
  }

  // Called when the current route has been pushed.
  @override
  void didPop() {
    _fcmTokenBloc!.add(OperatorsChatClosedEvent(chat: _chatCopy!));
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
        _fcmTokenBloc!.add(OperatorsChatOpenedEvent(chat: _chatCopy!));
        _syncMessages();
        _msgsTimer = _syncMsgsTimer(5);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        //allow showing notifications for this chat
        _fcmTokenBloc!.add(OperatorsChatPausedEvent(chat: _chatCopy!));
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
    var _serverRepository = context.watch<ServerRepository>();
    // Chat page creates and manages it's own bloc.
    _chatPageBloc =
        ChatOperatorsMessagesBloc(serverRepository: _serverRepository);
    TextStyle headerbottom = const TextStyle(
      fontSize: 12.0,
      height: 1,
      color: Colors.white,
      fontWeight: FontWeight.w300,
    );

    var msgsStreamBuilder =
        BlocBuilder<ChatOperatorsMessagesBloc, ChatOperatorsMessagesState>(
            bloc: _chatPageBloc,
            builder: (context, state) {
              if (state is ChatOperatorsMessagesInitial) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is ChatOperatorsMessagesLoadError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is ChatOperatorsMessagesLoaded) {
                _addMessages(state.messages);

                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  reverse: true,
                  padding: EdgeInsets.all(6.0),
                  itemBuilder: (BuildContext context, int index) {
                    return _msgsHandlerList[index];
                  },
                  itemCount: _msgsHandlerList.length,
                );
              }
              return const Text("No messages");
            });

    var popupMenuBtn = PopupMenuButton<ChatItemMenuOption>(
        onSelected: (ChatItemMenuOption result) {
      onMenuOptionChanged(result);
    }, itemBuilder: (BuildContext context) {
      return _itemMenuBuilder();
    });

    Widget loadingIndicator =
        _isActionLoading ? const CircularProgressIndicator() : Container();

    var mainScaffold = BlocProvider<ChatOperatorsMessagesBloc>(
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
                  RichText(
                    text: TextSpan(
                      children: [
                        WidgetSpan(
                            style: const TextStyle(height: 1, fontSize: 17),
                            child: BlocBuilder<ChatOperatorsMessagesBloc,
                                    ChatOperatorsMessagesState>(
                                bloc: _chatPageBloc,
                                builder: (context, state) {
                                  if (state is ChatOperatorsMessagesLoaded) {
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
                          style: const TextStyle(height: 2, fontSize: 15),
                          text: ' ${_chatCopy!.name_official}',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.people,
                        size: 17,
                        color: Colors.white,
                      ),
                      Text(
                        ' owner',
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
                IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showChatInfo(context)),
                popupMenuBtn
              ],
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(25.0),
                  child: Container(
                      height: 28.0,
                      padding: const EdgeInsets.only(
                          top: 0.0, left: 73.0, right: 8.0),
                      alignment: Alignment.centerLeft,
                      child: BlocBuilder<ChatOperatorsMessagesBloc,
                          ChatOperatorsMessagesState>(
                        bloc: _chatPageBloc,
                        builder: (context, state) {
                          if (state is ChatOperatorsMessagesLoaded) {
                            return Text(
                              state.chatStatus,
                              softWrap: true,
                              style: const TextStyle(
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
            body: BlocConsumer<ChatOperatorsMessagesBloc,
                ChatOperatorsMessagesState>(
              listener: (context, state) {
                if (state is ChatOperatorsMessagesLoaded) {
                  if (state.isChatClosed) {
                    widget.refreshList!();
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
                  if (state is ChatOperatorsMessagesLoaded && state.isLoading)
                    Center(child: loadingIndicator)
                ]);
              },
            )));

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
        OperatorsMsgHandler msgHandle = OperatorsMsgHandler(
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

    /*if (_chatCopy.status == 1) {
      menuItems.add(const PopupMenuItem<ChatItemMenuOption>(
        value: ChatItemMenuOption.CLOSE,
        child: const Text('Close'),
      ));
    }*/

    /*menuItems.add(const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.REJECT,
      child: const Text('Delete'),
    ));*/

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
      default:
        break;
    }
  }

  void _closeChat() async {
    //_chatPageBloc.add(CloseChat(server: widget.server, chat: _chatCopy));
  }

  void _deleteChat() async {
    //_chatPageBloc.add(DeleteChat(server: widget.server, chat: _chatCopy));
  }

  void _showChatInfo(context) {
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
                title: Text(_chatCopy!.user_id.toString()),
                onTap: () {},
              )
            ],
          ));
        });
  }

  Widget _buildComposer() {
    var iconButton = IconButton(
        icon: const Icon(Icons.send),
        onPressed: () {
          if (_textController.text.isNotEmpty) _submitMsg(_textController.text);
        });

    return IconTheme(
      data: IconThemeData(color: Colors.accents.first),
      child: Container(
          margin: const EdgeInsets.fromLTRB(5.0, 0, 0, 0),
          child: Row(
            children: <Widget>[
              Flexible(
                  child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: null,
                      enableInteractiveSelection: true,
                      onChanged: (txt) => (_writingSubject.add(txt)),
                      onSubmitted: _submitMsg,
                      decoration: new InputDecoration(
                          hintText: "Enter a message to send",
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none))),
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 0.0),
                child: iconButton,
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
    _serverApiClient!
        .chatOperatorsData(widget.server!, _chatCopy!)
        .then((chatData) {
      setState(() {
        //developer.log(jsonEncode(chat.toJson()), name: 'my.app.category');
        //print(chatData['id']);

        // update chat with new data
        _chatCopy!.chat_id = chatData['id'];

        _isNewChat = false;

        _cancelAccept();

        _syncMessages();

        _msgsTimer = _syncMsgsTimer(5);
      });
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
    _chatPageBloc!.add(PostOperatorsMessage(
        server: widget.server!, chat: widget.chat!, message: msg));
  }

  void _textChanged(String text) {
    if (_isWriting == false && text.isNotEmpty) {
      _isWriting = true;

      _operatorTyping();
    } else if (_isWriting == true && text.length == 0) {
      _isWriting = false;
    }

    // Cancel present
    if (_operatorTimer != null && _operatorTimer!.isActive) {
      _operatorTimer!.cancel();
    }

    _operatorTimer = Timer(const Duration(seconds: 3), () {
      _isWriting = false;
      _operatorTyping();
    });
  }

  void _operatorTyping() async {
    /*await _serverApiClient.setOperatorTyping(
        widget.server, _chatCopy.id, _isWriting);*/
  }

  Future<void> _syncMessages() async {
    _chatPageBloc?.add(
        FetchOperatorsChatMessages(server: widget.server!, chat: _chatCopy!));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    _syncMessages();
  }
}

class OperatorsMsgHandler extends StatelessWidget {
  const OperatorsMsgHandler({this.chat, this.msg, this.animationController});
  final Message? msg;
  final User? chat;
  final AnimationController? animationController;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ChatBubbleCustom(
                  message: msg!,
                ),
              )
            ]));
  }
}
