import 'package:flutter/material.dart';

class ChatNumberIndcator extends StatelessWidget{

  ChatNumberIndcator({this.title,this.offstage,this.number});

  final bool offstage;
  final String title;
  final String number; // number to display

  @override
  Widget build(BuildContext context) {
    return
       Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(title,textAlign: TextAlign.center,style: new TextStyle(fontSize: 12.0),),
           Offstage(
            offstage: offstage,
            child:  Container(
              padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 5.0),
              margin: const EdgeInsets.all( 2.0),
              decoration: new BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: new Text(
                number,
                style: new TextStyle(
                  fontSize: 8.0,
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