import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import '../common/constants.dart';
import '../common/response.dart';
import '../models/login.dart';

class Mai2Bonus {
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

  static Future<CommonResponse<UserModel?>> SendBonus({
    required int userID, //获取userid值
    required String? loginId,
    required List<int> bonusIds,
    required List<int> points,
  }) async {
    try {
      final userLoginBonusList = List<Map<String, dynamic>>.generate(bonusIds.length, (index) {
        return {
          "bonusId": bonusIds[index],
          "point": points[index],
          "isCurrent": true,
          "isComplete": false,
        };
      });

      final data = jsonEncode({"userLoginBonusList": userLoginBonusList});

      print("Received decrypted response body: $data");

      // 正常情况下处理请求并返回
      return CommonResponse(
        success: true,
        data: null, // 根据需要返回的数据类型设置
        message: "Bonus sent successfully",
      );
    } catch (e) {
      // 处理异常情况并返回错误响应
      return CommonResponse(
        success: false,
        data: null,
        message: "Error sending bonus: $e",
      );
    }
  }
}
