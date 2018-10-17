import 'dart:async';
import 'package:flutter/material.dart';

import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/widget/chat_item_widget.dart';
import 'package:livehelp/pages/chat_page.dart';
import 'package:livehelp/utils/routes.dart';
import 'package:livehelp/utils/server_requests.dart';

import 'package:livehelp/utils/enum_menu_options.dart';

class TransferredListWidget extends StatefulWidget {
  TransferredListWidget({Key key,this.listOfServers,this.listToAdd,this.loadingState}):super(key:key);

  final List<Chat> listToAdd;
  final List<Server> listOfServers;

  final ValueChanged<bool> loadingState;

  @override
  _TransferredListWidgetState createState() => new _TransferredListWidgetState();
}


class _TransferredListWidgetState extends State<TransferredListWidget> {

  ServerRequest _serverRequest;


  @override
  void initState(){
    super.initState();
    _serverRequest = new ServerRequest();
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body:new RefreshIndicator(
          onRefresh: _onRefresh,
          child: new ListView.builder(
          itemCount:widget.listToAdd.length,
          itemBuilder: _itemBuilder),
     ));
  }

List<PopupMenuEntry<ChatItemMenuOption>> _itemMenuBuilder(){
return <PopupMenuEntry<ChatItemMenuOption>>[
  /*  const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.ACCEPT,
      child: const Text('Accept Chat'),
    ),  */
    const PopupMenuItem<ChatItemMenuOption>(
      value: ChatItemMenuOption.ACCEPT,
      child: const Text('Accept Chat'),
    ),
  ];
}

 Widget _itemBuilder(BuildContext context,int index){
   Chat chat = widget.listToAdd[index];
   Server server = widget.listOfServers.firstWhere((srvr)=>srvr.id == chat.serverid);
    return new GestureDetector(
        child:  new ChatItemWidget(
          server:server,chat: chat,menuBuilder:_itemMenuBuilder(),
         onMenuSelected:(selectedOption){ onItemSelected(server,chat,selectedOption);},),
        onTap:() {

  } ,
      
    );
  }


  void onItemSelected(Server srvr,Chat chat,ChatItemMenuOption selectedMenu){

    switch(selectedMenu){
      case ChatItemMenuOption.ACCEPT:
        widget.loadingState(true);
      _acceptChat(srvr, chat);
        break;
      default:
        break;
    }
    print(selectedMenu.value.toString());
  }


  void _acceptChat(Server srv,Chat chat)async{
    //TODO accept chat
    await _serverRequest.acceptChatTransfer(srv,chat)
        .then((loaded){
          widget.loadingState(false);

       var route = new FadeRoute(
      settings: new RouteSettings(name: "/chats/chat"),

      builder: (BuildContext context) => new ChatPage(server:srv,chat: chat,isNewChat: false,), );

    Navigator.of(context).push(route);

        });

  }


  Future<Null> _onRefresh(){
    Completer<Null> completer = new Completer<Null>();
    Timer timer = new Timer(new Duration(seconds: 3), () {
      completer.complete();
    });
    return completer.future;
  }

}
