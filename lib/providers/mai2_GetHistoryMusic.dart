import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../common/constants.dart';
import '../common/response.dart';

class Mai2GetMusic {
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

  static Future<CommonResponse<Map<String, dynamic>>> GetData({
    required int userID,
    int nextIndex = 0,
    List<Map<String, dynamic>> collectedData = const [],
  }) async {
    final data = jsonEncode({
      "userId": userID,
      "nextIndex": nextIndex,
      "maxCount": 50,
    });
    final body = zlib.encode(aesEncrypt(data));

    maiHeader['User-Agent'] =
    "${obfuscate('GetUserMusicApiMaimaiChn')}#$userID";
    maiHeader['Content-Length'] = body.length.toString();

    try {
      final client = HttpClient();

      final request = await client.postUrl(
        Uri.parse(
            'https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('GetUserMusicApiMaimaiChn')}'),
      );

      request.headers.clear();
      for (final key in maiHeader.keys) {
        request.headers.add(key, maiHeader[key]!, preserveHeaderCase: true);
      }

      request.add(body);

      await request.flush();

      final response = await request.close();

      String message = "";
      bool success = false;
      Map<String, dynamic> jsonData = {};

      final responseBody = await response.toBytes();

      try {
        message = aesDecrypt(Uint8List.fromList(zlib.decode(responseBody)));
        jsonData = jsonDecode(message);

        print('music data message: $message');

        if (jsonData['userMusicList'] == null) {
          print('userMusicList 为空或不存在');
          return CommonResponse(success: false, data: {}, message: 'userMusicList 为空或不存在');
        }

        List<Map<String, dynamic>> userMusicList = List<Map<String, dynamic>>.from(jsonData['userMusicList']);
        collectedData = List<Map<String, dynamic>>.from(collectedData)..addAll(userMusicList);

        success = true;

        if (jsonData['nextIndex'] != 0) {
          return await GetData(
            userID: userID,
            nextIndex: jsonData['nextIndex'],
            collectedData: collectedData,
          );
        }
      } catch (e) {
        print("music 解码或解密失败: $e");
        return await GetData(userID: userID, nextIndex: nextIndex, collectedData: collectedData);
      }

      return CommonResponse(success: success, data: {'userMusicList': collectedData}, message: message);
    } catch (e) {
      return CommonResponse(success: false, data: {}, message: "请求出错: $e");
    }
  }
}
