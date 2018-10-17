import 'package:meta/meta.dart';

import 'package:livehelp/model/user.dart';
import 'package:livehelp/model/chat.dart';

class Server {

  //Tablename
  static final String tableName = "server";
  static final int LOGGED_OUT = 0;
  static final int LOGGED_IN = 1;



  //Columns
  static final Map columns = {'db_id':"id","db_userid":"userid",
  'db_installationid':"installationid",'db_servername':"servername",'db_url':"url",
  'db_urlhasindex':"urlhasindex",'db_isloggedin':"isloggedin",'db_rememberme':"rememberme",'db_soundnotify':"soundnotify",'db_vibrate':"vibrate",'db_username':"username",'db_password':"password", 'db_firstname':"firstname",'db_surname':"surname",'db_operatoremail':"email",'db_job_title':"job_title",'db_all_departments':"all_departments",'db_departments_ids':"departments_ids","db_user_online":"user_online",'db_fcmtoken':"fcm_token"
  };

   bool urlhasindex;
   int id,userid, isloggedin, rememberme, soundnotify, vibrate,all_departments,user_online;
   String installationid,
      servername,
      url,
      username,
      password,
      firstname,surname,job_title,operatoremail,departments_ids;
     //  fcm_token;




  Server(
      {this.id,
        this.userid,
      this.urlhasindex =true,
      this.isloggedin =0,
      this.rememberme =0,
      this.soundnotify =1,
      this.vibrate =0,
      this.installationid,
      this.servername,
      this.url,
      this.username,
      this.password,
      this.firstname,this.surname,this.job_title,this.all_departments,this.departments_ids,
      this.operatoremail,this.user_online});

  String getUrl ()=>  urlhasindex ? url+"/index.php" : url;

  static int checkInt(dynamic value){
     if(value == null) return null;
      return value is int ? value : int.parse(value);
  }

  Server.fromMap(Map<String, dynamic> map)
      : this(
    id:  checkInt(map[columns['db_id']]),
    userid:checkInt(map[columns['db_userid']]),
    urlhasindex: map[columns['db_urlhasindex']] == 1,
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
      user_online: map[columns['db_user_online']]
  );

  Map<String, dynamic> toMap() {
    return {
      columns['db_id']: id,
      columns['db_userid']:userid,
      columns['db_installationid']: installationid,
      columns['db_servername']: servername,
      columns['db_url']:url,
      columns['db_urlhasindex']: urlhasindex,
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
      columns['db_user_online']: user_online
    };
  }

}
