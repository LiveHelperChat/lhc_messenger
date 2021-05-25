import 'package:flutter/material.dart';

class ChatNumberIndcator extends StatelessWidget{

  ChatNumberIndcator({this.title,this.offstage,this.number});

  final bool offstage;
  final String title;
  final String number; // number to display

  @override
  Widget build(BuildContext context) {
    return
       Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child:Text(title,textAlign: TextAlign.center,
            style:  TextStyle(
              fontSize: 12.0),), 
          ),          
           Offstage(
            offstage: offstage,
            child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 6.0),
              margin: const EdgeInsets.only(bottom: 8.0),
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: new Text(
                number,
                style: new TextStyle(
                  fontSize: 9.0,
                  color: Theme.of(context).primaryColorDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ),
          ),
        ],
      );
  }

}