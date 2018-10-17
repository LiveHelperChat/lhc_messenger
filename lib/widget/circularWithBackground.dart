
import 'package:flutter/material.dart';

class CircularProgressWithBackground extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Colors.grey.shade300,
      width: 70.0,
      height: 70.0,
      child: new Padding(padding: const EdgeInsets.all(5.0),
          child: new Center(child: new CircularProgressIndicator())),
    );
  }
}