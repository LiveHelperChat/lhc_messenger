import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/TwilioPhone.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/department.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';

/// A class similar to http.Response but instead of a String describing the body
/// it already contains the parsed Dart-Object
class ParsedResponse<T> {
  ParsedResponse(this.statusCode, this.body);
  final int statusCode;
  final T body;

  bool isOk() {
    return statusCode >= 200 && statusCode < 300;
  }
}

final int NO_INTERNET = 404;

class ServerRequest {
  DatabaseHelper dbHelper;
  http.Client _client;

  ServerRequest() {
    dbHelper = new DatabaseHelper();
    _client = new http.Client();
  }

  dispose() async {
    _client.close();
  }

  String _encodeCredentials(Server server) {
    String credentials = "${server.username}:${server.password}";
    return base64.encode(utf8.encode(credentials));
  }

  Future<ParsedResponse> apiGet(Server server, String path) async {
    String auth = _encodeCredentials(server);
    final response = await http.get(
      server.getUrl() + path,
      headers: {HttpHeaders.authorizationHeader: "Basic $auth"},
    ).catchError((resp) {
      return new ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"true","msg":${resp.toString()}'));
    });
    try {
      var respBody = {};
      if (response.body != null && response.body.length > 0) {
        respBody = jsonDecode(response.body);
      }
      return ParsedResponse(response.statusCode, respBody);
    } catch (ex) {
      return ParsedResponse(response.statusCode, ex.toString());
    }
  }

  Future<ParsedResponse> apiPost(
      Server server, String path, Map<String, dynamic> params) async {
    String auth = _encodeCredentials(server);

    try {
      final response = await http.post(
        server.getUrl() + path,
        headers: {HttpHeaders.authorizationHeader: "Basic $auth"},
        body: jsonEncode(params),
      );
      var respBody = {};
      if (response.body != null && response.body.length > 0) {
        respBody = jsonDecode(response.body);
      }

      return new ParsedResponse(response.statusCode, respBody);
    } catch (ex) {
      return ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"true","msg":${ex.toString()}'));
    }
  }

  Future<ParsedResponse> _makeRequest(Server server, String path, Map jsonParams, {bool asJson = false, method = 'post'}) async {
    Map parameters = {};
    parameters['username'] = server.username;
    parameters['password'] = server.password;

    if (jsonParams != null) parameters.addAll(jsonParams);
    //http request, catching error like no internet connection.
    //If no internet is available for example
    String url = "${server.getUrl()}$path";

    try {

      var response;

      if (server.username.isNotEmpty && server.password.isNotEmpty) {

        Map<String,String> headers = {
          'authorization' : 'Basic ' + base64Encode(utf8.encode(server.username + ":" + server.password))
        };

        if (asJson == true) {
            headers['Content-type'] = 'application/json';
            headers['Accept'] = 'application/json';
        }

        if (method == 'post') {
          response = await _client.post(url, body: (asJson ? jsonEncode(parameters) : parameters), headers: headers);
        } else if (method == 'put') {
          response = await _client.put(url, body: (asJson ? jsonEncode(parameters) : parameters), headers: headers);
        }

      } else {
        Map<String,String> headers = {};

        if (asJson == true) {
          headers['Content-type'] = 'application/json';
          headers['Accept'] = 'application/json';
        }

        if (method == 'post') {
          response = await _client.post(url, body: (asJson ? jsonEncode(parameters) : parameters), headers: headers);
        } else if (method == 'put') {
          response = await _client.put(url, body: (asJson ? jsonEncode(parameters) : parameters), headers: headers);
        }
      }

      if (response == null) {
        return ParsedResponse(200, jsonDecode('{"error":"true"}'));
      }
      //If there was an error return an empty list
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ParsedResponse(
            response.statusCode, jsonDecode('{"error":"true"}'));
      }
      var respBody = {};
      if (response.body != null && response.body.length > 0) {
        respBody = jsonDecode(response.body);
      }

      return ParsedResponse(response.statusCode, respBody);
    } on FormatException catch (fx) {
      // Workaround for unknown error when deleting closing or deleting chat.
      return ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"false","msg": "Unknown Error" }'));
    } on SocketException catch (fx) {
      // Workaround for unknown error when deleting closing or deleting chat.
      return ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"false","msg": "Socket exception" }'));
    } catch (ex) {
      String msg = "";
      msg = ex != null ? ex : "Request could not be sent.";
      return ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"true","msg": $msg }'));
    }
  }

  // Check whether twilio extension is enabled
  Future<bool> isExtensionInstalled(Server serv, String extension) async {
    var resp = await apiGet(serv, "/restapi/extensions");
    if (resp.isOk()) {
      var response = resp.body;
      if (response['error'] == false) {
        return response['result'].toList().contains(extension);
      }
    }
    return false;
  }

  Future<List<TwilioPhone>> getTwilioPhones(Server server) async {
    var resp = await apiGet(server, "/restapi/twilio_phones");
    List<TwilioPhone> phonesList = List<TwilioPhone>();
    if (resp.isOk()) {
      var response = resp.body;
      if (response['error'] == false) {
        var phones = response['result'].toList();
        if (phones.length > 0) {
          phones.forEach((fone) {
            phonesList.add(TwilioPhone.fromMap(fone));
          });
        }
      }
    }
    return phonesList;
  }

  Future<Server> getTwilioChats(Server server) async {
    // check for twilio extention
    var twilExt = await isExtensionInstalled(server, "twilio");

    if (twilExt) {
      String params = "twilio_sms_chat=true&prefill_fields=phone";
      var resp = await apiGet(server, "/restapi/chats?" + params);
      if (resp.isOk()) {
        var response = resp.body;
        if (response['error'] == false) {
          var listCount = int.parse(response['list_count'].toString());
          if (listCount > 0) {
            var chats = response['list'].toList();
            /* chats.forEach((chat){
              chatList.add(Chat.fromMap(chat));
            });
            */
            List<dynamic> newTwilioList = _chatListToMap(server.id, chats);
            if (newTwilioList != null && newTwilioList.length > 0)
              server.addChatsToList(newTwilioList, 'twilio');
          } else
            server.clearList("twilio");
        }
      }
    }

    return server;
  }

  Future<Server> login(Server server) async {
    var response = await _makeRequest(server, "/xml/checklogin", null);

    if (response.isOk() && response.body["result"].toString() == "true") {
      server.isloggedin = Server.LOGGED_IN;
      return server;
    } else {
      server.isloggedin = Server.LOGGED_OUT;
      return server;
    }
  }

  Future<Server> fetchInstallationId(Server server, String token, String action) async {
    Map param = {};
    param["action"] = action;
    param["generate_token"] = "true";
    param["device"] = "android";
    param["username"] = server.username;
    param["password"] = server.password;

    if (token.isNotEmpty) param["device_token"] = token;

    if (action == 'logout') {
        param["token"] = server.installationid;
    }

    var response = await _makeRequest(server, "/restapi/" + (action == 'add' ? 'login' : 'logout'), param);

    if (response.isOk() && response.body["error"].toString() == "false") {
        server.installationid = response.body["session_token"].toString();
    }

    return server;
  }

  Future<String> fetchVersionExt(Server server) async {
    Map param = {};
    param["regId"] = server.installationid;
    var response = await _makeRequest(server, "/restapi/login", param);

    String resp;
    if (response.isOk() && response.body["error"].toString() == "false") {
      resp = response.body["version"].toString();
    }
    return resp;
  }

  // returns a list of chats as maps
  List<dynamic> _chatListToMap(int server_id, List jsonList) {
    // dynamically pick the fields from the json returned
    // matching the database columns
    var listToStore = new List<Map<dynamic, dynamic>>();
    jsonList.forEach((k) {
      // Add Server id to chat
      k["${Chat.columns['db_serverid']}"] = server_id;

      Map<String, dynamic> chatsToStore = {};
      // print(k);
      Chat.columns.values.forEach((val) {
        chatsToStore[val] = k[val];
      });
      listToStore.add(chatsToStore);
    });
    return listToStore;
  }

  // fetch list and return a formatted Map of active,pending,... chat lists
  Future<Server> getChatLists(Server server) async {
    ParsedResponse response = await _makeRequest(server, "/xml/lists", null);

    if (response.isOk()) {
      int activeSize = response.body['active_chats']['size'];
      if (activeSize > 0) {
        // activeList = Map.castFrom(activeJson).values.toList();
        Map activeJson = response.body['active_chats']['rows'];
        List<dynamic> newActiveList =
            _chatListToMap(server.id, activeJson.values.toList());
        if (newActiveList != null && newActiveList.length > 0)
          server.addChatsToList(newActiveList, 'active');

        //  await dbHelper.bulkInsertChats(
        //     server, _chatListToMap(server.id, activeJson.values.toList()));
      } else
        server.clearList('active');

      int pendingSize = response.body['pending_chats']['size'];
      if (pendingSize > 0) {
        Map pendingJson = response.body['pending_chats']['rows'];
        List<dynamic> newPendingList =
            _chatListToMap(server.id, pendingJson.values.toList());
        if (newPendingList != null && newPendingList.length > 0)
          server.addChatsToList(newPendingList, 'pending');
      } else
        server.clearList('pending');

      int transferSize = response.body['transfered_chats']['size'];
      if (transferSize > 0) {
        List<dynamic> transferredList =
            response.body['transfered_chats']['rows'];

        List<dynamic> newTransferList =
            _chatListToMap(server.id, transferredList);
        if (newTransferList != null && newTransferList.length > 0)
          server.addChatsToList(newTransferList, 'transfer');
      } else
        server.clearList('transfer');

      //close database
    }
    return server;
  }

  Future<bool> postMesssage(Server server, Chat chat, String msg) async {
    Map params = {};
    params["msg"] = msg;
    ParsedResponse response =
        await _makeRequest(server, "/xml/addmsgadmin/${chat.id}", params);

    //print(response.body.toString());
    return response.isOk() ? true : false;
  }

  Future<bool> closeChat(Server server, Chat chat) async {
    String path = "/xml/closechat/${chat.id}";
    ParsedResponse response = await _makeRequest(server, path, null);
    if (response.body["error"] == "true") // no error
      return false;
    else
      return true;
  }

  Future<bool> deleteChat(Server server, Chat chat, {list : "active"}) async {
    ParsedResponse response =
        await _makeRequest(server, "/xml/deletechat/${chat.id}", null);

    if (response.isOk()) server.removeChat(chat.id, list);

    return response.isOk() ? true : false;
  }

  Future<Map<String, dynamic>> syncMessages(
      Server server, Chat chat, int last_msg_id) async {
    Map params = {};
    params["chats"] = last_msg_id == 0
        ? chat.id.toString()
        : chat.id.toString() + '|' + last_msg_id.toString();
    ParsedResponse response =
        await _makeRequest(server, "/xml/chatssynchro", params);

    Map<String, dynamic> messagesChatStatus = new Map<String, dynamic>();
    List<Message> listToMsgs = new List<Message>();

    //print("RESPONSE BODY. "+response.body.toString());

    if (response.isOk() && response.body["error"].toString() == "false") {
      Map results = {};
      results.addAll(response.body["result"]);
      Map level1 = results['${chat.id}'];

      messagesChatStatus['chat_status'] = level1["chat_status"].toString();

      if (level1['messages'] is Map) {
        Map msgs = level1['messages'];

        List msgsList = last_msg_id == 0 ? msgs[""] : msgs["$last_msg_id"];

        if (msgsList.length > 0) {
          msgsList.forEach((value) {
            listToMsgs.add(new Message.fromMap(value));
          });

          messagesChatStatus['messages'] = listToMsgs;
        }
      }
    }
    return messagesChatStatus;
  }

  Future<Map<String, dynamic>> chatData(Server server, Chat chat) async {
    ParsedResponse response =
        await _makeRequest(server, "/xml/chatdata/${chat.id}", null);

    Map<String, dynamic> chatData;

    if (response.isOk() && response.body["error"].toString() == "false") {
      chatData = Map.castFrom(response.body);
    }

    //   print(chatData.toString());
    return chatData;
  }

  Future<Map<String, dynamic>> getUserFromServer(Server server) async {

    Map param = {};
    param["by_login"] = "1";

    var response = await _makeRequest(server, "/restapi/getuser", param);

    Map<String, dynamic> user;
    if (response.isOk() && response.body["error"].toString() == "false") {
      user = Map.castFrom(response.body['result']);
    }
    return user;
  }

  Future<List<Department>> getUserDepartments(Server server) async {
    Map params = {};
    params['user_depids'] = json.encode({
      "all_departments": server.all_departments,
      "dep_ids": [server.departments_ids]
    });
    ParsedResponse response =
        await _makeRequest(server, "/restapi/user_departments", params);

    List<Department> departments = new List<Department>();

    if (response.isOk() && response.body["error"].toString() == "false") {
      // print("Departments: "+response.body.toString());
      if (response.body['result'] != null) {
        List<dynamic> dept = response.body['result'];
        dept.forEach((map) {
          departments.add(new Department.fromMap(map));
        });
      }
    }

    //   print(chatData.toString());
    return departments;
  }

  Future<Map<String, dynamic>> setDepartmentWorkHours(
      Server server, Department department) async {
    Map params = {};
    var postData = department.toMapWorkHours();
    params['post_body'] = json.encode(postData);
    params['request_method'] = 'PUT';
    params['raw_attr'] = '1';

    var response = await _makeRequest(server, "/restapi/department/" + postData['id'].toString(), params);
    Map<String, dynamic> chatData = {};
    if (response.isOk() && response.body["error"].toString() == "false") {
      chatData = Map.castFrom(response.body);
    }

    //   print(chatData.toString());
    return chatData;
  }

  Future<bool> setOperatorTyping(
      Server server, int chatid, bool istyping) async {

    Map params = {
      "operator_typing" : istyping ? ((new DateTime.now().millisecondsSinceEpoch)/1000).round() : 0,
      "operator_typing_id" : istyping ? server.userid : 0
    };

    var response = await _makeRequest(server, "/restapi/chat/" + chatid.toString(), params, asJson : true, method : 'put');
    if (response.isOk())
      return true;
    else
      return false;
  }

  Future<List<dynamic>> getOperatorsList(Server server) async {
    var response = await _makeRequest(server, "/xml/transferchat", null);

    List<dynamic> operatorList = [];
    if (response.isOk() && response.body["result"] is List) {
      List<dynamic> llist = response.body["result"];
      llist.forEach((map) {
        // print("operator: "+map.toString());
        operatorList.add(map);
      });
    }
    return operatorList;
  }

  Future<bool> transferChatUser(Server server, Chat chat, int userid) async {
    ParsedResponse response = await _makeRequest(
        server, "/xml/transferuser/${chat.id}/$userid", null);

    return response.isOk() ? true : false;
  }

  Future<bool> acceptChatTransfer(Server server, Chat chat) async {
    ParsedResponse response = await _makeRequest(
        server, "/xml/accepttransferbychat/${chat.id}", null);

    return response.isOk() ? true : false;
  }

  Future<bool> getUserOnlineStatus(Server server) async {
    ParsedResponse response =
        await _makeRequest(server, "/xml/getuseronlinestatus", null);

    if (response.isOk() && response.body != null && response.body.isNotEmpty) {
      /*
        the logic is inverted. if it returns true, user is offline, false means user is online
       */

      if (response.body["online"].toString() == "true") {
        // user is offline

        return false;
      } else if (response.body["online"].toString() == "false") {
        return true;
      } else
        return false;
    } else
      return false;
  }

  Future<bool> setUserOnlineStatus(Server server) async {
    var status = "0";
    await getUserOnlineStatus(server).then((isOnline) {
      status = isOnline ? "1" : "0";
    });

    var response =
        await _makeRequest(server, "/xml/setonlinestatus/" + status, null);
    // status 1 or 0
    return await getUserOnlineStatus(server);
  }
}
