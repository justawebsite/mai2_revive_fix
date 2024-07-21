import 'dart:collection';
import 'dart:convert';
//import 'dart:io';
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';

class LxnsUpdatamusiclist {
  static LinkedHashMap<String, String> lxnsHeader = LinkedHashMap<String, String>.from({
    "User-Agent": "Mai2/1.0.0 (iPhone; iOS 14.5; Scale/2.00)",
    "Host": "maimai.lxns.net",
    "Accept": "*/*",
    "Accept-Language": "zh-Hans-CN;q=1, en-CN;q=0.9",
    "Accept-Encoding": "gzip, deflate",
    "Connection": "keep-alive",
    "Content-Type": "application/x-www-form-urlencoded",
  });

  static Future<String> getLocalFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/MusicList.json';
  }

  static Future<File> getLocalFile() async {
    final path = await getLocalFilePath();
    return File(path);
  }

  static Future<Map<String, dynamic>> updateMusicList() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://maimai.lxns.net/api/v0/maimai/song/list'),
      );

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final jsonData = jsonDecode(responseBody);

        final file = await getLocalFile();
        await file.writeAsString(jsonEncode(jsonData));

        print('MusicList.json has been updated successfully.');
        return jsonData;
      } else {
        print('Failed to load data from server. Status code: ${response.statusCode}');
        return {'error': 'Failed to load data'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': e.toString()};
    }
  }
}
