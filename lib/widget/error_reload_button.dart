import 'package:flutter/material.dart';

///ErrorReloadButton(String message, String actionText, void Function() buttonAction)
///@message Error message to display, @actionText text to display on button
///@onButtonPress function to execute on button press
///
class ErrorReloadButton extends StatelessWidget {
  final Widget? child;
  final String actionText;
  final Function onButtonPress;
  const ErrorReloadButton(
      {Key? key,
      this.child,
      required this.onButtonPress,
      required this.actionText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          child ?? Container(),
          ElevatedButton(
            child: Text(actionText),
            onPressed: () {
              onButtonPress();
            },
          ),
        ]));
  }
}
