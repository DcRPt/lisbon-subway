import 'package:http/http.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';

class HttpClient {

  final client = HttpWithMiddleware.build(
      middlewares: [
        HttpLogger(logLevel: LogLevel.BASIC),
      ]
  );

  Future<Response> get({required String url, Map<String,String>? headers}) {
    return client.get(Uri.parse(url), headers: headers);
  }

}