import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/utils/utils.dart';
import 'package:livehelp/widget/widget.dart';

class DepartmentHours extends StatefulWidget {
  const DepartmentHours({this.server});
  final Server? server;
  @override
  _DepartmentHoursState createState() => _DepartmentHoursState();
}

class _DepartmentHoursState extends State<DepartmentHours> {
  DatabaseHelper? _dbHelper;
  ServerApiClient? _serverRequest;

  Future<dynamic>? _myInitState;
  Server? _localServer;
  List<Server> listServers = <Server>[];
  List<Department> userDepartments = <Department>[];
  Department? _department;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _onlineHoursActive = false;
  bool _sundayHoursActive = false;
  bool _mondayHoursActive = false;
  bool _tuesdayHoursActive = false;
  bool _wednesdayHoursActive = false;
  bool _thursdayHoursActive = false;
  bool _fridayHoursActive = false;
  bool _saturdayHoursActive = false;

  bool _isLoading = false;

  ValueChanged<TimeOfDay>? selectTime;

  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _serverRequest = ServerApiClient(httpClient: http.Client());
    _localServer = widget.server;

    _syncServerData();
    _myInitState = _initAsyncloader();
  }

  @override
  Widget build(BuildContext context) {
    Widget loadingIndicator =
        _isLoading ? const CircularProgressIndicator() : Container();
    var scaff = Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        appBar: AppBar(
          title:
              Text(widget.server!.servername!), // new Text("Server Details"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
            /* new Offstage(
                offstage:_isLoading,
                child: new IconButton(
                    icon: new CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      ),onPressed: null,)),  */
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: Colors.transparent),
                ), // This replaces `textColor` in FlatButton
              ),
              child: const Text("Refresh"),
              onPressed: () {
                _initAsyncloader();
              },
            )
          ],
        ),
        body: Stack(children: <Widget>[
          Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: ListTile(
                  title: const Text(
                    "Select Department",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Set Department work hours/days active",
                    style: new TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white),
                margin: const EdgeInsets.only(bottom: 4.0),
                child: ListTile(
                  trailing: Offstage(
                    offstage: _department == null,
                    child: Checkbox(
                        value: _onlineHoursActive,
                        onChanged: (val) {
                          setState(() {
                            _onlineHoursActive = val!;
                          });
                        }),
                  ),
                  title: _department == null
                      ? const Text(
                          "Could not load department hours from server.\nCheck your network connection. ",
                          style: TextStyle(
                              fontSize: 14.0, fontWeight: FontWeight.bold),
                        )
                      : DropdownButton(
                          isExpanded: true,
                          value: _department,
                          items: userDepartments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: new Text('${dept.name}'),
                            );
                          }).toList(),
                          onChanged: _onDeptListChanged),
                ),
              ),
              new Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: const Text('Sunday'),
                              subtitle: OfficeTimePicker(
                                  isChecked:
                                      _sundayHoursActive || _department != null
                                          ? _department!.sundayActive
                                          : false,
                                  startTime: _department != null
                                      ? _department!.sud_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.sud_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.sud_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.sud_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: Checkbox(
                                value: _sundayHoursActive || _department != null
                                    ? _department!.sundayActive
                                    : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.sud_start_hour = "-1";
                                      _department!.sud_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.sud_start_hour = "00";
                                    _department!.sud_end_hour = "00";
                                  }
                                  setState(() {
                                    _mondayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: const Text('Monday'),
                              subtitle: OfficeTimePicker(
                                  isChecked:
                                      _mondayHoursActive || _department != null
                                          ? _department!.mondayActive
                                          : false,
                                  startTime: _department != null
                                      ? _department!.mod_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.mod_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.mod_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.mod_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: new Checkbox(
                                value: _mondayHoursActive || _department != null
                                    ? _department!.mondayActive
                                    : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.mod_start_hour = "-1";
                                      _department!.mod_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.mod_start_hour = "00";
                                    _department!.mod_end_hour = "00";
                                  }
                                  setState(() {
                                    _mondayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: new Text('Tuesday'),
                              subtitle: OfficeTimePicker(
                                  isChecked:
                                      _tuesdayHoursActive || _department != null
                                          ? _department!.tuesdayActive
                                          : false,
                                  startTime: _department != null
                                      ? _department!.tud_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.tud_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.tud_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.tud_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: new Checkbox(
                                value:
                                    _tuesdayHoursActive || _department != null
                                        ? _department!.tuesdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.tud_start_hour = "-1";
                                      _department!.tud_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.tud_start_hour = "00";
                                    _department!.tud_end_hour = "00";
                                  }
                                  setState(() {
                                    _tuesdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: new Text('Wednesday'),
                              subtitle: OfficeTimePicker(
                                  isChecked: _wednesdayHoursActive ||
                                          _department != null
                                      ? _department!.wednesdayActive
                                      : false,
                                  startTime: _department != null
                                      ? _department!.wed_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.wed_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.wed_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.wed_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: new Checkbox(
                                value:
                                    _wednesdayHoursActive || _department != null
                                        ? _department!.wednesdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.wed_start_hour = "-1";
                                      _department!.wed_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.wed_start_hour = "00";
                                    _department!.wed_end_hour = "00";
                                  }
                                  setState(() {
                                    _wednesdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: new Text('Thursday'),
                              subtitle: OfficeTimePicker(
                                  isChecked: _thursdayHoursActive ||
                                          _department != null
                                      ? _department!.thursdayActive
                                      : false,
                                  startTime: _department != null
                                      ? _department!.thd_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.thd_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.thd_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.thd_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: new Checkbox(
                                value:
                                    _thursdayHoursActive || _department != null
                                        ? _department!.thursdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.thd_start_hour = "-1";
                                      _department!.thd_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.thd_start_hour = "00";
                                    _department!.thd_end_hour = "00";
                                  }
                                  setState(() {
                                    _thursdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: const Text('Friday'),
                              subtitle: OfficeTimePicker(
                                  isChecked:
                                      _fridayHoursActive || _department != null
                                          ? _department!.fridayActive
                                          : false,
                                  startTime: _department != null
                                      ? _department!.frd_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.frd_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.frd_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.frd_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: Checkbox(
                                value: _fridayHoursActive || _department != null
                                    ? _department!.fridayActive
                                    : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.frd_start_hour = "-1";
                                      _department!.frd_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.frd_start_hour = "00";
                                    _department!.frd_end_hour = "00";
                                  }
                                  setState(() {
                                    _fridayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        Offstage(
                          offstage: !_onlineHoursActive,
                          child: ListTile(
                              title: const Text('Saturday'),
                              subtitle: OfficeTimePicker(
                                  isChecked: _saturdayHoursActive ||
                                          _department != null
                                      ? _department!.saturdayActive
                                      : false,
                                  startTime: _department != null
                                      ? _department!.sad_start_hour!
                                      : '',
                                  endTime: _department != null
                                      ? _department!.sad_end_hour!
                                      : '',
                                  startTimeChanged: (time) {
                                    setState(() {
                                      _department?.sad_start_hour = time;
                                    });
                                  },
                                  endTimeChanged: (time) {
                                    setState(() {
                                      _department?.sad_end_hour = time;
                                    });
                                  }),
                              onTap: () {
                                _selectTime(context);
                              },
                              trailing: Checkbox(
                                value:
                                    _saturdayHoursActive || _department != null
                                        ? _department!.saturdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val!) {
                                    setState(() {
                                      _department!.sad_start_hour = "-1";
                                      _department!.sad_end_hour = "-1";
                                    });
                                  } else {
                                    _department!.sad_start_hour = "00";
                                    _department!.sad_end_hour = "00";
                                  }
                                  setState(() {
                                    _saturdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _department?.online_hours_active = _onlineHoursActive;
                  _isLoading = true;
                  _serverRequest!
                      .setDepartmentWorkHours(_localServer!, _department)
                      .then((value) {
                    if (value['error'] == false) {
                      WidgetUtils.creatDialog(
                          context, "Working hours saved successfully.");
                    }
                    _isLoading = false;
                  });
                },
                child: const Text(
                  "Save Data",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          new Center(child: loadingIndicator),
        ]));

    return FutureBuilder<dynamic>(
        future: _myInitState,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Something is wrong'),
              ),
            );
          } else if (snapshot.hasData) {
            return scaff;
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        });
  }

  Future<dynamic> _initAsyncloader() async {
    _isLoading = true;
    //  await _fetchServerDetails();
    await _syncServerData();
    setState(() {
      _isLoading = false;
      print("_isLoading setState false");
    });
    return Future.value("complete");
  }

  Future<void> _syncServerData() async {
    if (_localServer != null) {
      var user = await _serverRequest!.getUserFromServer(_localServer!);

      setState(() {
        _localServer!.userid = user['id'];
        _localServer!.firstname = user['name'];
        _localServer!.surname = user['surname'];
        _localServer!.operatoremail = user['email'];
        _localServer!.job_title = user['job_title'];
        _localServer!.all_departments = user['all_departments'];
        _localServer!.departments_ids = user['departments_ids'];
      });

      await _dbHelper!.upsertServer(_localServer!, "id=?", [_localServer!.id]);

      // fetch departments
      List<Department> listDepts =
          await _serverRequest!.getUserDepartments(_localServer!);

      if (listDepts.isNotEmpty) {
        setState(() {
          userDepartments = listDepts;
          if (userDepartments.isNotEmpty) {
            _department = userDepartments.elementAt(0);
            _checkActiveHours();
          }
        });
      }
    }
  }

  void _checkActiveHours() {
    setState(() {
      _onlineHoursActive = _department!.online_hours_active!;
    });
  }

  void _onDeptListChanged(Department? dept) {
    setState(() => _department = dept);
    _checkActiveHours();
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
        context: context, initialTime: new TimeOfDay.now());
    return picked ?? null;
  }
}
