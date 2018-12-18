import 'package:flutter/material.dart';

class ChatNumberIndcator extends StatelessWidget{

  ChatNumberIndcator({this.title,this.offstage,this.number});

  final bool offstage;
  final String title;
  final String number; // number to display

  @override
  Widget build(BuildContext context) {
    return
      new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Text(title,textAlign: TextAlign.center,style: new TextStyle(fontSize: 12.0),),
          new Offstage(
            offstage: offstage,
            child: new Container(
              padding: const EdgeInsets.symmetric(vertical: 2.0,horizontal: 2.0),
              width: 18.0,
              height: 18.0,
              margin: const EdgeInsets.only(left: 2.0),
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: new Text(
                number,
                style: new TextStyle(
                  fontSize: 11.0,
                  color: Theme.of(context).primaryColorDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
  }

}