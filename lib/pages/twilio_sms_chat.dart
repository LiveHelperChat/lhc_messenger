import 'dart:async';

import 'package:flutter/material.dart';

import 'package:async_loader/async_loader.dart';
import 'package:flutter/services.dart';
import 'package:livehelp/model/TwilioPhone.dart';

import 'package:livehelp/model/server.dart';
import 'package:livehelp/utils/server_requests.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/utils/routes.dart';

const TIMEOUT = const Duration(seconds: 5);

class TwilioSMSChat extends StatefulWidget {
  TwilioSMSChat({Key key, this.server, this.refreshList}) : super(key: key);

  Server server;

  VoidCallback refreshList;

  @override
  State<StatefulWidget> createState() {
    return new TwilioSMSChatState();
  }
}

class TwilioSMSChatState extends State<TwilioSMSChat> {

  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollViewKey = GlobalKey<ScaffoldState>();

  static final TextEditingController _phoneNumberController =
   TextEditingController();
  static final TextEditingController _messageController =
   TextEditingController();


  Server _currentServer;
  TwilioPhone _selectedPhone;

  List<TwilioPhone> twilioPhonesList = new List<TwilioPhone>();
  DatabaseHelper dbHelper;
  final GlobalKey<AsyncLoaderState> _asyncLoaderState =
  new GlobalKey<AsyncLoaderState>();

  ServerRequest _serverRequest = new ServerRequest();

  bool _isLoading = false;
  bool _checkBoxCreateChat = true;


  @override
  initState() {
    super.initState();
    dbHelper = new DatabaseHelper();
    _currentServer = widget.server;
    _getTwilioPhones();
  }

  @override
  Widget build(BuildContext context) {

    var sendBtn = new Container(
        padding: const EdgeInsets.only(top: 8.0),
        child: new RaisedButton(
          onPressed: () {
            _submit();
          },
          child: new Text("Send Twilio SMS",style: new TextStyle(color: Colors.white),),
          color: Theme.of(context).primaryColor,
        ));
    var messageForm = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
               Text("Twilio Phone Number: "),
              DropdownButton(
                  isExpanded: true,
                  value: _selectedPhone?.id,
                  items: twilioPhonesList.map((phone) {
                    return new DropdownMenuItem(
                      value: phone.id,
                      child:  Text('${phone.base_phone}${phone.phone}'),
                    );
                  }).toList(),
                  onChanged: (fone){
                    setState(() {
                      _selectedPhone = fone;
                    });
                  }),

              new TextFormField(
                  controller: _phoneNumberController,
                  //      onSaved: (val) => _server_name = val,
                  decoration: const InputDecoration(
                      hintText: 'Recipient number',
                      labelText: 'Recipient number *'),
                  keyboardType: TextInputType.numberWithOptions(),
                  //  onSaved: (String value) { person.name = value; },
                  validator: (value){
                    if(value.isEmpty){
                      return 'Recipient Phone number is required';
                    }
                    return null;
                  },
              ),
              new TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Enter Msg',
                  labelText: 'Message *',
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                enableInteractiveSelection: true,
                //   onSaved: (val) => _server_url = val,
                validator:(value){
                  if(value.isEmpty){
                    return 'Message cannot be empty';
                  }
                  return null;
                } ,
              ),
              new Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                     Text('Create SMS Chat'),
                     Checkbox(
                        value: _checkBoxCreateChat,
                        onChanged: (bool value) {
                          onCheckBoxChanged(value);
                        }),
                  ]),
            ],
          ),
        ),
        _isLoading ? new CircularProgressIndicator() : sendBtn,
        new Container(
          padding: const EdgeInsets.only(top: 8.0),
          child: new Text('* indicates required field',
              style: Theme.of(context).textTheme.caption),
        ),
      ],
    );

    var scaffoldSMSForm = new Scaffold(
      appBar:new AppBar(title: new Text("Twilio SMS"),centerTitle: true,) ,
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
    key: _scrollViewKey,
    scrollDirection: Axis.vertical,
    child:   Container(
      child:Container(
          padding: EdgeInsets.only(left: 16.0, right: 16.0),
          decoration: new BoxDecoration(
              color: Colors.white
          ),
          child:messageForm
      ),
          )
        ) ,
      ),
    );

    return scaffoldSMSForm;
  }

  void _submit() async {

    try{

      final form = _formKey.currentState;
      if (form.validate()) {
        setState(() => _isLoading = true);
        form.save();
        _createSMS();

      }

    }
    catch(ex){
      setState(() => _isLoading = false);
    }

  }

  _resetControllers(){
   // _phoneNumberController.text = "";
    _messageController.text = "";
  }

  void _initServer(){
      setState(() {
        _resetControllers();
      });

  }


  Future<Null> _createSMS() async {
    Map<String, dynamic> params = Map<String, dynamic>();

    params.addAll({"twilio_id":_selectedPhone.id,"phone_number": _phoneNumberController.text,
      "create_chat": _checkBoxCreateChat,"msg": _messageController.text});

      try {
        var resp = await _serverRequest.apiPost(_currentServer, "/restapi/twilio_create_sms", params);
      setState(() => _isLoading = false);
      if(resp.statusCode == 200) {
        _showSnackBar("Message sent!.");
        if (_checkBoxCreateChat){
          widget.refreshList();
          Navigator.of(context).pop();
        } else { _resetControllers();
        }
      }
      else {_showSnackBar("Error: Message might not have been sent!"); }
      } catch (e) {
        _showSnackBar("Could not send message.");
        return;
      }
    }


  void _showSnackBar(String text) {
    _scaffoldKey.currentState
        .showSnackBar( SnackBar(content: Text(text)));
  }

  void onCheckBoxChanged(bool value) {
    setState(() {
      _checkBoxCreateChat = value;
    });
  }

  void _getTwilioPhones() async {
    setState(() => _isLoading = true);
    twilioPhonesList?.clear();
    print("SERver: "+_currentServer.toMap().toString());
    var phones = await _serverRequest.getTwilioPhones(_currentServer);
    setState(() => _isLoading = false);
    if (phones != null && phones.length > 0) {
      phones.forEach((item) {
        setState(() {
          twilioPhonesList.add( item);
          _selectedPhone = twilioPhonesList.elementAt(0);
        });
      });
    } else {
      _ackAlert(context);
    }
    }
  }


  void _showAlertMsg(String title,String msg, BuildContext context) {
    SimpleDialog dialog = SimpleDialog(
      title:  Text(title,
        style:  TextStyle(fontSize: 14.0),
      ),
      children: <Widget>[
        new Text(msg,
          style:  TextStyle(fontSize: 14.0),
        )
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog );
  }

  Future<void> _ackAlert(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Twilio Phone'),
          content: const Text('Please configure a Phone number in Twilio extension.'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
}
