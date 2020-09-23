import 'package:livehelp/model/TwilioPhone.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/services/server_requests.dart';

class TwilioService extends ServerRequest {
  TwilioService(): super();

  Future<Server> getTwilioChats(Server server) async {
    // check for twilio extention
    var twilExt = await isExtensionInstalled(server, "twilio");

    if (twilExt) {
      String params = "twilio_sms_chat=true&prefill_fields=phone";
      var resp = await makeRequest(server, "/restapi/chats?" + params, null);
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
            List<dynamic> newTwilioList = chatListToMap(server.id, chats);
            if (newTwilioList != null && newTwilioList.length > 0)
              server.addChatsToList(newTwilioList, 'twilio');
          } else
            server.clearList("twilio");
        }
      }
    }

    return server;
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

}
