import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///ErrorReloadButton(String message, String actionText, void Function() buttonAction)
///@message Error message to display, @actionText text to display on button
///@buttonAction function to execute on button press
///
class ErrorReloadButton extends StatelessWidget {
  final String message;
  final String actionText;
  final Function onButtonPress;
  ErrorReloadButton(
      {Key key,
      this.message,
      @required this.onButtonPress,
      @required this.actionText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: <Widget>[
      Text(message ?? ''),
      MaterialButton(
        child: Text(actionText),
        onPressed: onButtonPress(),
      ),
    ]));
  }
}
