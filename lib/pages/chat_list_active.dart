import 'dart:async';
import 'package:flutter/material.dart';


import 'package:async_loader/async_loader.dart';
import 'package:livehelp/utils/server_requests.dart';


import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/widget/chat_item_widget.dart';
import 'package:livehelp/pages/chat_page.dart';
import 'package:livehelp/utils/routes.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

class ActiveListWidget extends StatefulWidget {
  ActiveListWidget({Key key,this.listOfServers,this.listToAdd,this.loadingState,this.chatRemoved}):super(key:key);

  final List<Chat> listToAdd;
  final List<Server> listOfServers;

  final ValueChanged<bool> loadingState;
  final ValueChanged<Chat> chatRemoved;


  @override
  _ActiveListWidgetState createState() => new _ActiveListWidgetState();
}

  

class _ActiveListWidgetState extends State<ActiveListWidget> {

  ServerRequest _serverRequest;
  List<Chat> _listToAdd;
  List<dynamic> _listForTransfer;

  @override
  void initState() {
    super.initState();

    _serverRequest = new ServerRequest();
    _listForTransfer =new List();
    _listToAdd = widget.listToAdd;
  }

  @override
  Widget build(BuildContext context) {
    final inheritedTokenWidget = TokenInheritedWidget.of(context);

    return new Scaffold(
        body:new RefreshIndicator(
          onRefresh: _onRefresh,
          child: new ListView.builder(
          itemCount:_listToAdd.length,
          itemBuilder: _itemBuilder),
     ));
  }


  Widget _itemBuilder(BuildContext context,int index){

    List<Chat> listToReverse = _listToAdd;
   //TODO
    // listToReverse.sort((x,y)=>x.last_msg_time.compareTo(y.last_msg_time));

    List<Chat> reversedList = listToReverse.reversed.toList();
   Chat chat = reversedList[index];
   Server server = widget.listOfServers.firstWhere((srvr)=>srvr.id == chat.serverid);
    return new GestureDetector(
        child:  new ChatItemWidget(server:server,chat: chat,menuBuilder:_itemMenuBuilder(), onMenuSelected: (selectedOption){onItemSelected(context,server,chat,selectedOption);},),
        onTap:(){
    var route = new FadeRoute(
      settings: new RouteSettings(name: "/chats/chat"),
      builder: (BuildContext context) => new ChatPage(server:server,chat: chat,isNewChat: false,),
    );
    Navigator.of(context).push(route);
  } ,
      
    );
  }

List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder(){
return <PopupMenuEntry<ChatItemMenuOption>>[
    const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.CLOSE,
      child: const Text('Close'),
    ),
    const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.REJECT,
      child: const Text('Delete'),
    ),
    const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.TRANSFER,
      child: const Text('Transfer'),
    ),
  ];
}


  void onItemSelected(BuildContext ctx,Server srv,Chat chat,ChatItemMenuOption result){
    switch(result){
    case ChatItemMenuOption.CLOSE:
      widget.loadingState(true);
      _closeChat(srv,chat);
    break;
    case ChatItemMenuOption.REJECT:
      widget.loadingState(true);
      _deleteChat(srv,chat);
      break;
      case ChatItemMenuOption.TRANSFER:
       // widget.loadingState(true);
        _showOperatorList(context,srv,chat);
        //_getOperatorList(ctx,srv,chat);
        break;
    default:
      break;
    }

   // print(result.value.toString());
  }

  void _closeChat(Server srv,Chat chat)async{
    await _serverRequest.closeChat(srv,chat)
        .then((loaded) {
      widget.loadingState(false);
      _updateList(chat);

    });

  }

  void _deleteChat(Server srv,Chat chat)async{

    await _serverRequest.deleteChat(srv,chat).then((loaded){
      widget.loadingState(false);
    //  widget.chatRemoved()
        _updateList(chat);
    });
  }


  void _updateList(chat){
    setState((){
      _listToAdd.removeWhere((cht) => chat.id == cht.id );
    });
  }

  Future<List<dynamic>>  _getOperatorList(BuildContext context,Server srvr,Chat chat)async{
   return await _serverRequest.getOperatorsList(srvr)
    .then((list){

    //  widget.loadingState(false);
      return list;
    });
  }


  Future<Null> _onRefresh(){
    Completer<Null> completer = new Completer<Null>();
    Timer timer = new Timer(new Duration(seconds: 3), () {
      completer.complete();
    });
    return completer.future;
  }

  void _showOperatorList(BuildContext context,Server srvr,Chat chat){

    var futureBuilder = new FutureBuilder(
      future: _getOperatorList(context, srvr, chat),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return new Text('loading...');
          default:
            if (snapshot.hasError)
              return new Text('Error: ${snapshot.error}');
            else
              return createListView(context, snapshot,srvr,chat);
        }
      },
    );

    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return new Container(
              child: new Padding(
                  padding: const EdgeInsets.all(4.0),
                  child:new Column(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      new Text("Select online operator",
                        style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 16.0),),
                      new Divider(),
                      Expanded(
                        child:futureBuilder ,
                      )
                    ],
                  )
                ,));
        });
  }

  void _transferToUser(Server srvr,Chat chat,int userid)async{
   await _serverRequest.transferChatUser(srvr,chat,userid)
   .then((value)=>widget.loadingState(false));
  }

  Widget createListView(BuildContext context, AsyncSnapshot snapshot,Server srvr,Chat chat) {
    List<dynamic> listOP = snapshot.data;


    return listOP != null ? new ListView.builder(
      reverse: false,
      padding: new EdgeInsets.all(6.0),
      itemCount: listOP.length,
      itemBuilder: (_, int index) {
        Map operator = listOP[index];
        return  new ListTile(
              title: new Text('Name: ${operator["name"]} ${operator["surname"]}'),
              subtitle: new Text('Title: ${operator["job_title"]}'),
              onTap: () {
                Navigator.of(context).pop();
                widget.loadingState(true);
                // TODO transfer here
                _transferToUser(srvr,chat,int.parse(operator['id']));
              },
            );
      },
    ) : new Text('No online operator found!');
  }

}


