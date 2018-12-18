import 'package:flutter/material.dart';

import 'package:livehelp/data/database.dart';

import 'dart:async';
// Inherited widget for managing a token
// TOken inheritedWidget is used to pass token around
// the application
class TokenInheritedWidget extends InheritedWidget {
  const TokenInheritedWidget({
    Key key,
    this.token,
    Widget child}) : super(key: key, child: child);

  final String token;

  @override
  bool updateShouldNotify(TokenInheritedWidget old) {
    // print('In updateShouldNotify');

    return token != old.token;
  }


  static TokenInheritedWidget of(BuildContext context) {
    // You could also just directly return the name here
    // as there's only one field
    return context.inheritFromWidgetOfExactType(TokenInheritedWidget);
  }



}
