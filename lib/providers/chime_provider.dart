import 'dart:convert';
//import 'dart:io';
import 'package:universal_io/io.dart';
import 'package:crypto/crypto.dart';
import '../common/chime_error.dart';
import '../common/constants.dart';
import '../common/response.dart';

class ChimeProvider {
  static String hashData(String chipId, String timestamp) {
    return sha256
        .convert('$chipId$timestamp${AppConstants.chimeSalt}'.codeUnits)
        .toString()
        .toUpperCase();
  }  //生成狗号，时间戳，和chime盐值的sha256加密哈希值

  static Future<CommonResponse<int>> getUserId({
    required String chipId,
    required String timestamp,
    required String qrCode,
  }) async {
    final data = jsonEncode({
      "chipID": chipId,
      "openGameID": AppConstants.gameID,
      "key": hashData(chipId, timestamp),
      "qrCode": qrCode,
      "timestamp": timestamp,
    });  //将上面的内容构造http数据包

    try {
      final client = HttpClient();  //创建http请求

      print("$data");

      final request = await client.postUrl(
        Uri.parse('http://${AppConstants.chimeHost}/wc_aime/api/get_data'),
      );  //发送数据包

      request.headers.clear();  //清楚上面设置的http请求头
      request.headers
          .add('Host', AppConstants.chimeHost, preserveHeaderCase: true);  //添加host请求头，值为chime的域名
      request.headers
          .add('User-Agent', 'WC_AIME_LIB', preserveHeaderCase: true);  //将user-agent设置为WC_AIME_LIB
      request.headers.add('Content-Length', data.length.toString(),  //告诉data的长度
          preserveHeaderCase: true);

      request.write(data);  //将上面的data写入请求包，并发送

      await request.flush();  //确保数据发送到服务器

      final response = await request.close();  //完成发送，开始接收数据包
      final responseBody = await response.transform(utf8.decoder).join();  //将收到的数据包转为UTF-8编码，并合并多个数据包为完整的数据

      final json = jsonDecode(responseBody);  //将json转为dart能读写的结构

      return CommonResponse(
        success: json['userID'] != -1,
        data: json['userID'],
        message: ChimeError(json['errorID']).toString(),
      );
    } catch (e) {
      return CommonResponse(
        success: false,
        data: -1,
        message: e.toString(),
      );
    }  //判断返回的数据确定操作是否成功，并提取相关信息
  }
}
