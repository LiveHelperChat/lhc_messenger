import 'dart:convert';

import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/services/server_requests.dart';

class ChatMessagesService extends ServerRequest {
  ChatMessagesService() : super();

  Future<bool> postMesssage(Server server, Chat chat, String msg) async {
    Map params = {};
    params["msg"] = msg;
    ParsedResponse response =
        await makeRequest(server, "/xml/addmsgadmin/${chat.id}", params);

    return response.isOk() ? true : false;
  }

  Future<Map<String, dynamic>> chatData(Server server, Chat chat) async {
    ParsedResponse response =
        await makeRequest(server, "/xml/chatdata/${chat.id}", null);

    Map<String, dynamic> chatData;

    if (response.isOk() && response.body["error"].toString() == "false") {
      chatData = Map.castFrom(response.body);
    }
    return chatData;
  }

  Future<Map<String, dynamic>> syncMessages(
      Server server, Chat chat, int last_msg_id) async {
    Map params = {};
    params["chats"] = last_msg_id == 0
        ? chat.id.toString()
        : chat.id.toString() + '|' + last_msg_id.toString();
    ParsedResponse response =
        await makeRequest(server, "/xml/chatssynchro", params);

    Map<String, dynamic> messagesChatStatus = new Map<String, dynamic>();
    List<Message> listToMsgs = new List<Message>();

    if (response.isOk() && response.body["error"].toString() == "false") {
      Map results = {};
      results.addAll(response.body["result"]);
      Map level1 = results['${chat.id}'];

      messagesChatStatus['chat_status'] = level1["chat_status"].toString();
      messagesChatStatus['chat_scode'] = level1["chat_scode"] ?? 0;

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
}
