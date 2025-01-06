import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_repository.dart';

class TwilioSMSChat extends StatefulWidget {
  TwilioSMSChat({Key? key, this.server, this.refreshList}) : super(key: key);

  final Server? server;

  final VoidCallback? refreshList;

  @override
  State<StatefulWidget> createState() => new TwilioSMSChatState();
}

class TwilioSMSChatState extends State<TwilioSMSChat> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollViewKey = GlobalKey<ScaffoldState>();

  static final TextEditingController _phoneNumberController =
      TextEditingController();
  static final TextEditingController _messageController =
      TextEditingController();

  Server? _currentServer;
  TwilioPhone? _selectedPhone;

  List<TwilioPhone> twilioPhonesList = List<TwilioPhone>.empty();
  DatabaseHelper? dbHelper;
  ServerRepository? _serverRepository;

  bool _isLoading = false;
  bool _checkBoxCreateChat = true;

  @override
  initState() {
    super.initState();
    _serverRepository = context.watch<ServerRepository>();
    dbHelper = DatabaseHelper();
    _currentServer = widget.server;
    _getTwilioPhones();
  }

  @override
  Widget build(BuildContext context) {
    var sendBtn = Container(
        padding: const EdgeInsets.only(top: 8.0),
        child: ElevatedButton(
          onPressed: () {
            _submit();
          },
          child: Text(
            "Send Twilio SMS",
            style: new TextStyle(color: Colors.white),
          ),
          // color: Theme.of(context).primaryColor,
        ));
    var messageForm = Column(
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
                    return DropdownMenuItem(
                      value: phone.id,
                      child: Text('${phone.base_phone}${phone.phone}'),
                    );
                  }).toList(),
                  onChanged: (fone) {
                    setState(() {
                      _selectedPhone = fone as TwilioPhone;
                    });
                  }),
              TextFormField(
                controller: _phoneNumberController,
                //      onSaved: (val) => _server_name = val,
                decoration: const InputDecoration(
                    hintText: 'Recipient number',
                    labelText: 'Recipient number *'),
                keyboardType: TextInputType.numberWithOptions(),
                //  onSaved: (String value) { person.name = value; },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Recipient Phone number is required';
                  }
                  return null;
                },
              ),
              TextFormField(
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
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Message cannot be empty';
                  }
                  return null;
                },
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text('Create SMS Chat'),
                    Checkbox(
                        value: _checkBoxCreateChat,
                        onChanged: (bool? value) {
                          onCheckBoxChanged(value);
                        }),
                  ]),
            ],
          ),
        ),
        _isLoading ? new CircularProgressIndicator() : sendBtn,
        Container(
          padding: const EdgeInsets.only(top: 8.0),
          child: new Text('* indicates required field',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );

    var scaffoldSMSForm = Scaffold(
      appBar: AppBar(
        title: Text("Twilio SMS"),
        centerTitle: true,
      ),
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            key: _scrollViewKey,
            scrollDirection: Axis.vertical,
            child: Container(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                decoration: const BoxDecoration(color: Colors.white),
                child: messageForm)),
      ),
    );

    return scaffoldSMSForm;
  }

  void _submit() async {
    try {
      final form = _formKey.currentState;
      if (form!.validate()) {
        setState(() => _isLoading = true);
        form.save();
        _createSMS();
      }
    } catch (ex) {
      setState(() => _isLoading = false);
    }
  }

  _resetControllers() {
    // _phoneNumberController.text = "";
    _messageController.text = "";
  }

  Future<Null> _createSMS() async {
    try {
      var resp = await _serverRepository!.sendTwilioSMS(
          _currentServer!,
          _selectedPhone!,
          _phoneNumberController.text,
          _messageController.text,
          _checkBoxCreateChat);
      setState(() => _isLoading = false);
      if (resp) {
        _showSnackBar("Message sent!.");
        if (_checkBoxCreateChat) {
          widget.refreshList!();
          Navigator.of(context).pop();
        } else {
          _resetControllers();
        }
      } else {
        _showSnackBar("Error: Message might not have been sent!");
      }
    } catch (e) {
      _showSnackBar("Could not send message.");
      return;
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(_scaffoldKey.currentContext!)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  void onCheckBoxChanged(bool? value) {
    setState(() {
      _checkBoxCreateChat = value!;
    });
  }

  void _getTwilioPhones() async {
    setState(() => _isLoading = true);
    twilioPhonesList.clear();
    var phones = await _serverRepository!.getTwilioPhones(_currentServer!);
    setState(() => _isLoading = false);
    if (phones.length > 0) {
      phones.forEach((item) {
        setState(() {
          twilioPhonesList.add(item);
          _selectedPhone = twilioPhonesList.elementAt(0);
        });
      });
    } else {
      _ackAlert(context);
    }
  }
}

Future<void> _ackAlert(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Twilio Phone'),
        content:
            const Text('Please configure a Phone number in Twilio extension.'),
        actions: <Widget>[
          ElevatedButton(
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
