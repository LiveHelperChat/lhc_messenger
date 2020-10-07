import 'dart:async';
import 'package:flutter/material.dart';

import 'package:async_loader/async_loader.dart';
import 'package:http/http.dart' as http;

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';
import 'package:livehelp/utils/widget_utils.dart';
import 'package:livehelp/widget/office_time_picker.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';

class DepartmentHours extends StatefulWidget {
  DepartmentHours({this.server});
  final Server server;
  @override
  _DepartmentHoursState createState() => new _DepartmentHoursState();
}

class _DepartmentHoursState extends State<DepartmentHours> {
  DatabaseHelper _dbHelper;
  ServerApiClient _serverRequest;

  Server _localServer;
  List<Server> listServers = new List<Server>();
  List<Department> userDepartments = new List<Department>();
  Department _department;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AsyncLoaderState> _asyncLoaderState =
      new GlobalKey<AsyncLoaderState>();

  bool _onlineHoursActive = false;
  bool _sundayHoursActive = false;
  bool _mondayHoursActive = false;
  bool _tuesdayHoursActive = false;
  bool _wednesdayHoursActive = false;
  bool _thursdayHoursActive = false;
  bool _fridayHoursActive = false;
  bool _saturdayHoursActive = false;

  bool _isLoading = false;

  ValueChanged<TimeOfDay> selectTime;

  TimeOfDay selectedTime;

  String _fcmToken;

  @override
  void initState() {
    super.initState();
    _dbHelper = new DatabaseHelper();
    _serverRequest = new ServerApiClient(httpClient: http.Client());
    _localServer = widget.server;

    _syncServerData();
  }

  @override
  Widget build(BuildContext context) {
    final tokenInherited = TokenInheritedWidget.of(context);
    _fcmToken = tokenInherited?.token;
    // print('$_fcmToken');

    Widget loadingIndicator =
        _isLoading ? new CircularProgressIndicator() : new Container();
    var scaff = new Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        appBar: new AppBar(
          title:
              new Text(widget.server.servername), // new Text("Server Details"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
            /* new Offstage(
                offstage:_isLoading,
                child: new IconButton(
                    icon: new CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      ),onPressed: null,)),  */

            FlatButton(
                shape:
                    CircleBorder(side: BorderSide(color: Colors.transparent)),
                textColor: Colors.white,
                child: new Text("Refresh"),
                onPressed: () {
                  _initAsyncloader();
                }),
          ],
        ),
        body: new Stack(children: <Widget>[
          Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: ListTile(
                  title: Text(
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
                child: new ListTile(
                  trailing: new Offstage(
                    offstage: _department == null,
                    child: new Checkbox(
                        value: _onlineHoursActive,
                        onChanged: (val) {
                          setState(() {
                            _onlineHoursActive = val;
                          });
                        }),
                  ),
                  title: _department == null
                      ? new Text(
                          "Could not load department hours from server.\nCheck your network connection. ",
                          style: new TextStyle(
                              fontSize: 14.0, fontWeight: FontWeight.bold),
                        )
                      : DropdownButton(
                          isExpanded: true,
                          value: _department,
                          items: userDepartments.map((dept) {
                            return new DropdownMenuItem(
                              value: dept,
                              child: new Text('${dept?.name}'),
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
                          child: new ListTile(
                              title: new Text('Sunday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked:
                                      _sundayHoursActive || _department != null
                                          ? _department.sundayActive
                                          : false,
                                  startTime: _department?.sud_start_hour,
                                  endTime: _department?.sud_end_hour,
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
                              trailing: new Checkbox(
                                value: _sundayHoursActive || _department != null
                                    ? _department.sundayActive
                                    : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.sud_start_hour = "-1";
                                      _department.sud_end_hour = "-1";
                                    });
                                  } else {
                                    _department.sud_start_hour = "00";
                                    _department.sud_end_hour = "00";
                                  }
                                  setState(() {
                                    _mondayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        new Offstage(
                          offstage: !_onlineHoursActive,
                          child: new ListTile(
                              title: new Text('Monday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked:
                                      _mondayHoursActive || _department != null
                                          ? _department.mondayActive
                                          : false,
                                  startTime: _department?.mod_start_hour,
                                  endTime: _department?.mod_end_hour,
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
                                    ? _department.mondayActive
                                    : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.mod_start_hour = "-1";
                                      _department.mod_end_hour = "-1";
                                    });
                                  } else {
                                    _department.mod_start_hour = "00";
                                    _department.mod_end_hour = "00";
                                  }
                                  setState(() {
                                    _mondayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        new Offstage(
                          offstage: !_onlineHoursActive,
                          child: new ListTile(
                              title: new Text('Tuesday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked:
                                      _tuesdayHoursActive || _department != null
                                          ? _department.tuesdayActive
                                          : false,
                                  startTime: _department?.tud_start_hour,
                                  endTime: _department?.tud_end_hour,
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
                                        ? _department.tuesdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.tud_start_hour = "-1";
                                      _department.tud_end_hour = "-1";
                                    });
                                  } else {
                                    _department.tud_start_hour = "00";
                                    _department.tud_end_hour = "00";
                                  }
                                  setState(() {
                                    _tuesdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        new Offstage(
                          offstage: !_onlineHoursActive,
                          child: new ListTile(
                              title: new Text('Wednesday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked: _wednesdayHoursActive ||
                                          _department != null
                                      ? _department.wednesdayActive
                                      : false,
                                  startTime: _department?.wed_start_hour,
                                  endTime: _department?.wed_end_hour,
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
                                        ? _department.wednesdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.wed_start_hour = "-1";
                                      _department.wed_end_hour = "-1";
                                    });
                                  } else {
                                    _department.wed_start_hour = "00";
                                    _department.wed_end_hour = "00";
                                  }
                                  setState(() {
                                    _wednesdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        new Offstage(
                          offstage: !_onlineHoursActive,
                          child: new ListTile(
                              title: new Text('Thursday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked: _thursdayHoursActive ||
                                          _department != null
                                      ? _department.thursdayActive
                                      : false,
                                  startTime: _department?.thd_start_hour,
                                  endTime: _department?.thd_end_hour,
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
                                        ? _department.thursdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.thd_start_hour = "-1";
                                      _department.thd_end_hour = "-1";
                                    });
                                  } else {
                                    _department.thd_start_hour = "00";
                                    _department.thd_end_hour = "00";
                                  }
                                  setState(() {
                                    _thursdayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        new Offstage(
                          offstage: !_onlineHoursActive,
                          child: new ListTile(
                              title: new Text('Friday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked:
                                      _fridayHoursActive || _department != null
                                          ? _department.fridayActive
                                          : false,
                                  startTime: _department?.frd_start_hour,
                                  endTime: _department?.frd_end_hour,
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
                              trailing: new Checkbox(
                                value: _fridayHoursActive || _department != null
                                    ? _department.fridayActive
                                    : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.frd_start_hour = "-1";
                                      _department.frd_end_hour = "-1";
                                    });
                                  } else {
                                    _department.frd_start_hour = "00";
                                    _department.frd_end_hour = "00";
                                  }
                                  setState(() {
                                    _fridayHoursActive = val;
                                  });
                                },
                              )),
                        ),
                        new Offstage(
                          offstage: !_onlineHoursActive,
                          child: new ListTile(
                              title: new Text('Saturday'),
                              subtitle: new OfficeTimePicker(
                                  isChecked: _saturdayHoursActive ||
                                          _department != null
                                      ? _department.saturdayActive
                                      : false,
                                  startTime: _department?.sad_start_hour,
                                  endTime: _department?.sad_end_hour,
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
                                        ? _department.saturdayActive
                                        : false,
                                onChanged: (val) {
                                  if (!val) {
                                    setState(() {
                                      _department.sad_start_hour = "-1";
                                      _department.sad_end_hour = "-1";
                                    });
                                  } else {
                                    _department.sad_start_hour = "00";
                                    _department.sad_end_hour = "00";
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
              RaisedButton(
                onPressed: () {
                  _department.online_hours_active = _onlineHoursActive;
                  _isLoading = true;
                  _serverRequest
                      .setDepartmentWorkHours(_localServer, _department)
                      .then((value) {
                    if (value['error'] == false) {
                      WidgetUtils.creatDialog(
                          context, "Working hours saved successfully.");
                    }
                    _isLoading = false;
                  });
                },
                child: new Text(
                  "Save Data",
                  style: new TextStyle(color: Colors.white),
                ),
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
          new Center(child: loadingIndicator),
        ]));

    var _asyncLoader = new AsyncLoader(
      key: _asyncLoaderState,
      initState: () async => await _initAsyncloader(),
      renderLoad: () => new Scaffold(
        body: new Center(child: new CircularProgressIndicator()),
      ),
      renderError: ([error]) => new Scaffold(
        body: new Center(
          child: new Text('Something is wrong'),
        ),
      ),
      renderSuccess: ({data}) {
        return scaff;
      },
    );

    return _asyncLoader;
  }

  Future<Null> _initAsyncloader() async {
    _isLoading = true;
    //  await _fetchServerDetails();
    await _syncServerData();
    _isLoading = false;
  }

  Future<Null> _syncServerData() async {
    if (_localServer != null) {
      var user = await _serverRequest.getUserFromServer(_localServer);

      if (user != null) {
        setState(() {
          _localServer.userid = user['id'];
          _localServer.firstname = user['name'];
          _localServer.surname = user['surname'];
          _localServer.operatoremail = user['email'];
          _localServer.job_title = user['job_title'];
          _localServer.all_departments = user['all_departments'];
          _localServer.departments_ids = user['departments_ids'];
        });
      }

      await _dbHelper.upsertServer(_localServer, "id=?", [_localServer.id]);

      // fetch departments
      List<Department> listDepts =
          await _serverRequest.getUserDepartments(_localServer);

      if (listDepts is List) {
        setState(() {
          userDepartments = listDepts;
          if (userDepartments.length > 0) {
            _department = userDepartments.elementAt(0);
            _checkActiveHours();
          }
        });
      }
    }
  }

  void _checkActiveHours() {
    setState(() {
      _onlineHoursActive = _department.online_hours_active;
    });
  }

  _onDeptListChanged(Department dept) {
    setState(() => _department = dept);
    _checkActiveHours();
  }

  Future<TimeOfDay> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
        context: context, initialTime: new TimeOfDay.now());
    return picked ?? 00;
  }

  void _refreshServerData() {
    _serverRequest
        .fetchInstallationId(_localServer, _fcmToken, "")
        .then((server) {
      _localServer = server;
      _dbHelper.upsertServer(_localServer, "${Server.columns['db_id']} = ?",
          ['${_localServer.id}']);
      setState(() {
        _isLoading = false;
      });
    });
  }
}
