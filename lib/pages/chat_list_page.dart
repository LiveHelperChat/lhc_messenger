import 'package:flutter/material.dart';

import 'package:livehelp/pages/token_inherited_widget.dart';

class ChatListPage extends StatefulWidget{
  @override
  _ChatListPageState createState()=> new _ChatListPageState();

}

class _ChatListPageState extends State<ChatListPage>{


  @override
  Widget build(BuildContext context) {
    final inheritedTokenWidget = TokenInheritedWidget.of(context);
   return new Scaffold(

     body: new Column(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         new Padding(
           padding: new EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0),
           child: new Text(inheritedTokenWidget.token,
             textAlign: TextAlign.center,
             style: new TextStyle(
               height: 2.0,
             ),
           ),
         ),

       ]));
  }

}