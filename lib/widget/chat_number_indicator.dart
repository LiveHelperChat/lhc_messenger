import 'package:flutter/material.dart';

class ChatNumberIndcator extends StatelessWidget{

  ChatNumberIndcator({required this.title,required this.offstage,required this.number});

  final bool offstage;
  final String title;
  final String number; // number to display

  @override
  Widget build(BuildContext context) {

    Map <String,IconData> icons = {
      'Operators' : Icons.support_agent,
      'Bot' : Icons.android,
      'Transfer' : Icons.transfer_within_a_station,
      'Subject' : Icons.label,
    };
    IconData? icon = icons.containsKey(title) ? icons[title] : Icons.message;

    Map <String,Color> colors = {
      'Operators' : Colors.green.shade400,
      'Bot' : Colors.green.shade400,
      'Transfer' : Colors.green.shade400,
      'Subject' :Colors.green.shade400,
      'Pending' :Colors.yellow.shade400,
      'Closed' :Colors.red.shade400,
    };

    Color? colorIcon = colors.containsKey(title) ? colors[title] : Colors.green.shade400;

    return
      Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.bottomCenter,
            child: new Icon(
                icon,
                size: 14,
                color: colorIcon
            ),
          ),
          Offstage(
            offstage: offstage,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 6.0),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Text(
                  number,
                  style: TextStyle(
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