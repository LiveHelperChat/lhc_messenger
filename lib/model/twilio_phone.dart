// ignore_for_file: non_constant_identifier_names
class TwilioPhone {
  String? phone, account_sid, auth_token, base_phone, originator;
  int? id, dep_id, chat_timeout;

  TwilioPhone(
      {this.id,
        this.phone,
        this.account_sid,
        this.auth_token,
        this.base_phone,
        this.originator,
        this.dep_id,
        this.chat_timeout});

  static int? checkInt(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.parse(value);
  }

  TwilioPhone.fromMap(Map<String, dynamic> map)
      : this(
    id: checkInt(map['id']),
    dep_id: checkInt(map['dep_id']),
    chat_timeout: checkInt(map['chat_timeout']),
    phone: map['phone'] ?? "",
    account_sid: map['account_sid'] ?? "",
    auth_token: map['auth_token'] ?? "",
    base_phone: map['base_phone'] ?? "",
    originator: map['originator'] ?? "",
  );

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "dep_id": dep_id,
      "chat_timeout": chat_timeout,
      "phone": phone,
      "account_sid": account_sid,
      "auth_token": auth_token,
      "base_phone": base_phone,
      "originator": originator,
    };
  }
}
