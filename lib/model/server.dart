import 'package:livehelp/model/model.dart';
import 'package:livehelp/utils/utils.dart';

// ignore_for_file: non_constant_identifier_names
class Server {
  //Tablename
  static const String tableName = "server";
  static const int LOGGED_OUT = 0;
  static const int LOGGED_IN = 1;

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
    'db_twilio_installed': "twilio_installed",
    'db_fb_installed': "fb_installed"
  };
  bool get appendIndexToUrl => _urlhasindex != 0;
  set appendIndexToUrl(bool value) =>
      _urlhasindex = WidgetUtils.checkInt(value)!;

  bool get isLoggedIn => this._loggedin == Server.LOGGED_IN;
  set isLoggedIn(bool val) => this._loggedin = (val) ? 1 : 0;

  bool get userOnline => this._user_online == 1;
  set userOnline(bool val) => this._user_online = (val) ? 1 : 0;

  //set twilioInstalled(bool val) =>

  bool? twilioInstalled = false, fbInstalled = false, extensionsSynced;
  int? id,
      userid,
      _loggedin,
      rememberme,
      soundnotify,
      vibrate,
      all_departments,
      _user_online,
      _urlhasindex;
  String? installationid,
      servername,
      url,
      username,
      password,
      firstname,
      surname,
      job_title,
      operatoremail,
      departments_ids;

  List<Chat> pendingChatList = [];
  List<Chat> activeChatList = [];
  List<Chat> transferChatList = [];
  List<Chat> twilioChatList = [];
  List<Chat> closedChatList = [];
  List<Chat> botChatList = [];
  List<Chat> subjectChatList = [];
  List<User> operatorsChatList = [];

  Server(
      {this.id,
      this.userid,
      bool loggedIn = false,
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
      bool? useronline,
      this.twilioInstalled,
      this.fbInstalled,
      int? urlHasIndex}) {
    _user_online = userOnline ? 1 : 0;
    _urlhasindex = urlHasIndex;
    _loggedin = loggedIn ? 1 : 0;
    pendingChatList = <Chat>[];
    activeChatList = <Chat>[];
    transferChatList = <Chat>[];
    twilioChatList = <Chat>[];
    closedChatList = <Chat>[];
    botChatList = <Chat>[];
    subjectChatList = <Chat>[];
    operatorsChatList = <User>[];
  }

  String? getUrl() => appendIndexToUrl ? url.toString() + "/index.php" : url;

  Server.fromJson(Map<String, dynamic> map)
      : this(
            id: WidgetUtils.checkInt(map[columns['db_id']]),
            userid: WidgetUtils.checkInt(map[columns['db_userid']]),
            loggedIn: map[columns['db_isloggedin']] == 1,
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
            useronline: map[columns['db_user_online']] == 1,
            urlHasIndex: map[columns['db_urlhasindex']],
            twilioInstalled: WidgetUtils.checkInt(map[columns['db_twilio_installed']]) == 1,
            fbInstalled: WidgetUtils.checkInt(map[columns['db_fb_installed']]) == 1
    );

  Map<String, dynamic> toJson() {
    return {
      columns['db_id']: id,
      columns['db_userid']: userid,
      columns['db_installationid']: installationid,
      columns['db_servername']: servername,
      columns['db_url']: url,
      columns['db_username']: username,
      columns['db_password']: password,
      columns['db_isloggedin']: _loggedin,
      columns['db_rememberme']: rememberme,
      columns['db_soundnotify']: soundnotify,
      columns['db_vibrate']: vibrate,
      columns['db_firstname']: firstname,
      columns['db_operatoremail']: operatoremail,
      columns['db_surname']: surname,
      columns['db_job_title']: job_title,
      columns['db_all_departments']: all_departments,
      columns['db_departments_ids']: departments_ids,
      columns['db_user_online']: _user_online,
      columns['db_urlhasindex']: _urlhasindex,
      'twilio_installed': WidgetUtils.checkInt(twilioInstalled),
      'fb_installed': WidgetUtils.checkInt(fbInstalled)
    };
  }

  void addChatsToList(List<dynamic> newChatList, String list) {
    switch (list) {
      case "active":
        activeChatList = _cleanUpLists(activeChatList, newChatList);
        //Sort list by last message time
        activeChatList
            .sort((a, b) => b.last_msg_time.compareTo(a.last_msg_time));
        break;
      case "pending":
        pendingChatList = _cleanUpLists(pendingChatList, newChatList);
        break;
      case "transfer":
        transferChatList = _cleanUpLists(transferChatList, newChatList);
        break;
      case "closed":
        closedChatList = _cleanUpLists(closedChatList, newChatList);
        closedChatList.sort((a, b) => a.id!.compareTo(b.id!));
        break;
      case "bot":
        this.botChatList = _cleanUpLists(this.botChatList, newChatList);
        this.botChatList.sort((a, b) => a.id!.compareTo(b.id!));
        break;
      case "subject":
        this.subjectChatList = _cleanUpLists(this.subjectChatList, newChatList);
        this.subjectChatList.sort((a, b) => a.id!.compareTo(b.id!));
        break;
      case "twilio":
        twilioChatList = _cleanUpLists(twilioChatList, newChatList);
        twilioChatList
            .sort((a, b) => b.last_msg_time.compareTo(a.last_msg_time));
        break;
      case "operators":
        operatorsChatList =
            _cleanUpOperatorsLists(operatorsChatList, newChatList);
        operatorsChatList.sort((a, b) => a.user_id!.compareTo(b.user_id!));
        break;
    }
  }

  List<Chat> _cleanUpLists(
      List<Chat> chatToClean, List<dynamic> listFromServer) {
    var incomingList = listFromServer.map((map) => Chat.fromJson(map));
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
    if (chatToClean.isNotEmpty && incomingList.isNotEmpty) {
      List<int> removedIndices = [];
      for (var chat in chatToClean) {
        if (!incomingList
            .any((map) => map.id == chat.id && map.serverid == chat.serverid)) {
          int index = chatToClean.indexOf(chat);
          removedIndices.add(index);
        }
      }

      //remove the chats
      if (removedIndices.isNotEmpty) {
        removedIndices.sort();
        removedIndices.reversed.toList().forEach(chatToClean.removeAt);
        removedIndices.clear();
      }
    }

    return chatToClean;
  }

  List<User> _cleanUpOperatorsLists(
      List<User> chatToClean, List<dynamic> listFromServer) {
    //developer.log(jsonEncode(listFromServer), name: 'my.app.category');
    //developer.log(jsonEncode(listFromServer), name: '_cleanUpOperatorsLists');

    var incomingList = listFromServer.map((map) => User.fromJson(map));
    for (var map in incomingList) {
      if (chatToClean.any((chat) =>
          chat.user_id == map.user_id && chat.serverid == map.serverid)) {
        int index = chatToClean.indexWhere((chat) =>
            chat.user_id == map.user_id && chat.serverid == map.serverid);
        chatToClean[index] = map;
      } else {
        chatToClean.add(map);
      }
    }

    //remove missing
    if (chatToClean.isNotEmpty && incomingList.isNotEmpty) {
      List<int> removedIndices = List.empty();
      for (var chat in chatToClean) {
        if (!incomingList.any((map) =>
            map.user_id == chat.user_id && map.serverid == chat.serverid)) {
          int index = chatToClean.indexOf(chat);
          removedIndices.add(index);
        }
      }

      //remove the chats
      if (removedIndices.isNotEmpty) {
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
        activeChatList.clear();
        break;
      case 'pending':
        pendingChatList.clear();
        break;
      case 'transfer':
        transferChatList.clear();
        break;
      case 'bot':
        this.botChatList.clear();
        break;
      case 'subject':
        this.subjectChatList.clear();
        break;
      case 'closed':
        closedChatList.clear();
        break;
      case 'twilio':
        twilioChatList.clear();
        break;
      case 'operators':
        operatorsChatList.clear();
        break;
      default:
        break;
    }
  }

  void removeChat(int id, String list) {
    switch (list) {
      case 'active':
        activeChatList.removeWhere((chat) => chat.id == id);
        break;
      case 'pending':
        pendingChatList.removeWhere((chat) => chat.id == id);
        break;
      case 'subject':
        this.subjectChatList.removeWhere((chat) => chat.id == id);
        break;
      case 'bot':
        this.botChatList.removeWhere((chat) => chat.id == id);
        break;
      case 'transfer':
        transferChatList.removeWhere((chat) => chat.id == id);
        break;
    }
  }

  List<Chat> removeMissingFromList(
      List<Chat> toBeCleaned, List<Chat> incomingList) {
    //List<Chat> toBeCleaned = chatToClean;
    List<int> removedIndices = List.empty();

    toBeCleaned.forEach((chat) {
      if (this.id == chat.serverid) {
        if (!incomingList.any((map) => map.id != chat.id)) {
          int index = toBeCleaned.indexOf(chat);
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
