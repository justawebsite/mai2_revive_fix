import 'dart:collection';
import 'dart:convert';
//import 'dart:io';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../common/constants.dart';

class MakeOption {
  static LinkedHashMap<String, String> maiHeader = LinkedHashMap<String, String>.from({
    "Content-Type": "application/json",
    "User-Agent": "",
    "Mai-Encoding": "1.40",
    "Accept-Encoding": "",
    "charset": "UTF-8",
    "Content-Length": "",
    "Content-Encoding": "deflate",
    "Host": AppConstants.mai2Host,
    "Expect": "100-continue",
  });

  static String obfuscate(String srcStr) {
    final m = md5.convert(('$srcStr${AppConstants.mai2Salt}').codeUnits);
    return m.toString();
  }

  static Uint8List aesEncrypt(String data) {
    final key = Key.fromUtf8(AppConstants.aesKey);
    final iv = IV.fromUtf8(AppConstants.aesIV);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.encrypt(data, iv: iv).bytes;
  }

  static String aesDecrypt(Uint8List data) {
    final key = Key.fromUtf8(AppConstants.aesKey);
    final iv = IV.fromUtf8(AppConstants.aesIV);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt(Encrypted(data), iv: iv);
  }

  static Future<Map<String, dynamic>> UserOption({
    required int userID,
  }) async {
    final data = jsonEncode({
      'userId': userID
    });
    final body = zlib.encode(aesEncrypt(data));
    maiHeader['User-Agent'] = "${obfuscate('GetUserOptionApiMaimaiChn')}#$userID";
    maiHeader['Content-Length'] = body.length.toString();

    try {
      final client = HttpClient();

      final request = await client.postUrl(
        Uri.parse('https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('GetUserOptionApiMaimaiChn')}'),
      );

      request.headers.clear();
      for (final key in maiHeader.keys) {
        request.headers.add(key, maiHeader[key]!, preserveHeaderCase: true);
      }

      request.add(body);

      await request.flush();

      final response = await request.close();

      final responseBody = await response.toBytes();

      // 打印调试信息
      print('Response body (compressed and encrypted): $responseBody');

      try {
        final decodedBytes = zlib.decode(responseBody);
        final message = aesDecrypt(Uint8List.fromList(decodedBytes));
        final json = jsonDecode(message);

        // 打印解码后的信息
        print('Decoded and decrypted message: $message');

        // 对JSON数据进行重构或添加新内容
        final modifiedJson = _modifyJsonData(json);

        return modifiedJson;
      } catch (e) {
        throw Exception("解析数据出错: $e");
      }
    } catch (e) {
      print ("$e");
      // 重试请求
      return await UserOption(userID: userID);
    }
  }

  static Map<String, dynamic> _modifyJsonData(Map<String, dynamic> json) {
    return json;
  }
}
