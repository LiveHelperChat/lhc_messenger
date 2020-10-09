import 'dart:async';

import 'package:livehelp/data/database.dart';
import 'package:flutter/foundation.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';

class ServerRepository {
  final ServerApiClient serverApiClient;
  final DatabaseHelper dBHelper;

  ServerRepository({@required this.serverApiClient, @required this.dBHelper})
      : assert(serverApiClient != null, dBHelper != null);

  Future<Server> fetchChatList(Server server) async {
    return serverApiClient.getChatLists(server);
  }

  Future<List<Server>> getServersFromDB({bool onlyLoggedIn = false}) {
    return dBHelper.getServers(onlyLoggedIn);
  }

  Future<Server> loginServer(Server server) {
    return serverApiClient.login(server);
  }

  Future<Server> saveServerToDB(
      Server server, String condition, List whereArg) {
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
    int isOnline = online ? 1 : 0;

    server.user_online = isOnline;
    return saveServerToDB(server, "id=?", [server.id]);
  }

  Future<Server> setUserOnlineStatus(Server server) async {
    var online = await serverApiClient.setUserOnlineStatus(server);
    server.user_online = online ? 1 : 0;
    server = await saveServerToDB(server, "id=?", [server.id]);
    return server;
  }

  Future<Map<String, dynamic>> syncMessages(
      Server server, Chat chat, int lastMsgId) {
    return serverApiClient.syncMessages(server, chat, lastMsgId);
  }

  Future<bool> postMesssage(Server server, Chat chat, String msg) {
    return serverApiClient.postMesssage(server, chat, msg);
  }

  Future<bool> closeChat(
    Server server,
    Chat chat,
  ) {
    return serverApiClient.closeChat(server, chat);
  }

  Future<bool> deleteChat(
    Server server,
    Chat chat,
  ) {
    return serverApiClient.deleteChat(server, chat);
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
}
