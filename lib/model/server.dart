import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/widget_utils.dart';

// ignore_for_file: non_constant_identifier_names
class Server {
  //Tablename
  static final String tableName = "server";
  static final int LOGGED_OUT = 0;
  static final int LOGGED_IN = 1;

  //Columns
  static final Map columns = {
    'db_id': "id",
    "db_userid": "userid",
    'db_installationid': "installationid",
    'db_servername': "servername",
    'db_url': "url",
    'db_urlhasindex': "urlhasindex",
    'db_isloggedin': "isloggedin",
    'db_rememberme': "rememberme",
    'db_soundnotify': "soundnotify",
    'db_vibrate': "vibrate",
    'db_username': "username",
    'db_password': "password",
    'db_firstname': "firstname",
    'db_surname': "surname",
    'db_operatoremail': "email",
    'db_job_title': "job_title",
    'db_all_departments': "all_departments",
    'db_departments_ids': "departments_ids",
    "db_user_online": "user_online",
    'db_twilio_installed': "twilio_installed"
  };
  bool get appendIndexToUrl => _urlhasindex != 0;
  set appendIndexToUrl(bool value) =>
      _urlhasindex = WidgetUtils.checkInt(value);

  bool get loggedIn => this.isloggedin == Server.LOGGED_IN;

  bool twilioInstalled = false, extensionsSynced;
  int id,
      userid,
      isloggedin,
      rememberme,
      soundnotify,
      vibrate,
      all_departments,
      user_online,
      _urlhasindex;
  String installationid,
      servername,
      url,
      username,
      password,
      firstname,
      surname,
      job_title,
      operatoremail,
      departments_ids;

  List<Chat> pendingChatList;
  List<Chat> activeChatList;
  List<Chat> transferChatList;
  List<Chat> twilioChatList;

  Server(
      {this.id,
      this.userid,
      this.isloggedin = 0,
      this.rememberme = 0,
      this.soundnotify = 1,
      this.vibrate = 0,
      this.installationid,
      this.servername,
      this.url,
      this.username,
      this.password,
      this.firstname,
      this.surname,
      this.job_title,
      this.all_departments,
      this.departments_ids,
      this.operatoremail,
      this.user_online,
      this.twilioInstalled,
      int urlHasIndex}) {
    _urlhasindex = urlHasIndex;
    pendingChatList = List<Chat>();
    activeChatList = List<Chat>();
    transferChatList = List<Chat>();
    twilioChatList = List<Chat>();
  }

  String getUrl() => appendIndexToUrl ? url + "/index.php" : url;

  Server.fromMap(Map<String, dynamic> map)
      : this(
            id: WidgetUtils.checkInt(map[columns['db_id']]),
            userid: WidgetUtils.checkInt(map[columns['db_userid']]),
            isloggedin: map[columns['db_isloggedin']],
            rememberme: map[columns['db_rememberme']],
            soundnotify: map[columns['db_soundnotify']],
            vibrate: map[columns['db_vibrate']],
            installationid: map[columns['db_installationid']],
            servername: map[columns['db_servername']],
            url: map[columns['db_url']],
            username: map[columns['db_username']],
            password: map[columns['db_password']],
            firstname: map[columns['db_firstname']],
            surname: map[columns['db_surname']],
            job_title: map[columns['db_job_title']],
            all_departments: map[columns['db_all_departments']],
            departments_ids: map[columns['db_departments_ids']],
            operatoremail: map[columns['db_operatoremail']],
            user_online: map[columns['db_user_online']],
            urlHasIndex: map[columns['db_urlhasindex']]);

  Map<String, dynamic> toMap() {
    return {
      columns['db_id']: id,
      columns['db_userid']: userid,
      columns['db_installationid']: installationid,
      columns['db_servername']: servername,
      columns['db_url']: url,
      columns['db_username']: username,
      columns['db_password']: password,
      columns['db_isloggedin']: isloggedin,
      columns['db_rememberme']: rememberme,
      columns['db_soundnotify']: soundnotify,
      columns['db_vibrate']: vibrate,
      columns['db_firstname']: firstname,
      columns['db_operatoremail']: operatoremail,
      columns['db_surname']: surname,
      columns['db_job_title']: job_title,
      columns['db_all_departments']: all_departments,
      columns['db_departments_ids']: departments_ids,
      columns['db_user_online']: user_online,
      columns['db_urlhasindex']: appendIndexToUrl,
      'twilio_installed': twilioInstalled
    };
  }

  void addChatsToList(List<dynamic> newChatList, String list) {
    switch (list) {
      case "active":
        this.activeChatList ??= new List<Chat>();
        this.activeChatList = _cleanUpLists(this.activeChatList, newChatList);
        //Sort list by last message time
        this
            .activeChatList
            .sort((a, b) => b.last_msg_time.compareTo(a.last_msg_time));
        break;
      case "pending":
        this.pendingChatList ??= new List<Chat>();
        this.pendingChatList = _cleanUpLists(this.pendingChatList, newChatList);
        break;
      case "transfer":
        this.transferChatList ??= new List<Chat>();
        this.transferChatList =
            _cleanUpLists(this.transferChatList, newChatList);
        break;
      case "twilio":
        this.twilioChatList ??= new List<Chat>();
        this.twilioChatList = _cleanUpLists(this.twilioChatList, newChatList);
        break;
    }
  }

  List<Chat> _cleanUpLists(
      List<Chat> chatToClean, List<dynamic> listFromServer) {
    var incomingList = listFromServer.map((map) => new Chat.fromMap(map));
    incomingList.forEach((map) {
      if (chatToClean
          .any((chat) => chat.id == map.id && chat.serverid == map.serverid)) {
        int index = chatToClean.indexWhere(
            (chat) => chat.id == map.id && chat.serverid == map.serverid);
        chatToClean[index] = map;
      } else {
        chatToClean.add(map);
      }
    });

    //remove missing
    if (chatToClean.length > 0 && incomingList.length > 0) {
      List<int> removedIndices = new List();
      chatToClean.forEach((chat) {
        if (!incomingList
            .any((map) => map.id == chat.id && map.serverid == chat.serverid)) {
          int index = chatToClean.indexOf(chat);
          removedIndices.add(index);
        }
      });

      //remove the chats
      if (removedIndices != null && removedIndices.length > 0) {
        removedIndices.sort();
        removedIndices.reversed.toList().forEach(chatToClean.removeAt);
        removedIndices.clear();
      }
    }

    return chatToClean;
  }

  void clearList(String list) {
    switch (list) {
      case 'active':
        this.activeChatList?.clear();
        break;
      case 'pending':
        this.pendingChatList?.clear();
        break;
      case 'transfer':
        this.transferChatList?.clear();
        break;
      case 'twilio':
        this.twilioChatList?.clear();
        break;
      default:
        break;
    }
  }

  void removeChat(int id, String list) {
    switch (list) {
      case 'active':
        this.activeChatList.removeWhere((chat) => chat.id == id);
        break;
      case 'pending':
        this.pendingChatList.removeWhere((chat) => chat.id == id);
        break;
      case 'transfer':
        this.transferChatList.removeWhere((chat) => chat.id == id);
        break;
    }
  }

  List<Chat> removeMissingFromList(
      List<Chat> toBeCleaned, List<Chat> incomingList) {
    //List<Chat> toBeCleaned = chatToClean;
    List<int> removedIndices = new List();

    toBeCleaned.forEach((chat) {
      if (this.id == chat.serverid) {
        if (!incomingList.any((map) => map.id != chat.id)) {
          int index = toBeCleaned.indexOf(chat);
          print("Index ${index.toString()}");
          removedIndices.add(index);
        }
      }
    });

    //remove the chats
    if (removedIndices.length > 0) {
      removedIndices.sort();
      removedIndices.reversed.toList().forEach(toBeCleaned.removeAt);
      removedIndices.clear();
    }

    return toBeCleaned;
  }
}
