// ignore_for_file: non_constant_identifier_names
class Department {
  Department(
      {this.id,
        this.disabled,
        this.online_hours_active,
        this.name,
        this.email,
        this.mod_start_hour,
        this.mod_end_hour,
        this.tud_start_hour,
        this.tud_end_hour,
        this.wed_start_hour,
        this.wed_end_hour,
        this.thd_start_hour,
        this.thd_end_hour,
        this.frd_start_hour,
        this.frd_end_hour,
        this.sad_start_hour,
        this.sad_end_hour,
        this.sud_start_hour,
        this.sud_end_hour});

  int? id;
  bool? disabled, online_hours_active;
  String? name,
      email,
      mod_start_hour,
      mod_end_hour,
      tud_start_hour,
      tud_end_hour,
      wed_start_hour,
      wed_end_hour,
      thd_start_hour,
      thd_end_hour,
      frd_start_hour,
      frd_end_hour,
      sad_start_hour,
      sad_end_hour,
      sud_start_hour,
      sud_end_hour;

  bool get sundayActive =>
      _timeAlreadySet(this.sud_start_hour!, this.sud_end_hour!);
  bool get mondayActive =>
      _timeAlreadySet(this.mod_start_hour!, this.mod_end_hour!);
  bool get tuesdayActive =>
      _timeAlreadySet(this.tud_start_hour!, this.tud_end_hour!);
  bool get wednesdayActive =>
      _timeAlreadySet(this.wed_start_hour!, this.wed_end_hour!);
  bool get thursdayActive =>
      _timeAlreadySet(this.thd_start_hour!, this.thd_end_hour!);
  bool get fridayActive =>
      _timeAlreadySet(this.frd_start_hour!, this.frd_end_hour!);
  bool get saturdayActive =>
      _timeAlreadySet(this.sad_start_hour!, this.sad_end_hour!);

  bool _timeAlreadySet(String from, String to) {
    if (to != '') {
      return int.parse(from) >= 0 || int.parse(to) >= 0;
    } else {
      return false;
    }
  }

  Department.fromMap(Map<String, dynamic> map)
      : this(
      id: checkInt(map['id']),
      disabled: map['disabled'] == 1,
      name: map['name'],
      email: map['email'],
      online_hours_active: checkInt(map['online_hours_active']) == 1,
      mod_start_hour: map['mod_start_hour'],
      mod_end_hour: map['mod_end_hour'],
      tud_start_hour: map['tud_start_hour'],
      tud_end_hour: map['tud_end_hour'],
      wed_start_hour: map['wed_start_hour'],
      wed_end_hour: map['wed_end_hour'],
      thd_start_hour: map['thd_start_hour'],
      thd_end_hour: map['thd_end_hour'],
      frd_start_hour: map['frd_start_hour'],
      frd_end_hour: map['frd_end_hour'],
      sad_start_hour: map['sad_start_hour'],
      sad_end_hour: map['sad_end_hour'],
      sud_start_hour: map['sud_start_hour'],
      sud_end_hour: map['sud_end_hour']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'online_hours_active': online_hours_active! ? '1' : '0',
      'name': name,
      'email': email,
      'disabled': disabled,
      'mod_start_hour': mod_start_hour,
      'mod_end_hour': mod_end_hour,
      'tud_start_hour': tud_start_hour,
      'tud_end_hour': tud_end_hour,
      'wed_start_hour': wed_start_hour,
      'wed_end_hour': wed_end_hour,
      'thd_start_hour': thd_start_hour,
      'thd_end_hour': thd_end_hour,
      'frd_start_hour': frd_start_hour,
      'frd_end_hour': frd_end_hour,
      'sad_start_hour': sad_start_hour,
      'sad_end_hour': sad_end_hour,
      'sud_start_hour': sud_start_hour,
      'sud_end_hour': sud_end_hour,
    };
  }

  Map<String, dynamic> toMapWorkHours() {
    return {
      'id': '$id',
      'online_hours_active': online_hours_active! ? '1' : '0',
      'mod_start_hour': mod_start_hour,
      'mod_end_hour': mod_end_hour,
      'tud_start_hour': tud_start_hour,
      'tud_end_hour': tud_end_hour,
      'wed_start_hour': wed_start_hour,
      'wed_end_hour': wed_end_hour,
      'thd_start_hour': thd_start_hour,
      'thd_end_hour': thd_end_hour,
      'frd_start_hour': frd_start_hour,
      'frd_end_hour': frd_end_hour,
      'sad_start_hour': sad_start_hour,
      'sad_end_hour': sad_end_hour,
      'sud_start_hour': sud_start_hour,
      'sud_end_hour': sud_end_hour,
    };
  }

  static int? checkInt(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.parse(value);
  }
}
