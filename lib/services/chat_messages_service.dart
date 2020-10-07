import 'package:http/http.dart' as http;
import 'package:livehelp/model/model.dart';
import 'package:livehelp/services/server_api_client.dart';

class ChatMessagesService extends ServerApiClient {
  http.Client httpClient;
  ChatMessagesService({this.httpClient}) : super(httpClient: httpClient);



}
