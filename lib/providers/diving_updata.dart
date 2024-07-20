import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/response.dart';

class DivingUpdata {
  static Future<CommonResponse> upload(Map<String, dynamic> data, String token) async {
    try {
      var url = 'https://www.diving-fish.com/api/maimaidxprober/player/update_records';
      var headers = {
        'Import-Token': token,
        'Content-Type': 'application/json',
      };

      var response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(data));

      if (response.statusCode == 200) {
        return CommonResponse(success: true, message: '数据上传成功', data: null);
      } else {
        return CommonResponse(success: false, message: '数据上传失败，状态码: ${response.statusCode}\n响应内容: ${response.body}', data: null);
      }
    } catch (e) {
      return CommonResponse(success: false, message: '上传失败: $e', data: null);
    }
  }
}
