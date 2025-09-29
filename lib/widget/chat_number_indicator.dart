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
      Badge(
        alignment: AlignmentDirectional.topEnd, // corner, not over center
        backgroundColor: Colors.white,
        isLabelVisible: number != '0',          // hide when 0
        label: Text(
          number,
          style: TextStyle(
            fontSize: 10,
            height: 1,
            color: Theme.of(context).primaryColorDark,
          ),
          softWrap: false,
        ),
        child: Padding(                              // move icon down
          padding: const EdgeInsets.only(top: 20,left:2),
          child: Icon(icon, size: 14, color: colorIcon),
        ),
      )
    ;

  }

}