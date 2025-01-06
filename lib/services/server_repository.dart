import 'dart:async';
import 'dart:io';

import 'package:livehelp/data/database.dart';
import 'package:livehelp/model/file_upload_response.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';

class ServerRepository {
  final ServerApiClient serverApiClient;
  final DatabaseHelper dBHelper;

  ServerRepository({required this.serverApiClient, required this.dBHelper});

  Future<Server> fetchChatList(Server server) async {
    //print("fetchChatList");
    return serverApiClient.getChatLists(server);
  }

  Future<List<Server>> getServersFromDB({bool onlyLoggedIn = false}) {
    return dBHelper.getServers(onlyLoggedIn);
  }

  Future<Server> loginServer(Server server) {
    
    return serverApiClient.login(server);
  }

  Future<Server> saveServerToDB(
      Server server, String? condition, List whereArg) {
    return dBHelper.upsertServer(server, condition, whereArg);
  }

  Future<bool> isExtensionInstalled(Server server, String extensionName) {
    return serverApiClient.isExtensionInstalled(server, extensionName);
  }

  Future<Server> fetchInstallationId(
      Server server, String token, String action) {
    return serverApiClient.fetchInstallationId(server, token, action);
  }

  Future<Map<String, dynamic>> fetchUserFromServer(Server server) {
    return serverApiClient.getUserFromServer(server);
  }

  Future fetchItemFromDB(String tableName, String condition, List args) {
    return dBHelper.fetchItem(tableName, condition, args);
  }

  Future<Server> getUserOnlineStatus(Server server) async {
    bool online = await serverApiClient.getUserOnlineStatus(server);

    server.userOnline = online;
    return saveServerToDB(server, "id=?", [server.id]);
  }

  Future<Server> setUserOnlineStatus(Server server) async {
    var online = await serverApiClient.setUserOnlineStatus(server);
    server.userOnline = online;
    server = await saveServerToDB(server, "id=?", [server.id]);
    return server;
  }

  Future<Map<String, dynamic>> syncMessages(
      Server server, Chat chat, int lastMsgId) {
    return serverApiClient.syncMessages(server, chat, lastMsgId);
  }

  Future<Map<String, dynamic>> syncOperatorsMessages(
      Server server, User chat, int lastMsgId) {
    return serverApiClient.syncOperatorsMessages(server, chat, lastMsgId);
  }

  Future<bool> postMesssage(Server server, Chat chat, String msg,{String? sender}) {
    return serverApiClient.postMesssage(server, chat, msg,sender: sender);
  }

  //upload file
  Future<FileUploadResponse?> uploadFile(
    Server server,
    File file, {
    String? namePrepend,
    String? nameReplace,
    bool? persistent,
    int? chatId,
  }) {
    return serverApiClient.uploadFile(
      server,
      file,
      namePrepend: namePrepend,
      nameReplace: nameReplace,
      persistent: persistent,
      chatId: chatId,
    );
  }

  Future<bool> postOperatorsMesssage(Server server, User chat, String msg) {
    print("postOperatorsMesssage 1st");
    return serverApiClient.postOperatorsMesssage(server, chat, msg);
  }

  Future<bool> closeChat(
    Server server,
    Chat chat,
  ) {
    return serverApiClient.closeChat(server, chat);
  }

  Future<bool> closeOperatorsChat(
    Server server,
    User chat,
  ) {
    return serverApiClient.closeOperatorsChat(server, chat);
  }

  Future<bool> deleteChat(
    Server server,
    Chat chat,
  ) {
    return serverApiClient.deleteChat(server, chat);
  }

  Future<bool> deleteOperatorsChat(
    Server server,
    User chat,
  ) {
    return serverApiClient.deleteOperatorsChat(server, chat);
  }

  Future<List<dynamic>> getOperatorsList(Server server) {
    return serverApiClient.getOperatorsList(server);
  }

  Future<bool> transferChatUser(Server server, Chat chat, int userId) {
    return serverApiClient.transferChatUser(server, chat, userId);
  }

  Future<bool> deleteServer(Server srvr) async {
    return dBHelper.deleteItem(Server.tableName, "id=?", [srvr.id]);
  }

  Future<List<TwilioPhone>> getTwilioPhones(Server server) async {
    return serverApiClient.getTwilioPhones(server);
  }

  Future<bool> sendTwilioSMS(Server server, TwilioPhone phone, String toNumber,
      String message, bool createChat) async {
    return serverApiClient.sendTwilioSMS(
        server, phone, toNumber, message, createChat);
  }

  Future<bool> pushNotification(Server server) async {
    return serverApiClient.pushNotificationStatus(server);
  }

  Future<bool> toggleNotification(Server server) async {
    return serverApiClient.togglePushNotification(server);
  }
}
