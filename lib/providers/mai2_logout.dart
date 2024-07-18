import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:get/get_rx/get_rx.dart';
import '../common/constants.dart';
import '../common/response.dart';
import 'mai2_preview.dart'; // 导入Mai2Preview

class Mai2Logout {
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

  static Future<CommonResponse<Null>> logout(int userId, RxBool isCancelling, int timestamp) async {
    final String userAgent = '${obfuscate('UserLogoutApiMaimaiChn')}#$userId';
    final Map<String, dynamic> data = {
      "userId": userId,
      "accessCode": "",
      "regionId": 24,
      "placeId": 1545,
      "clientId": "A63E01C2626",
      "dateTime": timestamp,
      "type": 4
    };

    // 打印发送的数据包内容
    print("Sending request body: ${jsonEncode(data)}");

    final body = zlib.encode(aesEncrypt(jsonEncode(data)));
    maiHeader['User-Agent'] = userAgent;
    maiHeader['Content-Length'] = body.length.toString();

    try {
      // 打印当前的时间戳
      print("Sending request with timestamp: ${data['dateTime']}");
      final client = HttpClient();

      final request = await client.postUrl(
        Uri.parse('https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('UserLogoutApiMaimaiChn')}'),
      );

      request.headers.clear(); // 清空http请求头
      for (final key in maiHeader.keys) {
        request.headers.add(key, maiHeader[key]!, preserveHeaderCase: true);
      } // 使用 for 循环遍历之前在 maiHeader 中定义的请求头键值，对于 maiHeader 的每一个键（key），从 maiHeader 中获取对应的值（maiHeader[key]!），并使用 request.headers.add 方法将其添加到请求的头部，参数 preserveHeaderCase: true 确保在添加头信息时保持原有的大小写格式。

      request.add(body); // 将准备好的请求包“body”添加到http请求中

      await request.flush(); // 确保数据包发送

      final response = await request.close();

      String message = "未知错误";

      final responseBody = await response.toBytes();

      try {
        message = aesDecrypt(Uint8List.fromList(zlib.decode(responseBody)));

        final json = jsonDecode(message);
        final returnCode = json['returnCode'];

        print("接收: $json");

        if (returnCode == 1) {
          bool loginCheckSuccess = false;

          while (!loginCheckSuccess) {
            final loginCheck = await Mai2Preview.UserLoginIn(userID: userId);
            loginCheckSuccess = loginCheck['isLogin'] == false;

            if (loginCheckSuccess) {
              return CommonResponse(success: true, message: "登出成功", data: null);
            } else if (loginCheck['isLogin'] == true) {
              return CommonResponse(success: false, message: "登出失败：当前时间戳为$timestamp，可尝试手动登出", data: null);
            } else {
              await Future.delayed(Duration(milliseconds: 100));
            }
          }
        } else if (returnCode == 0) {
          return CommonResponse(success: false, message: "登出失败：当前时间戳为$timestamp，可尝试手动登出", data: null);
        }
      } catch (e) {
        print("解码或解密失败: $e");
        // 重试请求
        return await logout(userId, isCancelling, timestamp);
      }

      await Future.delayed(Duration(milliseconds: 100));
    } catch (e) {
      return CommonResponse(success: false, message: e.toString(), data: null);
    }

    return CommonResponse(success: false, message: "登出失败", data: null);
  }
}
