// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livehelp/utils/utils.dart';

class OfficeTimePicker extends StatefulWidget {
  OfficeTimePicker(
      {required this.isChecked,
      required this.startTime,
      required this.endTime,
      required this.startTimeChanged,
      required this.endTimeChanged});

  final ValueChanged<String> startTimeChanged;
  final ValueChanged<String> endTimeChanged;
  final String startTime;
  final String endTime;
  final bool isChecked;

  @override
  _OfficeTimePickerState createState() => _OfficeTimePickerState();
}

class _OfficeTimePickerState extends State<OfficeTimePicker> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String? _startString;
  String? _endString;

  @override
  void initState() {
    super.initState();
    //  _refreshThis();
  }

  _refreshThis() {
    _startTime = _parseTimeOfDay(widget.startTime);
    _endTime = _parseTimeOfDay(widget.endTime);

    _startString = _toTimeFormat(_timeOfDayToString(_startTime!));
    _endString = _toTimeFormat(_timeOfDayToString(_endTime!));
  }

  @override
  Widget build(BuildContext context) {
    _refreshThis();
    if (!(widget.isChecked)) {
      _startString = widget.startTime;
      _endString = widget.endTime;

      return Container();
    } else
      return new Offstage(
        offstage: !widget.isChecked,
        child: ButtonBarTheme(
          data: Theme.of(context).buttonBarTheme,
          child: new ButtonBar(
            alignment: MainAxisAlignment.start,
            children: <Widget>[
              new TextButton(
                child: new Text('From: $_startString'),
                onPressed: () {
                  _selectTime(context, _startTime!).then((val) {
                    // print(_endTime.toString()+" : "+val.toString());
                    if (val.hour > _endTime!.hour) {
                      _showDialog();
                    } else {
                      setState(() {
                        _startTime = val;
                        _startString =
                            val.hour.toString() + ":" + val.minute.toString();
                      });
                      var ttime = int.parse(_timeOfDayToString(val)).toString();
                      widget.startTimeChanged(ttime);
                    }
                  });
                },
              ),
              new TextButton(
                child: new Text('To: $_endString'),
                onPressed: () {
                  _selectTime(context, _endTime!).then((val) {
                    // print(_startTime.toString()+" : "+val.toString());
                    if (_startTime!.hour > val.hour) {
                      _showDialog();
                    } else {
                      setState(() {
                        _endTime = val;
                        _endString =
                            val.hour.toString() + ":" + val.minute.toString();
                      });
                      var ttime = int.parse(_timeOfDayToString(val)).toString();
                      widget.endTimeChanged(ttime);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      );
  }

  void _showDialog() {
    WidgetUtils.creatDialog(context,
        "Starting time should be earlier than Ending time. Select ending time first.");
  }

  Future<TimeOfDay> _selectTime(
      BuildContext context, TimeOfDay initialTime) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: initialTime);

    return picked ?? new TimeOfDay(hour: 0, minute: 0);
  }

  TimeOfDay _parseTimeOfDay(String value) {
    if (value != '') {
      String padded = "00";
      if (int.parse(value) >= 0) {
        padded = value.padLeft(4, '0');
        return TimeOfDay(
            hour: int.parse(padded.substring(0, 2)),
            minute: int.parse(padded.substring(2, 4)));
      } else {
        return TimeOfDay.now();
      }
    } else {
      return TimeOfDay.now();
    }
  }

  String _timeOfDayToString(TimeOfDay time) {
    return time.hour.toString().padLeft(2, "0") +
        time.minute.toString().padLeft(2, "0");
  }

  String _toTimeFormat(String time) {
    String padded;
    padded = time.padLeft(4, '0');
    return padded.substring(0, 2) + ":" + padded.substring(2, 4);
  }
}
