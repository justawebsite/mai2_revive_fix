import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../common/constants.dart';
import '../common/response.dart';
import '../models/login.dart';

class Mai2Login {
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
  }); // 构建http数据包

  static String obfuscate(String srcStr) {
    final m = md5.convert(('$srcStr${AppConstants.mai2Salt}').codeUnits);
    return m.toString();
  } // 拼接字符串和盐值，转换成UTF-16编码并进行MD5加密，再转换为MD5哈希值，最后转换成16进制的字符串

  static Uint8List aesEncrypt(String data) {
    // 待加密字符串
    final key = Key.fromUtf8(AppConstants.aesKey);
    final iv = IV.fromUtf8(AppConstants.aesIV); // 获取设置的aeskey和iv值并转换为加密算法所需的编码格式
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7')); // 创建加密器
    return encrypter.encrypt(data, iv: iv).bytes; // 加密并提取.bytes属性，
  }

  static String aesDecrypt(Uint8List data) {
    final key = Key.fromUtf8(AppConstants.aesKey);
    final iv = IV.fromUtf8(AppConstants.aesIV);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt(Encrypted(data), iv: iv); // 解密并返回解密后的原始数据
  } // 大致同上，只不过变成了解密

  static Future<CommonResponse<UserModel?>> UserLoginOn({
    required int userID, // 获取userid值
    required int timestamp, // 添加 timestamp 参数
  }) async {
    // 创建 JSON 数据
    final Map<String, dynamic> data = {
      "userId": userID,
      "accessCode": "",
      "regionId": 24,
      "placeId": 1545,
      "clientId": "A63E01C2626",
      "dateTime": timestamp,
      "isContinue": false,
      "genericFlag": 0
    };
    final jsonData = jsonEncode(data);
    print("send body: $jsonData");

    final body = zlib.encode(aesEncrypt(jsonEncode(data))); // 将userid值写入json字符串并调用上面的加密器进行加密，在用zlib算法压缩
    maiHeader['User-Agent'] = "${obfuscate('UserLoginApiMaimaiChn')}#$userID"; // 将user-agent标设置为GetUserPreviewApiMaimaiChn的值和userid
    maiHeader['Content-Length'] = body.length.toString(); // 更新请求体的字节长度

    try {
      final client = HttpClient(); // 构造http请求

      final request = await client.postUrl(
        Uri.parse('https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('UserLoginApiMaimaiChn')}'),
      ); // 设置URL并发送数据包

      request.headers.clear(); // 清空http请求头
      for (final key in maiHeader.keys) {
        request.headers.add(key, maiHeader[key]!, preserveHeaderCase: true);
      } // 使用 for 循环遍历之前在 maiHeader 中定义的请求头键值，对于 maiHeader 的每一个键（key），从 maiHeader 中获取对应的值（maiHeader[key]!），并使用 request.headers.add 方法将其添加到请求的头部，参数 preserveHeaderCase: true 确保在添加头信息时保持原有的大小写格式。

      request.add(body); // 将准备好的请求包“body”添加到http请求中

      await request.flush(); // 确保数据包发送

      final response = await request.close(); // 转为接收服务器数据包

      String message = "";
      bool success = false;
      UserModel? user; // 初始化一个message空字符和一个布尔值，声明一个usermodel变量

      final responseBody = await response.toBytes(); // 接收数据包并转换为字节数组

      // 打印接收到的原始响应数据
      print("Received raw response body: $responseBody");

      try {
        final decodedBytes = zlib.decode(responseBody);

        print("Decompressed body: $decodedBytes");

        final decryptedMessage = aesDecrypt(Uint8List.fromList(decodedBytes)); // 解压响应体并转换编码和解密数据

        print("Received decrypted response body: $decryptedMessage");

        final json = jsonDecode(decryptedMessage); // 解析得到的json数据

        print("body: $json");

        if (json['loginId'] == null) {
          success = false;
          message = "请在公众号重新点击一次获取二维码过后再试（不需要进行其他操作）";
        } else {
          user = UserModel.fromJson(json);
          user.UserLoginID = json['loginId']?.toString(); // 正确更新 UserModel 实例的 UserLoginID 属性并转换为字符串类型
          success = true;
        }
      } catch (e) {
        print ("$e");
        // 重试请求
        return await UserLoginOn(userID: userID, timestamp: timestamp);
      }

      print("message: $message");

      return CommonResponse(
        success: success,
        data: user,
        message: message,
      );
    } catch (e) {
      print("Error during request: $e");
      return CommonResponse(
        success: false,
        data: null,
        message: e.toString(),
      );
    } // 封装数据处理结果
  }
}
