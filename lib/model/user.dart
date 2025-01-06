// ignore_for_file: non_constant_identifier_names
class User {
  static final Map columns = {
    "user_id": "user_id",
    "chat_id": "chat_id",
    "db_serverid": "serverid",
    "name_official": "name_official",
    "active_chats": "active_chats",
    "lastactivity_ago": "lastactivity_ago",
    "departments_names": "departments_names",
    "hide_online": "hide_online",
    "last_msg_time": "last_msg_time",
    "last_msg": "last_msg",
    "has_unread": "has_unread",
  };

  User({
    this.user_id,
    this.name,
    this.name_official,
    this.serverid,
    this.chat_id,
    this.surname,
    this.email,
    this.job_title,
    this.all_departments,
    this.departments_ids,
    this.lastactivity_ago,
    this.active_chats,
    this.departments_names,
    this.hide_online,
    this.last_msg_time,
    this.last_msg,
    this.has_unread,
  });

  int? user_id,
      all_departments,
      serverid,
      active_chats,
      hide_online,
      chat_id,
      last_msg_time,
      has_unread;
  String? name,
      surname,
      email,
      job_title,
      departments_ids,
      name_official,
      lastactivity_ago,
      departments_names,
      last_msg;

  User.fromMap(Map<String, dynamic> map)
      : this(
            user_id: checkInt(map['user_id']),
            name: map['name'],
            name_official: map['name_official'] ?? "",
            lastactivity_ago: map['lastactivity_ago'] ?? "",
            active_chats: map['active_chats'] ?? "",
            serverid: map['serverid'] ?? 0,
            chat_id: map['chat_id'] ?? 0,
            last_msg_time: map['last_msg_time'] ?? 0,
            surname: map['surname'],
            email: map['email'],
            job_title: map['job_title'],
            departments_names: map['departments_names'],
            hide_online: map['hide_online'],
            all_departments: checkInt(map['all_departments']),
            departments_ids: map['departments_ids'],
            last_msg: map['last_msg'],
            has_unread: map['has_unread']);

  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'name': name,
      'serverid': serverid,
      'chat_id': chat_id,
      'last_msg_time': last_msg_time,
      'name_official': name_official,
      'surname': surname,
      'email': email,
      'job_title': job_title,
      'all_departments': all_departments,
      'departments_ids': departments_ids,
      'lastactivity_ago': lastactivity_ago,
      'departments_names': departments_names,
      'active_chats': active_chats,
      'hide_online': hide_online,
      'last_msg': last_msg,
      'has_unread': has_unread,
    };
  }

  User.fromJson(Map<String, dynamic> map)
      : this(
            user_id: checkInt(map['user_id']),
            chat_id: checkInt(map['chat_id']),
            last_msg_time: checkInt(map['last_msg_time']),
            name: map['name'],
            name_official: map['name_official'] ?? "",
            serverid: map['serverid'] ?? 0,
            surname: map['surname'],
            email: map['email'],
            job_title: map['job_title'],
            all_departments: checkInt(map['all_departments']),
            active_chats: checkInt(map['active_chats']),
            lastactivity_ago: map['lastactivity_ago'],
            departments_names: map['departments_names'],
            departments_ids: map['departments_ids'],
            hide_online: map['hide_online'],
            last_msg: map['last_msg'],
            has_unread: map['has_unread']);

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'name_official': name_official,
      'chat_id': chat_id,
      'last_msg_time': last_msg_time,
      'serverid': serverid,
      'surname': surname,
      'email': email,
      'job_title': job_title,
      'all_departments': all_departments,
      'departments_ids': departments_ids,
      'lastactivity_ago': lastactivity_ago,
      'departments_names': departments_names,
      'active_chats': active_chats,
      'hide_online': hide_online,
      'last_msg': last_msg,
      'has_unread': has_unread,
    };
  }

  User copyWith(
      {int? user_id,
      int? all_departments,
      int? serverid,
      int? active_chats,
      int? hide_online,
      int? chat_id,
      int? last_msg_time,
      int? has_unread,
      String? name,
      String? surname,
      String? email,
      String? job_title,
      String? departments_ids,
      String? name_official,
      String? lastactivity_ago,
      String? departments_names,
      String? last_msg}) {
    return User(
        serverid: serverid ?? this.serverid,
        user_id: user_id ?? this.user_id,
        all_departments: all_departments ?? this.all_departments,
        active_chats: active_chats ?? this.active_chats,
        hide_online: hide_online ?? this.hide_online,
        chat_id: chat_id ?? this.chat_id,
        last_msg_time: last_msg_time ?? this.last_msg_time,
        has_unread: has_unread ?? this.has_unread,
        name: name ?? this.name,
        surname: surname ?? this.surname,
        email: email ?? this.email,
        job_title: job_title ?? this.job_title,
        departments_ids: departments_ids ?? this.departments_ids,
        name_official: name_official ?? this.name_official,
        lastactivity_ago: lastactivity_ago ?? this.lastactivity_ago,
        departments_names: departments_names ?? this.departments_names,
        last_msg: last_msg ?? this.last_msg);
  }

  static int? checkInt(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.parse(value);
  }
}
