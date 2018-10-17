import 'dart:async';
import 'dart:convert';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/chat.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/department.dart';
import 'package:http/http.dart' as http;


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

  ServerRequest(){

    dbHelper =new DatabaseHelper();
    _client = new http.Client();
  }


  dispose()async {
    _client.close();
  }

  Future<ParsedResponse> _makeRequest(Server server,String path,Map jsonParams) async {

    Map parameters={};
    parameters['username']= server.username;
    parameters['password'] = server.password;

    if(jsonParams != null) parameters.addAll(jsonParams);
    //{'username':'${server.username}','password':'${server.password}'}
    //http request, catching error like no internet connection.
    //If no internet is available for example
    return await _client.post(server.getUrl()+path, body:parameters)
        .then((response){

     // print (response.statusCode);
     // print ('Body: ${response.body}');

      if(response == null) {
        return new ParsedResponse(NO_INTERNET, json.decode('{"error":"true"}'));
      }
      //If there was an error return an empty list
      if(response.statusCode < 200 || response.statusCode >= 300) {
        //print(response.body.toString());
        return new ParsedResponse(response.statusCode, json.decode('{"error":"true"}'));
      }
      var respBody ={};
      try{
        response.body != null ? respBody = json.decode(response.body) : respBody=null;
      } catch(Exception){}

      return new ParsedResponse(response.statusCode, respBody );
    })
        .catchError((resp) {
      return new ParsedResponse(NO_INTERNET, json.decode('{"error":"true","msg":"Request could not be sent"}') );
        });



  }

  Future<Server> login(Server server) {
  return  _makeRequest(server, "/xml/checklogin", null)
    .then((resp)async{
   // print (resp.body);
      if(resp.isOk() && resp.body["result"].toString() =="true")
      {
        server.isloggedin = Server.LOGGED_IN;
        return server;
    }
    else{
        server.isloggedin = Server.LOGGED_OUT;
        return server;
      }
    });

  }



  Future<Server> fetchInstallationId(Server server,String token,String action) async{
    Map param = {};
    param["action"] =action;
    if(token.isNotEmpty) param["regId"] = token;
   return await _makeRequest(server, "/gcm/registerdevice",param)
   .then((response) async{
     //print("Body"+response.body.toString());
     if(response.isOk() && response.body["error"].toString() =="false") {
       server.installationid = response.body["results"].toString();
     }

     return server;
   });

  }

  Future<String> fetchVersionExt(Server server) async{
    Map param = {};
     param["regId"] = server.installationid;
    return await _makeRequest(server, "/gcm/registerdevice",param)
        .then((response) async{
    //  print("Body"+response.body.toString());
          String resp;
      if(response.isOk() && response.body["error"].toString() =="false") {
        resp = response.body["version"].toString();
      }
      return resp;
    });

  }

  // returns a list of chats as maps
  List<dynamic> _chatListToMap(int server_id,List jsonList){
    // dynamically pick the fields from the json returned
    // matching the database columns
    var listToStore=new List<Map<dynamic,dynamic>>();
        jsonList.forEach((k){
          // Add Server id to chat
          k["${Chat.columns['db_serverid']}"] =server_id;


      Map<String, dynamic> chatsToStore = {};
      // print(k);
      Chat.columns.values.forEach((val) {
        chatsToStore[val] = k[val] ;
      });

      listToStore.add(chatsToStore);
    }

    );
    return listToStore;
  }

  // fetch list and return a formatted Map of active,pending,... chat lists
  Future<Server> getChatLists(Server server) async{
    ParsedResponse response = await _makeRequest(server, "/xml/lists", null);

    Map<String,dynamic> allChatLists={};

    if(response.isOk() && response.body != null ) {
      int activeSize = response.body['active_chats']['size'];
      if (activeSize > 0) {
        // activeList = Map.castFrom(activeJson).values.toList();
        Map activeJson = response.body['active_chats']['rows'];
  /*      allChatLists['active_chats'] =
            _chatListToMap(server.id, activeJson.values.toList());
*/
        List<dynamic> newActiveList = _chatListToMap(server.id, activeJson.values.toList());
        if(newActiveList != null && newActiveList.length >0) server.addChatsToList(newActiveList, 'active');

     //  await dbHelper.bulkInsertChats(
      //     server, _chatListToMap(server.id, activeJson.values.toList()));
      } else server.clearList('active');

      int pendingSize = response.body['pending_chats']['size'];
      if (pendingSize > 0) {
        Map pendingJson = response.body['pending_chats']['rows'];
/*
        allChatLists['pending_chats'] =
            _chatListToMap(server.id, pendingJson.values.toList());
        */
        List<dynamic> newPendingList = _chatListToMap(server.id, pendingJson.values.toList());
        if(newPendingList != null && newPendingList.length >0)
          server.addChatsToList(newPendingList, 'pending');

      }
      else server.clearList('pending');

      // TODO
      int transferSize = response.body['transfered_chats']['size'];
      if(transferSize >0){
      List<dynamic> transferredList = response.body['transfered_chats']['rows'];


      /*
        Fetch chatlist andn convert to map
        then save to server object
*/

        List<dynamic> newTransferList = _chatListToMap(server.id, transferredList);
      if(newTransferList != null && newTransferList.length >0) server.addChatsToList(newTransferList, 'transfer');
      }
      else server.clearList('transfer');

      //close database
    }
    return server;
  }

  Future<bool> postMesssage(Server server,Chat chat,String msg) async{
    Map params ={};
    params["msg"]=msg;
    ParsedResponse response = await _makeRequest(server, "/xml/addmsgadmin/${chat.id}", params);
     
    //print(response.body.toString()); 
    return response.isOk() ?  true : false;   
  }

  Future<bool> closeChat(Server server,Chat chat) async{
    ParsedResponse response = await _makeRequest(server, "/xml/closechat/${chat.id}", null);

    return response.isOk() ?  true : false;
  }

  Future<bool> deleteChat(Server server,Chat chat) async{
    ParsedResponse response = await _makeRequest(server, "/xml/deletechat/${chat.id}", null);

    if(response.isOk())
    server.removeChat(chat.id, 'active');

    return  response.isOk() ?  true : false;
  }

  Future<Map<String,dynamic>> syncMessages(Server server,Chat chat,int last_msg_id) async{
    Map params ={};
    params["chats"]= last_msg_id == 0 ? chat.id.toString() : chat.id.toString()+'|'+last_msg_id.toString();
    ParsedResponse response = await _makeRequest(server, "/xml/chatssynchro", params);

    Map<String,dynamic> messagesChatStatus =new Map<String,dynamic>();
    List<Message> listToMsgs=new List<Message>();

    //print("RESPONSE BODY. "+response.body.toString());

        if(response.isOk() && response.body["error"].toString() =="false") {
           Map results = {};
          results.addAll(response.body["result"]);
          Map level1 = results['${chat.id}'];

          messagesChatStatus['chat_status'] = level1["chat_status"].toString();

          if(level1['messages'] is Map) {
            Map msgs = level1['messages'];

            List msgsList = last_msg_id == 0 ? msgs[""] : msgs["$last_msg_id"];

            if (msgsList.length > 0) {
              msgsList.forEach((value) {
                listToMsgs.add(new Message.fromMap(value));
              });

              messagesChatStatus['messages'] =listToMsgs;
            }
          }
        }
        return messagesChatStatus;
  }


  Future<Map<String,dynamic>> chatData(Server server,Chat chat) async{
    
    ParsedResponse response = await _makeRequest(server, "/xml/chatdata/${chat.id}", null);

        Map<String,dynamic> chatData;

        if(response.isOk() && response.body["error"].toString() =="false"){
          chatData = Map.castFrom(response.body);
        }  

     //   print(chatData.toString());
        return chatData;

  }

  Future<Map<String,dynamic>> getUserFromServer(Server server)async{

   return await _makeRequest(server, "/gcm/getuser", new Map())
        .then((resp)async{
      Map<String,dynamic> user;
      if(resp.isOk() && resp.body["error"].toString() =="false")
      {
         user = Map.castFrom(resp.body['result']);
      }
      return user;
    });

  }


  Future<List<Department>> getUserDepartments(Server server) async{
    Map params ={};
    params['user_depids'] =
        json.encode({"all_departments":server.all_departments,"dep_ids":[server.departments_ids]});
    ParsedResponse response = await _makeRequest(server, "/gcm/getuserdepartments", params);

    List<Department> departments =new List<Department>();

    if(response.isOk() && response.body["error"].toString() =="false"){
     // print("Departments: "+response.body.toString());
      if(response.body['departments'] != null)
        {
          List<dynamic> dept = response.body['departments'];
          dept.forEach((map){
            departments.add(new Department.fromMap(map));
          });

        }
    }

    //   print(chatData.toString());
    return departments;
  }


  Future<Map<String,dynamic>> setDepartmentWorkHours(Server server,Department department) async{
    Map params ={};
   params['work_hours']=json.encode(department.toMapWorkHours());

    return await _makeRequest(server, "/gcm/departmenthours", params)
    .then((response){
      Map<String,dynamic> chatData ={};

      if(response.isOk() && response.body["error"].toString() =="false"){
        chatData = Map.castFrom(response.body);
      }

     //   print(chatData.toString());
      return chatData;
    });


  }

  Future<bool> setOperatorTyping(Server server,int chatid, bool istyping) async{
    Map params ={};
    params['chat_id']="$chatid";
    params['status']= istyping ? "true":"false";

    return await _makeRequest(server, "/gcm/operatortyping", params)
        .then((response){

      if(response.isOk()){
        return true;
      }
      else return false;

    });

  }


  Future<List<dynamic>> getOperatorsList(Server server) async{

    return await _makeRequest(server, "/xml/transferchat", null)
        .then((response){
      List<dynamic> operatorList=[];
      if(response.isOk() && response.body["result"] is List){
        List<dynamic> llist = response.body["result"];
        llist.forEach((map){
          // print("operator: "+map.toString());
          operatorList.add(map);
        });
      }
      return operatorList;

    });
  }
  Future<bool> transferChatUser(Server server,Chat chat,int userid) async{
    ParsedResponse response = await _makeRequest(server, "/xml/transferuser/${chat.id}/$userid", null);

    return response.isOk() ?  true : false;
  }

  Future<bool> acceptChatTransfer(Server server,Chat chat) async{
    ParsedResponse response = await _makeRequest(server, "/xml/accepttransferbychat/${chat.id}", null);

    return response.isOk() ?  true : false;
  }

  Future<bool> getUserOnlineStatus(Server server) async{
    ParsedResponse response = await _makeRequest(server, "/xml/getuseronlinestatus", null);

    if(response.isOk()){
      /*
        the logic is inverted. if it returns true, user is offline, false means user is online
       */

      if (response.body["online"].toString() == "true") {
        // user is offline
        // print("Online: "+response.body["online"].toString());
        return false;
      }
      else if(response.body["online"].toString() == "false")
        {
          // print("Online: "+response.body["online"].toString());
          return true;}

          else return false;


    }
    else return false;

  }

  Future<bool> setUserOnlineStatus(Server server) async{
    var status ="0";
    await getUserOnlineStatus(server)
    .then((isOnline){
     status = isOnline ? "1" : "0" ;
    });

  await  _makeRequest(server, "/xml/setonlinestatus/"+status, null);
    // status 1 or 0
    return await getUserOnlineStatus(server);
  }
}
