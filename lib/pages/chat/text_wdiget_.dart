import 'dart:async';

import 'package:flutter/material.dart';

//A widget which shows time left for sound message
class UpdatingTextWidget extends StatefulWidget {
  @override
  _UpdatingTextWidgetState createState() => _UpdatingTextWidgetState();
}

class _UpdatingTextWidgetState extends State<UpdatingTextWidget> {
  Timer? _timer;
  int _totalSeconds = 30; // Counter for elapsed seconds

  @override
  void initState() {
    super.initState();
    startTimer(); // Start the timer
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (_totalSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() {
        _totalSeconds--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "${_totalSeconds} s",
      style: TextStyle(color: Colors.red),
    );
  }
}
