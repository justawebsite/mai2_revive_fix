import 'dart:collection';
import 'dart:convert';
//import 'dart:io';
import 'package:universal_io/io.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import '../common/constants.dart';
import '../common/response.dart';

class Mai2GetBonus {
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

  static Future<CommonResponse<Map<String, dynamic>>> GetData({
    required int userID,
    int nextIndex = 0,
    List<Map<String, dynamic>> collectedData = const [],
  }) async {
    final data = jsonEncode({
      "userId": userID,
      "nextIndex": nextIndex,
      "maxCount": 20,
    });
    final body = zlib.encode(aesEncrypt(data.toString())); //将userid值写入json字符串并调用上面的加密器进行加密，在用zlib算法压缩

    maiHeader['User-Agent'] =
    "${obfuscate('GetUserLoginBonusApiMaimaiChn')}#$userID"; //将user-agent标设置为GetUserPreviewApiMaimaiChn的值和userid
    maiHeader['Content-Length'] = body.length.toString(); //更新请求体的字节长度

    try {
      final client = HttpClient(); //构造http请求

      final request = await client.postUrl(
        Uri.parse(
            'https://${AppConstants.mai2Host}/Maimai2Servlet/${obfuscate('GetUserLoginBonusApiMaimaiChn')}'),
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
      Map<String, dynamic> jsonData = {};

      final responseBody = await response.toBytes(); //接收数据包并转换为字节数组

      try {
        message = aesDecrypt(Uint8List.fromList(zlib.decode(responseBody))); //解压响应体并转换编码和解密数据
        jsonData = jsonDecode(message); //解析得到的json数据

        print('bonus data message: $message');

        List<Map<String, dynamic>> userLoginBonusList = List<Map<String, dynamic>>.from(jsonData['userLoginBonusList']);
        collectedData = List<Map<String, dynamic>>.from(collectedData)..addAll(userLoginBonusList);

        success = true;

        if (jsonData['nextIndex'] != 0) {
          return await GetData(
            userID: userID,
            nextIndex: jsonData['nextIndex'],
            collectedData: collectedData,
          );
        }
      } catch (e) {
        print("bonus 解码或解密失败: $e");
        // 重试请求
        return await GetData(userID: userID, nextIndex: nextIndex, collectedData: collectedData);
      }

      return CommonResponse(success: success, data: {'userLoginBonusList': collectedData}, message: message);
    } catch (e) {
      return CommonResponse(success: false, data: {}, message: "请求出错: $e");
    }
  }
}
