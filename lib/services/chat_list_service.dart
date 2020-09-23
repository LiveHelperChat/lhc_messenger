import 'dart:convert';

import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/services/server_requests.dart';

class ChatListService extends ServerRequest {

  
  // fetch list and return a formatted Map of active,pending,... chat lists
  Future<Server> getChatLists(Server server) async {
    ParsedResponse response = await makeRequest(server, "/xml/lists", null);

    if (response.isOk()) {
      int activeSize = response.body['active_chats']['size'];
      if (activeSize > 0) {
        // activeList = Map.castFrom(activeJson).values.toList();
        Map activeJson = response.body['active_chats']['rows'];
        List<dynamic> newActiveList =
            chatListToMap(server.id, activeJson.values.toList());
        if (newActiveList != null && newActiveList.length > 0)
          server.addChatsToList(newActiveList, 'active');
      } else
        server.clearList('active');

      int pendingSize = response.body['pending_chats']['size'];
      if (pendingSize > 0) {
        Map pendingJson = response.body['pending_chats']['rows'];
        List<dynamic> newPendingList =
            chatListToMap(server.id, pendingJson.values.toList());
        if (newPendingList != null && newPendingList.length > 0)
          server.addChatsToList(newPendingList, 'pending');
      } else
        server.clearList('pending');

      int transferSize = response.body['transfered_chats']['size'];
      if (transferSize > 0) {
        List<dynamic> transferredList =
            response.body['transfered_chats']['rows'];

        List<dynamic> newTransferList =
            chatListToMap(server.id, transferredList);
        if (newTransferList != null && newTransferList.length > 0)
          server.addChatsToList(newTransferList, 'transfer');
      } else
        server.clearList('transfer');

      //close database
    }
    return server;
  }


}
