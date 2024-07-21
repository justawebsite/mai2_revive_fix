import 'dart:collection';
import 'dart:async';
import 'dart:convert';
//import 'dart:io';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:intl/intl.dart'; // 引入 intl 包以处理日期和时间
import '../common/constants.dart';
import '../common/response.dart';
import '../models/login.dart';

class Mai2Ticket {
  static LinkedHashMap<String, String> maiHeader =
  LinkedHashMap<String, String>.from({
    "Content-Type": "application/json",
    "User-Agent": "",
    "Mai-Encoding": "1.40",
    "Accept-Encoding": "",
    "charset": "UTF-8",
    "Content-Length": "",
    "Content-Encoding": "deflate",
    "Host": AppConstants.mai2Host,
    "Expect": "100-continue",
  }); //构建http数据包

  static String obfuscate(String srcStr) {
    final m = md5.convert(('$srcStr${AppConstants.mai2Salt}').codeUnits);
    return m.toString();
  } //拼接字符串和盐值，转换成UTF-16编码并进行MD5加密，再转换为MD5哈希值，最后转换成16进制的字符串

  static Uint8List aesEncrypt(String data) {
    //待加密字符串
    final key = Key.fromUtf8(AppConstants.aesKey);
    final iv = IV.fromUtf8(AppConstants.aesIV); //获取设置的aeskey和iv值并转换为加密算法所需的编码格式
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7')); //创建加密器
    return encrypter.encrypt(data, iv: iv).bytes; //加密并提取.bytes属性，
  }

  static String aesDecrypt(Uint8List data) {
    final key = Key.fromUtf8(AppConstants.aesKey);
    final iv = IV.fromUtf8(AppConstants.aesIV);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt(Encrypted(data), iv: iv); //解密并返回解密后的原始数据
  } //大致同上，只不过变成了解密

  static Future<CommonResponse<UserModel?>> SendTicket({
    required int userID, //获取userid值
    required int chargeId,
    required int price,
  }) async {
    // 获取当前时间
    final now = DateTime.now();
    // 格式化当前时间为 purchaseDate 格式
    final purchaseDate = DateFormat('yyyy-MM-dd HH:mm:ss.S').format(now);
    // 获取三个月后的日期，并设置时间为 04:00:00
    final validDate = DateFormat('yyyy-MM-dd 04:00:00').format(
        now.add(Duration(days: 90)));

    final data = jsonEncode({
      "userId": userID,
      "userChargelog": {
        "chargeId": chargeId,
        "price": price,
        "purchaseDate": purchaseDate,
        "placeId": 1545,
        "regionId": 24,
        "clientId": "A63E01C2626"
      },
      "userCharge": {
        "chargeId": chargeId,
        "stock": 1,
        "purchaseDate": purchaseDate,
        "validDate": validDate
      }
    });

    print("Received decrypted response body: $data");

    final body = zlib.encode(
        aesEncrypt(data)); //将userid值写入json字符串并调用上面的加密器进行加密，在用zlib算法压缩

    maiHeader['User-Agent'] = "${obfuscate('UpsertUserChargelogApiMaimaiChn')}#$userID"; //将user-agent标设置为GetUserPreviewApiMaimaiChn的值和userid
    maiHeader['Content-Length'] = body.length.toString(); //更新请求体的字节长度

    try {
      final client = HttpClient(); //构造http请求

      final request = await client.postUrl(
        Uri.parse(
            'https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('UpsertUserChargelogApiMaimaiChn')}'),
      ); //设置URL并发送数据包

      request.headers.clear(); //清空http请求头
      for (final key in maiHeader.keys) {
        request.headers.add(key, maiHeader[key]!, preserveHeaderCase: true);
      } //使用 for 循环遍历之前在 maiHeader 中定义的请求头键值，对于 maiHeader 的每一个键（key），从 maiHeader 中获取对应的值（maiHeader[key]!），并使用 request.headers.add 方法将其添加到请求的头部，参数 preserveHeaderCase: true 确保在添加头信息时保持原有的大小写格式。

      request.add(body); //将准备好的请求包“body”添加到http请求中

      await request.flush(); //确保数据包发送

      final response = await request.close(); //转为接收服务器数据包

      String message = "";
      bool success = false;

      final responseBody = await response.toBytes(); //接收数据包并转换为字节数组

      try {
        message = aesDecrypt(Uint8List.fromList(zlib.decode(responseBody))); //解压响应体并转换编码和解密数据

        print("Received decrypted response body: $message");

        final json = jsonDecode(message); //解析得到的json数据
        if (json['returnCode'] == 1) {
          success = true;
          message = "发券成功,请勿多次发券，如账户内存有多张跑图券会导致无法上传游戏数据";
        } else {
          success = false;
          message = "发券可能成功，可通过退出此页面并再次点击发包选项验证";
        }
      } catch (e) {
        print ("$e");
        // 重试请求
        return await SendTicket(userID: userID, chargeId: chargeId, price: price);
      }

      return CommonResponse(
        success: success,
        data: null,
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
}
