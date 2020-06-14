import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

import 'package:path_provider/path_provider.dart';

import 'package:livehelp/model/server.dart';
import 'package:livehelp/model/chat.dart';

class DatabaseHelper {
  static DatabaseHelper _livehelpDatabase;

  final int dbVersion = 2; // previous 1
  final String configTable = "app_config";
  final String tokenColumn = "fcm_token";
  final String extVersionColumn = "ext_version";

  bool didInit = false;

  Database _db;
  final _lock = new Lock();

  factory DatabaseHelper() {
    if (_livehelpDatabase != null) return _livehelpDatabase;
    _livehelpDatabase = new DatabaseHelper._internal();

    return _livehelpDatabase;
  }

  static DatabaseHelper get() {
    return _livehelpDatabase;
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
        "${Server.columns['db_user_online']} BIT"
        ")");
/*
      await db.execute(
          "CREATE TABLE ${Chat.tableName} ("
              "${Chat.columns['db_id']} INTEGER,"
              "${Chat.columns['db_serverid']} INTEGER,"
              "${Chat.columns['db_status']} INTEGER,"
              "${Chat.columns['db_nick']} TEXT,"
              "${Chat.columns['db_email']} TEXT,"
              "${Chat.columns['db_ip']} TEXT,"
              "${Chat.columns['db_time']} INTEGER,"
              "${Chat.columns['db_last_msg_id']} INTEGER,"
              "${Chat.columns['db_user_id']} INTEGER,"
              "${Chat.columns['db_country_code']} TEXT,"
              "${Chat.columns['db_country_name']} TEXT,"
              "${Chat.columns['db_referrer']} TEXT,"
              "${Chat.columns['db_uagent']} TEXT,"
              "${Chat.columns['db_department_name']} TEXT,"
              "${Chat.columns['db_user_typing_txt']} TEXT,"
              "${Chat.columns['db_owner']} TEXT,"
              "${Chat.columns['db_has_unread_messages']} INTEGER"
              ")");
      */
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
        if (_db == null) {
          _db = await openDatabase(
            path,
            version: dbVersion,
            onCreate: this._create,
            onUpgrade: this._upgradeDB,
          );
        }
      });
    }

    return _db;
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    print("oLD " + oldVersion.toString() + " new " + newVersion.toString());
    if (oldVersion < newVersion) {
      db.execute("ALTER TABLE $configTable ADD COLUMN $extVersionColumn TEXT;");
    }
  }

  /// Get an item by its id, if there is not entry for that ID, returns null.
  Future<Map<String, dynamic>> fetchItem(
      String tableName, String condition, List arguments) async {
    var db = await getDb();
    var result =
        await db.query(tableName, where: condition, whereArgs: arguments); //
    if (result.length == 0) return null;
    // print(result[0].toString());
    return result[0];
  }

  Future<List<dynamic>> fetchAll(String tableName, String orderBy,
      String condition, List arguments) async {
    var db = await getDb();
    return db
        .query(tableName, where: condition, whereArgs: arguments)
        .then((res) {
      return res;
    }); //tableName,columns:columns
  }

  Future<Null> upsertFCMToken(String token) async {
    // print("Token: $token");
    var db = await getDb();
    Map<String, dynamic> tkn = {};
    tkn[tokenColumn] = token;

    List<Map<String, dynamic>> listMap =
        await db.rawQuery("SELECT * FROM $configTable");
    // print("UpsertFCM "+listMap.toString());
    if (listMap == null || listMap.length == 0) {
      await db.insert(configTable, tkn);
    } else {
      if (listMap.contains(tkn)) {
      } else
        await db.update(configTable, tkn);
    }
  }

  Future upsertChat(Chat chat) async {
    var db = await getDb();
    var count = Sqflite.firstIntValue(await db.rawQuery(
        "SELECT COUNT(*) FROM ${Chat.tableName}"
        " WHERE id = ? and status= ? and serverid= ?",
        [chat.id, chat.status, chat.serverid]));
    if (count == 0) {
      chat.id = await db.insert(Chat.tableName, chat.toMap());
    } else {
      await db.update(Chat.tableName, chat.toMap(),
          where: "id = ?", whereArgs: [chat.id]);
    }
    return chat;
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
      Chat chat = new Chat.fromMap(row);

      List<Map<String, dynamic>> listMap = await db.rawQuery(
          "SELECT COUNT(*) FROM chat"
          " WHERE id = ? and status= ? and serverid= ?",
          [chat.id, chat.status, chat.serverid]);
      var count = listMap.first.values.first;
      if (count == 0) {
        return await db.insert(Chat.tableName, chat.toMap());
      } else {
        return await db.update(Chat.tableName, chat.toMap(),
            where: "id = ?", whereArgs: [chat.id]);
      }
    });
  }

  Future<Server> upsertServer(
      Server server, String condition, List whereArg) async {
    var db = await getDb();
    List<Map<String, dynamic>> listMap = await db.rawQuery(
        "SELECT COUNT(*) FROM ${Server.tableName}"
        " WHERE $condition",
        whereArg);

    var count = listMap.first.values.first;
    if (count == 0) {
      //server.id = null;
      server.id = await db.insert(Server.tableName, server.toMap());
      return server;
    } else {
      await db.update(Server.tableName, server.toMap(),
          where: "id = ?", whereArgs: [server.id]).then((val) => _resetDb());
      // db.close();

      return server;
    }
  }

  Future upsertGeneral(String tableName, Map<String, dynamic> values) async {
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
}
