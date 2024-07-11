import 'dart:collection';
import 'dart:io';

class Mai2HttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;

  Mai2HttpResponse(this.statusCode, this.headers, this.body);
}  //封装 HTTP 响应，包括状态码、头信息和响应体。

class Mai2HttpClient {
  static Future<Mai2HttpResponse> post(
      Uri uri, LinkedHashMap<String, String> headers, List<int> body) async {
    final socket = await SecureSocket.connect(uri.host, uri.port);  //通过 SecureSocket.connect 方法与服务器建立安全的套接字连接。

    final request = 'POST ${uri.path} HTTP/1.1\r\n'
        '${headers.entries.map((e) => '${e.key}: ${e.value}\r\n').join()}'
        '\r\n';  //构建 HTTP 请求头并将其写入套接字。

    socket.add(request.codeUnits);  //将请求头发送到服务器。
    socket.add(body);  //将请求体发送到服务器。

    await socket.flush();  //确保所有数据被发送。

    var responseCode = "";
    final response = StringBuffer();
    final responseHeaders = <String, String>{};
    final responseBody = <int>[];  //初始化用于存储响应状态码、响应头和响应体的变量。

    socket.listen((data) {  //监听响应数据的传输。
      response.write(String.fromCharCodes(data));  //将响应数据写入 StringBuffer 并解析响应头和响应体。
      final responseString = response.toString();
      final responseParts = responseString.split('\r\n\r\n');  

      if (responseParts.length == 2) {
        responseCode = responseParts[0];
        responseBody.addAll(responseParts[1].codeUnits);
      } else if (responseParts.length == 1) {
        responseCode = responseParts[0];
      }

      if (responseCode.isNotEmpty) {
        final responseLines = responseCode.split('\r\n');
        for (var i = 1; i < responseLines.length; i++) {
          final header = responseLines[i].split(':');
          if (header.length == 2) {
            responseHeaders[header[0].trim()] = header[1].trim();
          }
        }
      }

      if (responseHeaders.containsKey('Content-Length')) {
        final contentLength = int.parse(responseHeaders['Content-Length']!);
        if (responseBody.length >= contentLength) {
          socket.close();
        }
      }
    });

    await socket.done;

    return Mai2HttpResponse(
      int.parse(responseCode.split(' ')[1]),
      responseHeaders,
      responseBody,
    ); //解析响应状态码，并返回一个包含状态码、响应头和响应体的 Mai2HttpResponse 对象
  }
}
