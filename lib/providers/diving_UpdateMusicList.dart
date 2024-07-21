import 'dart:collection';
import 'dart:convert';
//import 'dart:io';
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';

class divingUpdatamusiclist {
  static LinkedHashMap<String, String> divingHeader = LinkedHashMap<String, String>.from({
    "User-Agent": "Mai2/1.0.0 (iPhone; iOS 14.5; Scale/2.00)",
    "Host": "diving-fish.com",
    "Accept": "*/*",
    "Accept-Language": "zh-Hans-CN;q=1, en-CN;q=0.9",
    "Accept-Encoding": "gzip, deflate",
    "Connection": "keep-alive",
    "Content-Type": "application/x-www-form-urlencoded",
  });

  static Future<String> getLocalFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/mai_music_data.json';
  }

  static Future<File> getLocalFile() async {
    final path = await getLocalFilePath();
    return File(path);
  }

  static Future<List<dynamic>> updateMusicList() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://www.diving-fish.com/api/maimaidxprober/music_data'),
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
        return [{'error': 'Failed to load data'}];
      }
    } catch (e) {
      print('Error: $e');
      return [{'error': e.toString()}];
    }
  }
}
