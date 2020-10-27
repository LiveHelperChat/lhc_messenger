// ignore_for_file: non_constant_identifier_names
class User {
  User(
      {this.user_id,
      this.name,
      this.surname,
      this.email,
      this.job_title,
      this.all_departments,
      this.departments_ids});

  int user_id, all_departments;
  String name, surname, email, job_title, departments_ids;

  User.fromMap(Map<String, dynamic> map)
      : this(
            user_id: checkInt(map['db_userid']),
            name: map['name'],
            surname: map['surname'],
            email: map['email'],
            job_title: map['job_title'],
            all_departments: checkInt(map['all_departments']),
            departments_ids: map['departments_ids']);

  Map<String, dynamic> toMap() {
    return {
      'db_userid': user_id,
      'name': name,
      'surname': surname,
      'email': email,
      'job_title': job_title,
      'all_departments': all_departments,
      'departments_ids': departments_ids,
    };
  }

  static int checkInt(dynamic value) {
    if (value == null) return null;
    return value is int ? value : int.parse(value);
  }
}
