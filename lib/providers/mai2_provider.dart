import 'dart:collection';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:intl/intl.dart';

import '../common/constants.dart';
import '../common/response.dart';
import '../models/user.dart';
import '../utils/http.dart';

class Mai2Provider {
  static LinkedHashMap<String, String> maiHeader =
  LinkedHashMap<String, String>.from({
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
    final data = jsonEncode({
      'userId': userID,
    });
    final body = zlib.encode(aesEncrypt(data.toString()));

    maiHeader['User-Agent'] =
    "${obfuscate('GetUserPreviewApiMaimaiChn')}#$userID";
    maiHeader['Content-Length'] = body.length.toString();

    try {
      final client = HttpClient();

      final request = await client.postUrl(
        Uri.parse(
            'https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('GetUserPreviewApiMaimaiChn')}'),
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

      return CommonResponse(
        success: success,
        data: user,
        message: message,
      );
    } catch (e) {
      return CommonResponse(
        success: false,
        data: null,
        message: e.toString(),
      );
    }
  }

  static Future<CommonResponse<Null>> logout(int userId, String startTime) async {
    final startTimestamp = convertToUnixTimestamp(startTime);

    for (int i = 0; i < 3600; i++) {
      final String userAgent = '${obfuscate('UserLogoutApiMaimaiChn')}#$userId';
      final String data = jsonEncode({
        "userId": userId,
        "clientId": "A63E01C2626",
        "dateTime": startTimestamp + i,
        "type": 1
      });

      final body = zlib.encode(aesEncrypt(data.toString()));

      maiHeader['User-Agent'] = userAgent;
      maiHeader['Content-Length'] = body.length.toString();

      try {
        final response = await Mai2HttpClient.post(
          Uri.parse(
              'https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('UserLogoutApiMaimaiChn')}'),
          maiHeader,
          body,
        );

        bool success = false;
        String message = "未知错误";

        if (response.body.isEmpty) {
          message = "服务器返回为空";
          success = false;
          return CommonResponse(success: success, message: message, data: null);
        }

        try {
          message = aesDecrypt(Uint8List.fromList(zlib.decode(response.body)));
          final json = jsonDecode(message);
          success = json['returnCode'] == 1;
          print("进度：${i + 1}/3600");
          if (success) {
            return CommonResponse(success: true, message: "任务完成", data: null);
          }
        } catch (e) {
          success = false;
          message = utf8.decode(response.body);
        }

        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        return CommonResponse(success: false, message: e.toString(), data: null);
      }
    }

    return CommonResponse(success: false, message: "所有请求均未返回预期值", data: null);
  }

  static int convertToUnixTimestamp(String time) {
    final now = DateTime.now();
    final dateTimeString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $time";
    print("DateTime String: $dateTimeString"); // 调试输出

    final dateTime = DateFormat("yyyy-MM-dd HH:mm").parse(dateTimeString);
    int timestamp = dateTime.millisecondsSinceEpoch ~/ 1000;
    print("Unix Timestamp: $timestamp"); // 输出Unix时间戳

    return timestamp;
  }

  static String formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final formattedDateTime = DateFormat("yyyy-MM-dd HH:mm").format(dateTime);
    return formattedDateTime;
  }

  // 处理时间戳逻辑
  static Future<void> handleTimestampLogic(int startTime) async {
    int timestamp = convertToUnixTimestamp(startTime.toString().padLeft(4, '0'));
    bool success = false;

    for (int i = 0; i < 3600; i++) {
      int currentTimestamp = timestamp + i;
      success = await sendRequestWithTimestamp(currentTimestamp);
      if (success) {
        break;
      }
    }

    if (!success) {
      print("未在规定时间内获取到成功的响应");
    }
  }

  static Future<bool> sendRequestWithTimestamp(int timestamp) async {
    // 这里实现你的请求逻辑
    final response = await getUserPreview(userID: timestamp);
    return response.success && response.data != null;
  }
}
