import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../common/constants.dart';
import '../common/response.dart';
import '../models/user.dart';
import '../utils/http.dart';
import 'mai2_preview.dart'; // 导入Mai2Preview

class Mai2Provider {
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

  static Future<CommonResponse<UserModel?>> getUserPreview({
    required int userID,
  }) async {
    final data = jsonEncode({'userId': userID});
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

      String message = "";
      bool success = false;
      UserModel? user;
      final responseBody = await response.toBytes();

      try {
        message = aesDecrypt(Uint8List.fromList(zlib.decode(responseBody)));
        final json = jsonDecode(message);
        if (json['userId'] == null || json['userName'] == null) {
          success = false;
          message = "用户为空，可能未注册";
        } else {
          user = UserModel.fromJson(json);
          success = true;
        }
      } catch (e) {
        success = false;
        message = utf8.decode(responseBody);
      }

      return CommonResponse(success: success, data: user, message: message);
    } catch (e) {
      return CommonResponse(success: false, data: null, message: e.toString());
    }
  }

  static Stream<CommonResponse<Null>> logout(int userId, String startTime, RxBool isCancelling) async* {
    DateTime currentDateTime = parseDateTime(startTime);

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        if (isCancelling.value) {
          yield CommonResponse(success: false, message: "操作已取消", data: null);
          return;
        }
        String chipId = "A63E-01E${Random().nextInt(999999999).toString().padLeft(8, '0')}";

        final String userAgent = '${obfuscate('UserLogoutApiMaimaiChn')}#$userId';
        final String data = jsonEncode({
          "userId": userId,
          "accessCode": "",
          "regionId": "",
          "placeId": "",
          "clientId": chipId,
          "dateTime": (currentDateTime.millisecondsSinceEpoch ~/ 1000).toString(), // 转换为时间戳
          "type": 1
        });

        // 打印发送的数据包内容
        print("Sending request body: ${jsonEncode(data)}");

        final body = zlib.encode(aesEncrypt(data.toString()));
        maiHeader['User-Agent'] = userAgent;
        maiHeader['Content-Length'] = body.length.toString();

        try {
          // 打印当前的时间戳
          print("Sending request with timestamp: ${(currentDateTime.millisecondsSinceEpoch ~/ 1000)}");

          final response = await Mai2HttpClient.post(
            Uri.parse('https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('UserLogoutApiMaimaiChn')}'),
            maiHeader,
            body,
          );

          bool success = false;
          String message = "未知错误";

          if (response.body.isEmpty) {
            message = "服务器返回为空";
            success = false;
            yield CommonResponse(success: success, message: message, data: null);
            continue; // 继续发送下一次请求
          }

          try {
            message = aesDecrypt(Uint8List.fromList(zlib.decode(response.body)));

            final json = jsonDecode(message);
            success = json['returnCode'] == 0;

            // 打印解密后的数据包内容
            print("Received decrypted response body: $message");

            if (success) {
              yield CommonResponse(success: true, message: "任务完成", data: null);
              return;
            } else {
              yield CommonResponse(success: false, message: "进度：${i * 900 + j + 1}/3600", data: null);
            }
          } catch (e) {
            print("解码或解密失败，重新发送请求: $e");
            continue; // 继续发送下一次请求
          }

          await Future.delayed(Duration(milliseconds: 100));
        } catch (e) {
          yield CommonResponse(success: false, message: e.toString(), data: null);
          return;
        }

        currentDateTime = currentDateTime.add(Duration(seconds: 1));
      }

      // 每发送5次请求后调用Mai2Preview的UserLoginIn
      final loginCheck = await Mai2Preview.UserLoginIn(userID: userId, timestamp: (currentDateTime.millisecondsSinceEpoch ~/ 1000).toString());
      if (loginCheck['isLogin'] == false) {
        yield CommonResponse(success: false, message: "登出成功，该机台时间戳为${(currentDateTime.millisecondsSinceEpoch ~/ 1000)}", data: null);
        return;
      }
    }

    yield CommonResponse(success: false, message: "所有请求均未返回预期值", data: null);
  }

  static DateTime parseDateTime(String time) {
    final now = DateTime.now();
    final dateTimeString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $time";
    print("DateTime String: $dateTimeString");

    final dateTime = DateFormat("yyyy-MM-dd HH:mm").parse(dateTimeString);
    print("Parsed DateTime: $dateTime");

    return dateTime;
  }

  static String formatDateTime(DateTime dateTime) {
    final formattedDateTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
    return formattedDateTime;
  }
}
