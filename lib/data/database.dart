import 'dart:async';
import 'dart:io';

import 'package:livehelp/model/model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

class DatabaseHelper {
  static DatabaseHelper? _livehelpDatabase;

  final int dbVersion = 4; // previous 1
  final String configTable = "app_config";
  final String tokenColumn = "fcm_token";
  final String extVersionColumn = "ext_version";

  bool didInit = false;

  Database? _db;
  final _lock = Lock();

  factory DatabaseHelper() {
    if (_livehelpDatabase != null) return _livehelpDatabase!;
    _livehelpDatabase = DatabaseHelper._internal();

    return _livehelpDatabase!;
  }

  static DatabaseHelper get() {
    return _livehelpDatabase!;
  }

  DatabaseHelper._internal();

  Future _create(Database db, int version) async {
    // When creating the db, create the tables
    await db.execute("CREATE TABLE ${Server.tableName} ("
        "${Server.columns['db_id']} INTEGER PRIMARY KEY AUTOINCREMENT,"
        "${Server.columns['db_installationid']} TEXT,"
        "${Server.columns['db_servername']} TEXT,"
        "${Server.columns['db_url']} TEXT,"
        "${Server.columns['db_urlhasindex']} BIT,"
        "${Server.columns['db_isloggedin']} INTEGER,"
        "${Server.columns['db_userid']} INTEGER,"
        "${Server.columns['db_username']} TEXT,"
        "${Server.columns['db_password']} TEXT,"
        "${Server.columns['db_rememberme']} INTEGER,"
        "${Server.columns['db_soundnotify']} INTEGER NOT NULL DEFAULT 1,"
        "${Server.columns['db_vibrate']} INTEGER,"
        "${Server.columns['db_firstname']} TEXT,"
        "${Server.columns['db_surname']} TEXT,"
        "${Server.columns['db_operatoremail']} TEXT,"
        "${Server.columns['db_job_title']} TEXT,"
        "${Server.columns['db_all_departments']} BIT,"
        "${Server.columns['db_departments_ids']} TEXT,"
        "${Server.columns['db_user_online']} BIT,"
        "${Server.columns['db_twilio_installed']} BIT,"
        "${Server.columns['db_fb_installed']} BIT"
        ")");

    await db.execute("CREATE TABLE $configTable ("
        "'id' INTEGER PRIMARY KEY AUTOINCREMENT,"
        "$tokenColumn TEXT,"
        "$extVersionColumn TEXT"
        ")");

    didInit = true;
  }

  void debug() async {
    var db = await getDb();
    print(await db.query(configTable));
  }

  Future<Database> getDb() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "lhcmessenger.db");

    if (_db == null) {
      await _lock.synchronized(() async {
        // Check again once entering the synchronized block
        _db ??= await openDatabase(
          path,
          version: dbVersion,
          onCreate: _create,
          onUpgrade: _upgradeDB,
        );
      });
    }

    return _db!;
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // print("oLD " + oldVersion.toString() + " new " + newVersion.toString());
    if (oldVersion < 2) {
      db.execute("ALTER TABLE $configTable ADD COLUMN $extVersionColumn TEXT;");
    }
    if (oldVersion < 3) {
      db.execute(
          "ALTER TABLE ${Server.tableName} ADD COLUMN ${Server.columns['db_twilio_installed']} BIT;");
    }
    if (oldVersion < 4) {
      db.execute(
          "ALTER TABLE ${Server.tableName} ADD COLUMN ${Server.columns['db_fb_installed']} BIT;");
    }
  }

  /// Get an item by its id, if there is not entry for that ID, returns null.
  Future<Map<String, dynamic>?> fetchItem(
      String tableName, String condition, List arguments) async {
    var db = await getDb();
    var result =
        await db.query(tableName, where: condition, whereArgs: arguments); //
    if (result.length == 0) return null;
    // print(result[0].toString());
    return result[0];
  }

  Future<List<dynamic>> fetchAll(String tableName, String orderBy,
      String? condition, List arguments) async {
    var db = await getDb();
    return db
        .query(tableName, where: condition, whereArgs: arguments)
        .then((res) {
      return res;
    }); //tableName,columns:columns
  }

  Future<Null> upsertFCMToken(String token) async {
    var db = await getDb();
    Map<String, dynamic> tkn = {};
    tkn[tokenColumn] = token;

    List<Map<String, dynamic>> listMap =
        await db.rawQuery("SELECT * FROM $configTable");
    if (listMap.length == 0) {
      await db.insert(configTable, tkn);
    } else {
      if (listMap.contains(tkn)) {
      } else
        await db.update(configTable, tkn);
    }
  }

  Future upsertChat(Chat chat) async {
    Chat newChat = chat;
    var db = await getDb();
    var count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM ${Chat.tableName}"
        " WHERE id = ? and status= ? and serverid= ?",
        [chat.id, chat.status, chat.serverid]));
    if (count == 0) {
      int id = await db.insert(Chat.tableName, chat.toJson());
      newChat = chat.copyWith(id: id);
    } else {
      int id = await db.update(Chat.tableName, chat.toJson(),
          where: "id = ?", whereArgs: [chat.id]);
      newChat = chat.copyWith(id: id);
    }
    return newChat;
  }

  Future countRecords(String tableName, String condition, List whereArg) async {
    var db = await getDb();
    var count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM $tableName"
        " WHERE $condition",
        whereArg));
    return count;
  }

  Future<Null> bulkInsertChats(
      Server srvr, List<Map<dynamic, dynamic>> bulkRecords) async {
    var db = await getDb();

    bulkRecords.forEach((row) async {
      //Add server id to row
      row['serverid'] = srvr.id;
      Chat chat = Chat.fromJson(row);

      List<Map<String, dynamic>> listMap = await db.rawQuery(
          "SELECT COUNT(*) FROM chat"
          " WHERE id = ? and status= ? and serverid= ?",
          [chat.id, chat.status, chat.serverid]);
      var count = listMap.first.values.first;
      if (count == 0) {
        await db.insert(Chat.tableName, chat.toJson());
      } else {
        await db.update(Chat.tableName, chat.toJson(),
            where: "id = ?", whereArgs: [chat.id]);
      }
    });
  }

  Future<Server> upsertServer(
      Server server, String? condition, List whereArg) async {
    var db = await getDb();
    List<Map<String, dynamic>> listMap = await db.rawQuery(
        "SELECT COUNT(*) FROM ${Server.tableName}"
        " WHERE $condition",
        whereArg);

    var count = listMap.first.values.first;
    if (count == 0) {
      //server.id = null;
      server.id = await db.insert(Server.tableName, server.toJson());
      return server;
    } else {
      await db.update(Server.tableName, server.toJson(),
          where: "id = ?", whereArgs: [server.id]).then((val) => _resetDb());
      // db.close();

      return server;
    }
  }

  Future upsertGeneral(String tableName, Map<String, dynamic> values) async {
    print("upsertGeneral");
    var db = await getDb();
    var count = Sqflite.firstIntValue(
        await db.rawQuery("SELECT COUNT(*) FROM $tableName"));
    int id;
    if (count == 0) {
      id = await db.insert(tableName, values);
    } else {
      id = await db.update(tableName, values);
    }
    return id;
  }

/*
  Future bulkInsert(Server srvr,String tableName,List<Map> bulkRecords) async{
    var db = await _getDb();
    var batch = db.batch();
    bulkRecords.forEach((row){
      //Add server id to row
      row['serverid'] = srvr.id;
      batch.insert(tableName,row);
    });

    var  results= await batch.apply();
  }
  */

  update(String tableName, Map<String, dynamic> valueMap) async {
    var db = await getDb();
    await db.update(tableName, valueMap);
  }

  Future deleteAll(String tableName) async {
    var db = await getDb();
    await db.delete(tableName);
  }

  Future<Null> _resetDb() async {
    // db = null;
  }

  Future<bool> deleteItem(
      String tableName, String condition, List whereArg) async {
    var db = await getDb();
    return db
        .delete(tableName, where: "id=?", whereArgs: whereArg)
        .then((rows) {
      return rows > 0 ? true : false;
    });
  }

  Future<List<Server>> getServers(bool onlyLoggedIn) async {
    print("getServers");
    String? condition;
    List args = [];
    if (onlyLoggedIn) {
      condition = "isloggedin=?";
      int loggedIn = onlyLoggedIn ? 1 : 0;
      args = [loggedIn];
    }
    List savedservers = await fetchAll(
        Server.tableName, "${Server.columns['db_id']}  ASC", condition, args);
    List<Server> serversList = [];
    if (savedservers.isNotEmpty) {
      savedservers.forEach((item) {
        Server newServer = Server.fromJson(item);
        serversList.add(newServer);
      });
    }
    return serversList;
  }
}
