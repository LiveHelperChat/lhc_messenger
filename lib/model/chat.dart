class Chat {
  // Database table name
  static final String tableName = "chat";

  static final Map columns = {
    "db_id": "id",
    "db_serverid": "serverid",
    "db_status": "status",
    "db_nick": "nick",
    "db_email": "email",
    "db_ip": "ip",
    "db_time": "time",
    "db_last_msg_id": "last_msg_id",
    "db_user_id": "user_id",
    "db_country_code": "country_code",
    "db_country_name": "country_name",
    "db_referrer": "referrer",
    "db_uagent": "uagent",
    "db_department_name": "department_name",
    "db_owner": "owner",
    "db_has_unread_messages": "has_unread_messages",
    "db_user_typing_txt": "user_typing_txt",
    "db_last_user_msg_time": "last_user_msg_time",
    "db_phone": "phone",
    "db_user_status_front": "user_status_front",
  };

  int id,
      serverid,
      time,
      last_msg_id,
      status,
      user_id,
      has_unread_messages,
      last_user_msg_time,
      last_op_msg_time,
      user_status_front;
  String nick,
      email,
      ip,
      country_code,
      country_name,
      referrer,
      uagent,
      department_name,
      user_typing_txt,
      owner,
      phone;

  int get last_msg_time {
    if (last_op_msg_time != null && last_user_msg_time != null) {
      if (last_op_msg_time > last_user_msg_time)
        return last_op_msg_time;
      else
        return last_user_msg_time;
    } else if (last_user_msg_time != null) {
      return last_user_msg_time;
    } else
      return last_op_msg_time;
  }

  Chat(
      {this.id,
      this.serverid,
      this.status,
      this.nick,
      this.email,
      this.ip,
      this.time,
      this.last_msg_id,
      this.user_id,
      this.country_code,
      this.country_name,
      this.referrer,
      this.uagent,
      this.department_name,
      this.user_typing_txt,
      this.owner,
      this.has_unread_messages,
      this.last_user_msg_time,
      this.last_op_msg_time,
      this.phone,
      this.user_status_front
      });

  static int checkInt(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.parse(value);
  }

  Chat.fromMap(Map<String, dynamic> map)
      : this(
          id: checkInt(map[columns['db_id']]),
          serverid: checkInt(map[columns['db_serverid']]),
          status: checkInt(map[columns['db_status']]),
          nick: map[columns['db_nick']],
          email: map[columns['db_email']],
          ip: map[columns['db_ip']],
          time: checkInt(map[columns['db_time']]),
          last_msg_id: checkInt(map[columns['db_last_msg_id']]),
          user_id: checkInt(map[columns['db_user_id']]),
          country_code: map[columns['db_country_code']],
          country_name: map[columns['db_country_name']],
          referrer: map[columns['db_referrer']],
          uagent: map[columns['db_uagent']],
          department_name: map[columns['db_department_name']],
          user_typing_txt: map[columns['db_user_typing_txt']],
          owner: map[columns['db_owner']],
          has_unread_messages: checkInt(map[columns['db_has_unread_messages']]),
          last_user_msg_time: checkInt(map['last_user_msg_time']),
          last_op_msg_time: checkInt(map['last_user_msg_time']),
          phone: map['phone'] ?? "",
          user_status_front: map['user_status_front'] ?? 0,
        );

  Map<String, dynamic> toMap() {
    return {
      columns['db_id']: id,
      columns['db_serverid']: serverid,
      columns['db_status']: status,
      columns['db_nick']: nick,
      columns['db_email']: email,
      columns['db_ip']: ip,
      columns['db_time']: time,
      columns['db_last_msg_id']: last_msg_id,
      columns['db_user_id']: user_id,
      columns['db_country_code']: country_code,
      columns['db_country_name']: country_name,
      columns['db_referrer']: referrer,
      columns['db_uagent']: uagent,
      columns['db_department_name']: department_name,
      columns['db_user_typing_txt']: user_typing_txt,
      columns['db_owner']: owner,
      columns['db_has_unread_messages']: has_unread_messages,
      'last_msg_time': last_msg_time,
      columns['db_phone']: phone,
      columns['db_user_status_front']: user_status_front,
    };
  }
}
