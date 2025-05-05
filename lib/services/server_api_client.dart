// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:livehelp/model/file_upload_response.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:livehelp/utils/widget_utils.dart';

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

const int NO_INTERNET = 404;

class ServerApiClient {
  final http.Client httpClient;

  ServerApiClient({required this.httpClient});

  String _encodeCredentials(Server server) {
    String credentials = "${server.username}:${server.password}";
    return base64.encode(utf8.encode(credentials));
  }
//old code
  // Future<ParsedResponse> apiGet(Server server, String path) async {
  //   String auth = _encodeCredentials(server);
  //   final response = await http.get(
  //     Uri.parse(server.getUrl().toString() + path),
  //     headers: {HttpHeaders.authorizationHeader: "Basic $auth"},
  //   ).catchError((resp) {
  //     return ParsedResponse(NO_INTERNET,
  //         jsonDecode('{"error":"true","msg":"${resp.toString()}"'));
  //   });
  //   try {
  //     var respBody = {};
  //     if (response.body.isNotEmpty) {
  //       respBody = jsonDecode(response.body);
  //     }
  //     return ParsedResponse(response.statusCode, respBody);
  //   } catch (ex) {
  //     return ParsedResponse(response.statusCode, ex.toString());
  //   }
  // }

//updated code
  Future<ParsedResponse> apiGet(Server server, String path) async {
    String auth = _encodeCredentials(server);
    try {
      final response = await http.get(
        Uri.parse(server.getUrl().toString() + path),
        headers: {HttpHeaders.authorizationHeader: "Basic $auth"},
      );

      var respBody = {};
      if (response.body.isNotEmpty) {
        respBody = jsonDecode(response.body);
      }
      return ParsedResponse(response.statusCode, respBody);
    } catch (error) {
      return ParsedResponse(
          NO_INTERNET, {'error': 'true', 'msg': error.toString()});
    }
  }

  Future<ParsedResponse> apiPost(
      Server server, String path, Map<String, dynamic> params) async {
    String auth = _encodeCredentials(server);

    try {
      final response = await http.post(
        Uri.parse(server.getUrl().toString() + path),
        headers: {HttpHeaders.authorizationHeader: "Basic $auth"},
        body: jsonEncode(params),
      );
      var respBody = {};
      if (response.body.isNotEmpty) {
        respBody = jsonDecode(response.body);
      }

      return ParsedResponse(response.statusCode, respBody);
    } catch (ex) {
      return ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"true","msg":"${ex.toString()}"'));
    }
  }

  //old function
  Future<ParsedResponse> makeRequest(
      Server server, String path, Map? jsonParams,
      {bool asJson = false, method = 'post'}) async {
    Map parameters = {};
    parameters['username'] = server.username;
    parameters['password'] = server.password;

    if (jsonParams != null) parameters.addAll(jsonParams);
    //http request, catching error like no internet connection.
    //If no internet is available for example
    String url = "${server.getUrl()}$path";

    try {
      var response;

      if (server.username!.isNotEmpty && server.password!.isNotEmpty) {
        Map<String, String> headers = {
          'authorization': 'Basic ' +
              base64Encode(
                  utf8.encode(server.username! + ":" + server.password!))
        };

        if (asJson == true) {
          headers['Content-type'] = 'application/json';
          headers['Accept'] = 'application/json';
        }

        if (method == 'post') {
          response = await httpClient.post(Uri.parse(url),
              body: (asJson ? jsonEncode(parameters) : parameters),
              headers: headers);
        } else if (method == 'put') {
          response = await httpClient.put(Uri.parse(url),
              body: (asJson ? jsonEncode(parameters) : parameters),
              headers: headers);
        }
      } else {
        Map<String, String> headers = {};

        if (asJson == true) {
          headers['Content-type'] = 'application/json';
          headers['Accept'] = 'application/json';
        }

        if (method == 'post') {
          response = await httpClient.post(Uri.parse(url),
              body: (asJson ? jsonEncode(parameters) : parameters),
              headers: headers);
        } else if (method == 'put') {
          response = await httpClient.put(Uri.parse(url),
              body: (asJson ? jsonEncode(parameters) : parameters),
              headers: headers);
        }
      }

     /* log(response.body);*/
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
    } on http.ClientException catch (cx) {
      String msg = "Client exception: ${cx.message}";
      return _parseException(msg);
    } on HttpException catch (sx) {
      String msg = "HTTP exception: ${sx.message}";
      return _parseException(msg);
    } on SocketException catch (sx) {
      String msg = "Socket exception: ${sx.message}";
      return _parseException(msg);
    } catch (ex) {
      String msg = "";
      msg = ex != null ? ex.toString() : "Request could not be sent.";
      return ParsedResponse(
          NO_INTERNET, jsonDecode('{"error":"true","msg": "$msg" }'));
    }
  }

  ParsedResponse _parseException(String message) {
    return ParsedResponse(
        NO_INTERNET, jsonDecode('{"error":"true","msg": "$message" }'));
  }

  // fetch list and return a formatted Map of active,pending,... chat lists
  Future<Server> getChatLists(Server server) async {
    log("ok1");
    ParsedResponse response = await makeRequest(server, "/xml/lists", null);
    // print("getChatLists :  ${response.body.isNotEmpty}");

    if (response.isOk() && (response.body.isNotEmpty)) {
      if (response.body['is_online'] != null &&
          server.userOnline != response.body['is_online']) {
        server.userOnline = response.body['is_online'];
      }

      int activeSize = response.body['active_chats']['size'];
      if (activeSize > 0) {
        // activeList = Map.castFrom(activeJson).values.toList();
        Map activeJson = response.body['active_chats']['rows'];
        List<dynamic> newActiveList =
            chatListToMap(server.id!, activeJson.values.toList());
        if (newActiveList.isNotEmpty) {
          server.addChatsToList(newActiveList, 'active');
        }
      } else {
        server.clearList('active');
      }

      if (response.body['twilio_chats'] != null) {
        int twilioSize = response.body['twilio_chats']['size'];
        if (twilioSize > 0) {
          List<dynamic> newTwilioList =
              chatListToMap(server.id!, response.body['twilio_chats']['rows']);
          if (newTwilioList.isNotEmpty) {
            server.addChatsToList(newTwilioList, 'twilio');
          }
        } else {
          server.clearList('twilio');
        }
      }

      int pendingSize = response.body['pending_chats']['size'];
      if (pendingSize > 0) {
        Map pendingJson = response.body['pending_chats']['rows'];
        List<dynamic> newPendingList =
            chatListToMap(server.id!, pendingJson.values.toList());
        if (newPendingList.length > 0)
          server.addChatsToList(newPendingList, 'pending');
      } else {
        server.clearList('pending');
      }

      int closedSize = response.body['closed_chats']['size'];
      if (closedSize > 0) {
        Map closedJson = response.body['closed_chats']['rows'];
        List<dynamic> newClosedList =
            chatListToMap(server.id!, closedJson.values.toList());
        if (newClosedList.isNotEmpty)
          server.addChatsToList(newClosedList, 'closed');
      } else {
        server.clearList('closed');
      }

      if (response.body['bot_chats'] != null) {
        int botSize = response.body['bot_chats']['size'];
        if (botSize > 0) {
          Map botJson = response.body['bot_chats']['rows'];
          List<dynamic> newBotList =
              chatListToMap(server.id!, botJson.values.toList());
          if (newBotList.length > 0) server.addChatsToList(newBotList, 'bot');
        } else
          server.clearList('bot');
      }

      if (response.body['subject_chats'] != null) {
        int subjectSize = response.body['subject_chats']['size'];
        if (subjectSize > 0) {
          Map subjectJson = response.body['subject_chats']['rows'];
          List<dynamic> newSubjectList =
              chatListToMap(server.id!, subjectJson.values.toList());
          if (newSubjectList.length > 0)
            server.addChatsToList(newSubjectList, 'subject');
        } else
          server.clearList('subject');
      }

      if (response.body['operators_chats'] != null) {
        int operatorsSize = response.body['operators_chats']['size'];
        if (operatorsSize > 0) {
          Map operatorsJson = response.body['operators_chats']['rows'];
          List<dynamic> newOperatorsList =
              operatorListToMap(server.id!, operatorsJson.values.toList());
          if (newOperatorsList.length > 0) {
            server.addChatsToList(newOperatorsList, 'operators');
          }
        } else
          server.clearList('operators');
      }

      int transferSize = response.body['transfered_chats']['size'];
      if (transferSize > 0) {
        List<dynamic> transferredList =
            response.body['transfered_chats']['rows'];

        List<dynamic> newTransferList =
            chatListToMap(server.id!, transferredList);
        if (newTransferList.length > 0)
          server.addChatsToList(newTransferList, 'transfer');
      } else
        server.clearList('transfer');
    }
    return server;
  }

  // Check whether extension is enabled
  Future<bool> isExtensionInstalled(Server server, String extension) async {
    var resp = await makeRequest(server, "/restapi/extensions", null);
    if (resp.isOk()) {
      var response = resp.body;
      if (response['error'] == false) {
        return response['result'].toList().contains(extension);
      }
    }
    return false;
  }

  Future<Server> login(Server server) async {
    var response = await makeRequest(server, "/xml/checklogin", null);

    if (response.isOk() && response.body["result"].toString() == "true") {
      server.isLoggedIn = true;
      return server;
    } else {
      server.isLoggedIn = false;
      return server;
    }
  }

  Future<Server> fetchInstallationId(
      Server server, String token, String action) async {
    Map param = {};
    param["action"] = action;
    param["generate_token"] = "true";
    param["device"] = Platform.isAndroid ? "android" : "ios";
    param["username"] = server.username;
    param["password"] = server.password;

    if (token.isNotEmpty) param["device_token"] = token;

    if (action == 'logout') {
      param["token"] = server.installationid;
    }

    var response = await makeRequest(
        server, "/restapi/" + (action == 'add' ? 'login' : 'logout'), param);

    if (response.isOk() && response.body["error"].toString() == "false") {
      server.installationid = response.body["session_token"].toString();
    }

    return server;
  }

  Future<String> fetchVersionExt(Server server) async {
    Map param = {};
    param["regId"] = server.installationid;
    var response = await makeRequest(server, "/restapi/login", param);

    String resp = "";
    if (response.isOk() && response.body["error"].toString() == "false") {
      resp = response.body["version"].toString();
    }
    return resp;
  }

  // returns a list of chats as maps
  List<dynamic> chatListToMap(int serverId, List jsonList) {
    // dynamically pick the fields from the json returned
    // matching the database columns
    var listToStore = <Map<dynamic, dynamic>>[];
    jsonList.forEach((k) {
      // Add Server id to chat
      k["${Chat.columns['db_serverid']}"] = serverId;

      Map<String, dynamic> chatsToStore = {};
      Chat.columns.values.forEach((val) {
        chatsToStore[val] = k[val];
      });
      listToStore.add(chatsToStore);
    });

    return listToStore;
  }

  // returns a list of chats as maps
  List<dynamic> operatorListToMap(int serverId, List jsonList) {
    // dynamically pick the fields from the json returned
    // matching the database columns
    var listToStore = <Map<dynamic, dynamic>>[];
    jsonList.forEach((k) {
      // Add Server id to chat
      k["${Chat.columns['db_serverid']}"] = serverId;

      Map<String, dynamic> chatsToStore = {};
      User.columns.values.forEach((val) {
        chatsToStore[val] = k[val];
      });
      listToStore.add(chatsToStore);
    });

    return listToStore;
  }

  Future<bool> closeChat(Server server, Chat chat) async {
    String path = "/xml/closechat/${chat.id}";
    ParsedResponse response = await makeRequest(server, path, null);
    if (response.body["error"] == "true") // no error
      return false;
    else
      return true;
  }

  Future<bool> closeOperatorsChat(Server server, User chat) async {
    /*String path = "/xml/closechat/${chat.id}";
    ParsedResponse response = await makeRequest(server, path, null);
    if (response.body["error"] == "true") // no error
      return false;
    else
      return true;*/
    return true;
  }

  Future<bool> deleteOperatorsChat(Server server, User chat,
      {list = "active"}) async {
    /*ParsedResponse response =
    await makeRequest(server, "/xml/deletechat/${chat.id}", null);

    if (response.isOk()) server.removeChat(chat.id, list);

    return response.isOk() ? true : false;*/
    return true;
  }

  Future<bool> deleteChat(Server server, Chat chat, {list = "active"}) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/deletechat/${chat.id}", null);

    if (response.isOk()) server.removeChat(chat.id!, list);

    return response.isOk() ? true : false;
  }

  Future<Map<String, dynamic>> getUserFromServer(Server server) async {
    Map param = {};
    param["by_login"] = "1";

    var response = await makeRequest(server, "/restapi/getuser", param);

    print(server.id);
    print("getUserFromServer");
    print(response.isOk());
    print(response.body.toString());

    Map<String, dynamic> user = {};
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
        await makeRequest(server, "/restapi/user_departments", params);

    List<Department> departments = <Department>[];

    if (response.isOk() && response.body["error"].toString() == "false") {
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
      Server server, Department? department) async {
    Map params = {};
    var postData = department != null ? department.toMapWorkHours() : {};
    params['post_body'] = json.encode(postData);
    params['request_method'] = 'PUT';
    params['raw_attr'] = '1';

    var response = await makeRequest(
        server, "/restapi/department/" + postData['id'].toString(), params);
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
      "operator_typing": istyping
          ? ((new DateTime.now().millisecondsSinceEpoch) / 1000).round()
          : 0,
      "operator_typing_id": istyping ? server.userid : 0
    };

    var response = await makeRequest(
        server, "/restapi/chat/" + chatid.toString(), params,
        asJson: true, method: 'put');
    if (response.isOk())
      return true;
    else
      return false;
  }

  Future<List<dynamic>> getOperatorsList(Server server) async {
    var response = await makeRequest(server, "/xml/transferchat", null);

    List<dynamic> operatorList = [];
    if (response.isOk() && response.body["result"] is List) {
      List<dynamic> llist = response.body["result"];
      llist.forEach((map) {
        operatorList.add(map);
      });
    }
    return operatorList;
  }

  Future<bool> transferChatUser(Server server, Chat chat, int userid) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/transferuser/${chat.id}/$userid", null);

    return response.isOk() ? true : false;
  }

  Future<bool> acceptChatTransfer(Server server, Chat chat) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/accepttransferbychat/${chat.id}", null);

    return response.isOk() ? true : false;
  }

  Future<bool> getUserOnlineStatus(Server server) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/getuseronlinestatus", null);

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
    var isOnline = await getUserOnlineStatus(server);
    status = isOnline ? "1" : "0";
    await makeRequest(server, "/xml/setonlinestatus/" + status, null);
    // status 1 or 0
    return await getUserOnlineStatus(server);
  }

  Future<Map<String, dynamic>> syncOperatorsMessages(
      Server server, User chat, int lastMsgId) async {
    Map params = {};

    List<String> listChats = [
      lastMsgId == 0
          ? chat.chat_id.toString() + ',0,0'
          : chat.chat_id.toString() + ',' + lastMsgId.toString() + ',0'
    ];

    params["chats"] = listChats;

    ParsedResponse response = await makeRequest(
        server, "/groupchat/sync?rest_api=true", params,
        asJson: true, method: 'post');

    Map<String, dynamic> messagesChatStatus = <String, dynamic>{};
    List<Message> listToMsgs = <Message>[];

    if (response.isOk() && response.body["error"].toString() == "false") {
      Map results = {};
      if (response.body["result"].length > 0) {
        results.addAll(response.body["result"][0]);

        if (results['content'] is List) {
          results['content'].forEach((value) {
            listToMsgs.add(Message.fromMap(value));
          });
          messagesChatStatus['messages'] = listToMsgs;
        }
      }
    }
    return messagesChatStatus;
  }

  Future<Map<String, dynamic>> syncMessages(
      Server server, Chat chat, int lastMsgId) async {
    Map params = {};
    params["chats"] = lastMsgId == 0
        ? chat.id.toString()
        : chat.id.toString() + '|' + lastMsgId.toString();
    ParsedResponse response =
        await makeRequest(server, "/xml/chatssynchro", params);

    Map<String, dynamic> messagesChatStatus = <String, dynamic>{};
    List<Message> listToMsgs = <Message>[];
    if (response.isOk() && response.body["error"].toString() == "false") {
      Map results = {};
      results.addAll(response.body["result"]);
      Map level1 = results['${chat.id}'];
      messagesChatStatus['chat_status'] = level1["chat_status"].toString();
      messagesChatStatus['chat_scode'] = level1["chat_scode"] ?? 0;

      if (level1['messages'] is Map) {
        Map msgs = level1['messages'];
        List msgsList = lastMsgId == 0 ? msgs[""] : msgs["$lastMsgId"];

        if (msgsList.isNotEmpty) {
          for (var value in msgsList) {
            listToMsgs.add(Message.fromMap(value));
          }

          messagesChatStatus['messages'] = listToMsgs;
        }
      }
    }
    return messagesChatStatus;
  }

//for sending operator message in chat
  Future<bool> postMesssage(Server server, Chat chat, String msg,
      {String? sender}) async {
    try {
      log("chat name:${server.username}");
      Map params = {};
      params["msg"] = msg;
      params["chat_id"] = chat.id.toString();
      params["sender"] = sender ?? "operator"; //to enable whispering messages
      /*
      * We want alias to kick in back office itself
      if (sender == "system" && chat.owner == null ||
          chat.owner != server.username) {
        params["operator_name"] = server.username ?? "System Assistant";
      }
      log("OperatorName: ${params["operator_name"]}");*/
      ParsedResponse response =
          await makeRequest(server, "/restapi/addmsgadmin", params);
      log(response.body.toString());
      return response.isOk() ? true : false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

//for uploading file on server
  Future<FileUploadResponse?> uploadFile(
    Server server,
    File file, {
    String? namePrepend,
    String? nameReplace,
    bool? persistent,
    int? chatId,
  }) async {
    String url = "${server.getUrl()}/restapi/file";
    log("Url is:$url");
    // Create a multipart request
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add username and password to headers if provided
    if (server.username!.isNotEmpty && server.password!.isNotEmpty) {
      request.headers['authorization'] = 'Basic ' +
          base64Encode(utf8.encode('${server.username}:${server.password}'));
    }

    request.files.add(await http.MultipartFile.fromPath(
      'files',
      file.path,
      contentType: FunctionUtils.getMediaType(file.path),
    ));

    try {
      // Send the request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      // Handle the response
      if (response.statusCode == 200) {
        log(response.toString());
        return FileUploadResponse.fromJson(jsonDecode(responseData.body));
      } else {
        log(response.toString());
        throw Exception('Failed to upload file: ${responseData.body}');
      }
    } catch (e) {
      FunctionUtils.showErrorMessage(
          message: "Error while uploading file:${e.toString()}");
      return null;
    }
  }

  Future<bool> postOperatorsMesssage(
      Server server, User chat, String msg) async {
    print("postOperatorsMesssage");
    Map params = {};
    params["msg"] = msg;
    print(chat.chat_id);
    ParsedResponse response = await makeRequest(
        server, "/groupchat/addmessage/${chat.chat_id}?rest_api=true", params);
    print(response.isOk());
    print(response.body.toString());
    return response.isOk() ? true : false;
  }

  Future<Map<String, dynamic>> chatData(Server server, Chat chat) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/chatdata/${chat.id}", null);

    Map<String, dynamic> chatData = {};

    if (response.isOk() && response.body["error"].toString() == "false") {
      chatData = Map.castFrom(response.body);
    }
    return chatData;
  }

  Future<Map<String, dynamic>> cannedResponses(Server server, Chat chat) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/cannedresponses/${chat.id}", null);

    Map<String, dynamic> chatData = {};

    if (response.isOk() && response.body["error"].toString() == "false") {
      chatData = Map.castFrom(response.body);
    }
    return chatData;
  }

  Future<Map<String, dynamic>> chatOperatorsData(
      Server server, User chat) async {
    ParsedResponse response = await makeRequest(
        server, "/restapi/startchatwithoperator/${chat.user_id}", null);

    Map<String, dynamic> chatData = {};

    if (response.isOk()) {
      chatData = Map.castFrom(response.body);
    }

    return chatData;
  }

  Future<List<TwilioPhone>> getTwilioPhones(Server server) async {
    var resp = await makeRequest(server, "/restapi/twilio_phones", null);
    List<TwilioPhone> phonesList = <TwilioPhone>[];
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

  Future<bool> sendTwilioSMS(Server server, TwilioPhone phone, String toNumber,
      String message, bool createChat) async {
    Map<String, dynamic> params = Map<String, dynamic>();

    params.addAll({
      "twilio_id": phone.id,
      "phone_number": toNumber,
      "create_chat": createChat,
      "msg": message
    });

    try {
      ParsedResponse response = await makeRequest(
          server, "/restapi/twilio_create_sms", params,
          asJson: true, method: 'post');

      if (response.isOk()) {
        return true;
      } else
        return false;
    } catch (ex) {
      throw ex;
    }
  }

  Future<bool> pushNotificationStatus(Server server, {bool? newStatus}) async {
    Map<String, dynamic>? params =
        newStatus == null ? null : {"status": newStatus.toString()};
    bool asJson = params != null;

    try {
      ParsedResponse response = await makeRequest(
          server, "/restapi/notifications/${server.installationid}", params,
          asJson: asJson);
      if (response.isOk()) {
        return WidgetUtils.checkInt(response.body['status']) == 1;
      } else
        return false;
    } catch (ex) {
      throw Exception(ex);
    }
  }

  Future<bool> togglePushNotification(Server server) async {
    bool enabled = false;
    try {
      enabled = await pushNotificationStatus(server);
    } catch (ex) {
      throw Exception(ex);
    }
    try {
      return pushNotificationStatus(server, newStatus: !enabled);
    } catch (ex) {
      throw Exception(ex);
    }
  }
}
