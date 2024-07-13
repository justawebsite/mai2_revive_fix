import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../common/constants.dart';

class Mai2Preview {
  static LinkedHashMap<String, String> maiHeader = LinkedHashMap<String, String>.from({
    "Content-Type": "application/json",
    "User-Agent": "",
    "charset": "UTF-8",
    "Mai-Encoding": "1.30",
    "Content-Encoding": "deflate",
    "Content-Length": "",
    "Host": AppConstants.mai2Host,
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

  static Future<Map<String, dynamic>> UserLoginIn({
    required int userID,
    required String timestamp,
  }) async {
    final data = jsonEncode({
      'userId': userID,
      'segaIdAuthKey': "",
    });
    final body = zlib.encode(aesEncrypt(data));
    maiHeader['User-Agent'] = "${obfuscate('GetUserPreviewApiMaimaiChn')}#$userID";
    maiHeader['Content-Length'] = body.length.toString();

    try {
      final client = HttpClient();

      final request = await client.postUrl(
        Uri.parse('https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('GetUserPreviewApiMaimaiChn')}'),
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

        return json;
      } catch (e) {
        throw Exception("解析数据出错: $e");
      }
    } catch (e) {
      throw Exception("请求出错: $e");
    }
  }
}
