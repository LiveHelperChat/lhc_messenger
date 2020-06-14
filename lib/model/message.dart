class Message {
  static final String tableName = "message";
  static final Map<String, String> columns = {
    "db_id": "id",
    "db_time": "time",
    "db_chat_id": "chat_id",
    "db_user_id": "user_id",
    "db_msg": "msg",
    "db_name_support": "name_support"
  };

  int id, chat_id, user_id, time;
  String msg, name_support;

  Message(
      {this.id,
      this.chat_id,
      this.user_id,
      this.time,
      this.msg,
      this.name_support});

  static int checkInt(dynamic value) {
    if (value == null) return null;

    return value is int ? value : int.parse(value);
  }

  Message.fromMap(Map<String, dynamic> map)
      : this(
            id: checkInt(map[columns['db_id']]),
            chat_id: checkInt(map[columns['db_chat_id']]),
            time: checkInt(map[columns['db_time']]),
            user_id: checkInt(map[columns['db_user_id']]),
            msg: map[columns['db_msg']],
            name_support: map[columns['db_name_support']]);

  Map<String, dynamic> toMap() {
    return {
      columns['db_id']: id,
      columns['db_chat_id']: chat_id,
      columns['db_time']: time,
      columns['db_user_id']: user_id,
      columns['db_msg']: msg,
      columns['db_name_support']: name_support
    };
  }
}
