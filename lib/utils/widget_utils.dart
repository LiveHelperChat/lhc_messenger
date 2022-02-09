import 'package:flutter/material.dart';

class WidgetUtils {
  static addClick(Widget widget, Function param1) {
    return GestureDetector(child: widget, onTap: () => param1);
  }

  static creatDialog(BuildContext context, String resp) {
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Live help"),
          content: Text(resp),
          /* actions: <Widget>[
          new FlatButton(
              child:const Text("ok"),
              onPressed: (){
                // Navigator.of(context).pop();
              } ),
        ],  */
        );
      },
    );
  }

  static int? checkInt(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value ? 1 : 0;
    return value is int ? value : int.parse(value);
  }
}
