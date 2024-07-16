import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

class LxnsGetsongjacket {
  static LinkedHashMap<String, String> lxnsHeader = LinkedHashMap<String, String>.from({
    "User-Agent": "Mai2/1.0.0 (iPhone; iOS 14.5; Scale/2.00)",
    "Host": "assets2.lxns.net",
    "Accept": "*/*",
    "Accept-Language": "zh-Hans-CN;q=1, en-CN;q=0.9",
    "Accept-Encoding": "gzip, deflate",
    "Connection": "keep-alive",
    "Content-Type": "application/x-www-form-urlencoded",
  });

  static Future<Uint8List?> getSongJacket({required int musicID}) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://assets2.lxns.net/maimai/jacket/$musicID.png'),
      );

      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        return bytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
