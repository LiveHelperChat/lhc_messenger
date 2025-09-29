// ignore_for_file: non_constant_identifier_names
class Message {
  static final String tableName = "message";
  static final Map<String, String> columns = {
    "db_id": "id",
    "db_time": "time",
    "db_chat_id": "chat_id",
    "db_user_id": "user_id",
    "db_msg": "msg",
    "db_name_support": "name_support",
    "db_is_owner": "is_owner",
    "db_del_st": "del_st"
  };

  int? id, chat_id, user_id, time, is_owner;
  String? msg, name_support, del_st;

  Message({
    this.id,
    this.chat_id,
    this.user_id,
    this.time,
    this.msg,
    this.name_support,
    this.del_st,
    this.is_owner,
  });

  static int? checkInt(dynamic value) {
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
            name_support: map[columns['db_name_support']],
            del_st: map[columns['db_del_st']],
            is_owner: map[columns['db_is_owner']] ?? 0);

  Map<String?, dynamic> toMap() {
    return {
      columns['db_id']: id,
      columns['db_chat_id']: chat_id,
      columns['db_time']: time,
      columns['db_user_id']: user_id,
      columns['db_msg']: msg,
      columns['db_name_support']: name_support,
      columns['db_del_st']: del_st,
      columns['db_is_owner']: is_owner
    };
  }

  @override
  String toString() {
    return 'Message{id: $id, chat_id: $chat_id, user_id: $user_id, time: $time, msg: $msg, name_support: $name_support, del_st: $del_st, is_owner: $is_owner}';
  }
}
