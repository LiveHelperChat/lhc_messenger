import 'dart:async';
import 'package:flutter/material.dart';

import 'package:async_loader/async_loader.dart';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/user.dart';
import 'package:livehelp/model/department.dart';
import 'package:livehelp/utils/server_requests.dart';
import 'package:livehelp/utils/widget_utils.dart';
import 'package:livehelp/widget/office_time_picker.dart';
import 'package:livehelp/pages/token_inherited_widget.dart';
import 'package:livehelp/widget/circularWithBackground.dart';

class ServerDetails extends StatefulWidget {
  ServerDetails({this.server});
  final Server server;
  @override
  _ServerDetailsState createState() => new _ServerDetailsState();
}

class _ServerDetailsState extends State<ServerDetails> {
  DatabaseHelper _dbHelper;
  ServerRequest _serverRequest;

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
    _serverRequest = new ServerRequest();
    _localServer = widget.server;

    /*
    if(widget.server == null)
      ()async=>await  _syncServerData();
    else {

      listServers.add(_localServer);
    }*/
  }

  /*
    new Theme(
      data: Theme.of(context).copyWith(
      canvasColor: Colors.blue.shade400,
      ),
      child: new DropdownButton(
      hint: new Text(
      "Select Server",
      style: new TextStyle(color: Colors.white),
      ),
      value: _localServer,
      items: listServers.map((srver) {
      return new DropdownMenuItem(
      value: srver,
      child: new Text(
      '${srver?.servername}',
      style: new TextStyle(color: Colors.white),
      ),
      );
      }).toList(),
      onChanged: _onServerListChanged), )
   */
  

  @override
  Widget build(BuildContext context) {
    final tokenInherited =TokenInheritedWidget.of(context);
    _fcmToken =tokenInherited?.token;
    // print('$_fcmToken');

    Widget loadingIndicator =_isLoading ?  new CircularProgressIndicator():new Container();
    var scaff = new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title:new Text(widget.server.servername),// new Text("Server Details"),
          elevation:
              Theme.of(context).platform == TargetPlatform.android ? 6.0 : 0.0,
          actions: <Widget>[
           /* new Offstage(
                offstage:_isLoading,
                child: new IconButton(
                    icon: new CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      ),onPressed: null,)),  */
            new Offstage(
              offstage: _department == null,
              child: new MaterialButton(
                  child:  new Text("Save Data"),
                textColor: Colors.white,
                onPressed: () {
                  _department.online_hours_active = _onlineHoursActive;
                  _isLoading = true;
                  _serverRequest
                      .setDepartmentWorkHours(_localServer, _department)
                      .then((value) {
                    if(value['error'] == 'false')
                    { WidgetUtils.creatDialog(context, "Worked hours saved successfully."); }
                    _isLoading = false;
                  });
                }), ),
            new MaterialButton(
                child: new Text("Sync Server"),
                textColor: Colors.white,
                onPressed: () {
                  _isLoading = true;
                  _refreshServerData();
                  _initAsyncloader();
                }),
          ],
        ),
        body:new Stack(
          children:<Widget>[
            new SingleChildScrollView(
          child: new Container(
            margin: EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
        new Card(
                  child: new Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new Padding(
                            padding: EdgeInsets.all(8.0),
                            child: new Text(
                              "SERVER INFO",
                              textAlign: TextAlign.center,
                              style: new TextStyle(fontWeight: FontWeight.bold),
                            )),
                        new Divider(),
                        new ListTile(
                          title: new Text('${_localServer?.url}'),
                        ),
                      ]),
                ),

               new Card(
                  child: new Column(
                  mainAxisSize: MainAxisSize.min,
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new Padding(
                          padding: EdgeInsets.all(8.0),
                          child: new Text(
                            "OPERATOR INFO",
                            textAlign: TextAlign.center,
                            style: new TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        new Divider(),
                        new ListTile(
                          title: new Text(
                              '${_localServer?.firstname} ${_localServer?.surname}'),
                        ),
                        new ListTile(
                          title: new Text('${_localServer?.operatoremail}'),
                        ),
                      ]),
                ),
             new Divider(),

                      new Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        child: new ListTile(
                          leading:new Offstage(
                            offstage: _department == null,
                            child:new Checkbox(
                              value: _onlineHoursActive,
                              onChanged: (val) {
                                setState(() {
                                  _onlineHoursActive = val;
                                });
                              }) ,) ,
                          title: new Text("Department Work hours/day active",
                          style: new TextStyle(fontSize: 12.0),),
                          subtitle:_department ==null ? new Text("Could not load department hours from server.", style: new TextStyle(fontSize: 14.0,fontWeight: FontWeight.bold),)
                              : new Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[

                         new Expanded(
                                child: new DropdownButton(
                                    value: _department,
                                    items: userDepartments.map((dept) {
                                      return new DropdownMenuItem(
                                        value: dept,
                                        child: new Text('Dept: ${dept?.name}'),
                                      );
                                    }).toList(),
                                    onChanged: _onDeptListChanged),
                              )


                            ],
                          ),
                        ) ,
                      ),

                      new Divider(),
                      new Offstage(
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
                              value: _tuesdayHoursActive || _department != null
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
                                isChecked:
                                    _wednesdayHoursActive || _department != null
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
                                isChecked:
                                    _thursdayHoursActive || _department != null
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
                              value: _thursdayHoursActive || _department != null
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
                                isChecked:
                                    _saturdayHoursActive || _department != null
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
                            trailing: new Checkbox(
                              value: _saturdayHoursActive || _department != null
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
            new Center(child: loadingIndicator),
        ]
    )
    );

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
/*
  Future<Null> _fetchServerDetails() async {
    //get server details from db
    await _dbHelper.fetchAll(Server.tableName, null, null, null).then((srvrs) {
      listServers.clear();
      srvrs.forEach((map) {
        listServers.add(new Server.fromMap(map));
      });
      setState(() {
        _localServer = listServers.elementAt(0);
      });
    });
  }  */

  Future<Null> _syncServerData() async {
//    print("Localserver: " + _localServer?.toMap().toString());

    if (_localServer != null) {
      //TODO
      //Get 
    //  await _serverRequest.fetchInstallationId(_localServer, _fcmToken)
    //      .then((srvr)=>_localServer = srvr);
      
      // fetch user data
      await _serverRequest.getUserFromServer(_localServer).then((user) {
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
      });
      await _dbHelper.upsertServer(_localServer, "id=?", [_localServer.id]);

      // fetch departments
      await _serverRequest.getUserDepartments(_localServer).then((list) {
        if (list is List) {
          setState(() {
            userDepartments = list;
            if(userDepartments.length >0) {
              _department = userDepartments.elementAt(0);
              _checkActiveHours();
            }
          });
        }
      });
    }
  }

  void _checkActiveHours() {
    setState(() {
      _onlineHoursActive = _department.online_hours_active;
    });
  }
/*
  _onServerListChanged(Server srvr) {
    setState(() => _localServer = srvr);
    _syncServerData();
  }
*/
  _onDeptListChanged(Department dept) {
    setState(() => _department = dept);
    _checkActiveHours();
  }

  Future<TimeOfDay> _selectTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
        context: context, initialTime: new TimeOfDay.now());
    return picked ?? 00;
  }

  void _refreshServerData()async{
    await _serverRequest.fetchInstallationId(_localServer,_fcmToken,"add")
        .then((server){
        _localServer = server;
      _dbHelper.upsertServer(_localServer,"${Server.columns['db_id']} = ?",
          ['${_localServer.id}']);
      setState(() {
        _isLoading = false;
      });
    }
    );



  }
}
