import 'package:equatable/equatable.dart';

// ignore_for_file: non_constant_identifier_names
class Chat extends Equatable {
  // Database table name
  static const String tableName = "chat";

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
    "db_subject_front": "subject_front",
    "db_aicon_front": "aicon_front"
  };

  final int? id,
      serverid,
      time,
      last_msg_id,
      status,
      user_id,
      has_unread_messages,
      last_user_msg_time,
      last_op_msg_time,
      user_status_front;
  final String? nick,
      email,
      ip,
      country_code,
      country_name,
      referrer,
      uagent,
      department_name,
      user_typing_txt,
      owner,
      phone,
      subject_front,
      aicon_front;


  int get last_msg_time {
    if (last_op_msg_time != null && last_user_msg_time != null) {
      if (last_op_msg_time! > last_user_msg_time!) {
        return last_op_msg_time!;
      } else {
        return last_user_msg_time!;
      }
    } else if (last_user_msg_time != null) {
      return last_user_msg_time!;
    } else if (last_op_msg_time != null) {
      return last_op_msg_time!;
    } else
      return 0;
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
        this.user_status_front,
        this.subject_front,
        this.aicon_front,
      });

  Chat copyWith(
      {int? id,
        int? serverid,
        String? status,
        String? nick,
        String? email,
        String? ip,
        int? time,
        int? last_msg_id,
        int? user_id,
        String? country_code,
        String? country_name,
        String? referrer,
        String? uagent,
        String? department_name,
        String? user_typing_txt,
        String? owner,
        has_unread_messages,
        last_user_msg_time,
        last_op_msg_time,
        String? phone,
        String? user_status_front,
        String? subject_front,
        String? aicon_front
      }) {
    return Chat(
        id: id ?? this.id,
        serverid: serverid ?? this.serverid,
        status: status !=null ? this.status:null,
        nick: nick ?? this.nick,
        email: email ?? this.email,
        ip: ip ?? this.ip,
        time: time ?? this.time,
        last_msg_id: last_msg_id ?? this.last_msg_id,
        user_id: user_id ?? this.user_id,
        country_code: country_code ?? this.country_code,
        country_name: country_name ?? this.country_name,
        referrer: referrer ?? this.referrer,
        uagent: uagent ?? this.uagent,
        department_name: department_name ?? this.department_name,
        user_typing_txt: user_typing_txt ?? this.user_typing_txt,
        owner: owner ?? this.owner,
        has_unread_messages: has_unread_messages ?? this.has_unread_messages,
        last_user_msg_time: last_user_msg_time ?? this.last_user_msg_time,
        last_op_msg_time: last_op_msg_time ?? this.last_op_msg_time,
        phone: phone ?? this.phone,
        user_status_front: user_status_front !=null ? this.user_status_front : null,
        subject_front: subject_front ?? this.subject_front,
        aicon_front: aicon_front ?? this.aicon_front
    );
  }

  static int? checkInt(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.parse(value);
  }

  Chat.fromJson(Map<dynamic, dynamic> map)
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
    last_op_msg_time: checkInt(map['last_op_msg_time']),
    phone: map['phone'] ?? "",
    user_status_front: map['user_status_front'] ?? 0,
    subject_front: map['subject_front'] ?? "",
    aicon_front: map['aicon_front'] ?? "",
  );

  Map<String, dynamic> toJson() {
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
      columns['db_subject_front']: subject_front,
      columns['db_aicon_front']: aicon_front,
    };
  }

  @override
  List<Object?> get props => [
    id,
    serverid,
    status,
    nick,
    email,
    ip,
    time,
    last_msg_id,
    user_id,
    country_code,
    country_name,
    referrer,
    uagent,
    department_name,
    user_typing_txt,
    owner,
    has_unread_messages,
    last_user_msg_time,
    last_op_msg_time,
    phone,
    user_status_front,
    subject_front,
    aicon_front,
  ];
}
