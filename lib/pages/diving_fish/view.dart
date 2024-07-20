import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import '../../providers/mai2_GetHistoryMusic.dart';
import '../../providers/diving_updata.dart';

class DivingFishPage extends StatefulWidget {
  final int userId;
  final String token;

  const DivingFishPage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _DivingFishPageState createState() => _DivingFishPageState();
}

class _DivingFishPageState extends State<DivingFishPage> {
  TextEditingController logController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAndUploadMusicData();
  }

  Future<void> _fetchAndUploadMusicData() async {
    setState(() {
      isLoading = true;
    });
    _log('开始获取乐曲信息...');
    try {
      final musicDataResponse = await Mai2GetMusic.GetData(userID: widget.userId);
      if (musicDataResponse.success) {
        _log('乐曲信息获取成功.');
        final musicData = musicDataResponse.data;

        _log('开始转换乐曲信息...');
        final convertedData = await _convertMusicData(musicData);
        _log('乐曲信息转换成功.');

        _log('开始上传乐曲信息至水鱼查分器...');
        final uploadResponse = await DivingUpdata.upload(convertedData, widget.token);

        if (uploadResponse.success) {
          _log('乐曲信息上传成功.');
          showToast('乐曲信息上传成功');
        } else {
          _log('乐曲信息上传失败: ${uploadResponse.message}');
          showToast('乐曲信息上传失败: ${uploadResponse.message}');
        }
      } else {
        _log('获取乐曲信息失败: ${musicDataResponse.message}');
        showToast('获取乐曲信息失败: ${musicDataResponse.message}');
      }
    } catch (e) {
      _log('操作失败: $e');
      showToast('操作失败: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _convertMusicData(Map<String, dynamic> musicData) async {
    final userMusicData = musicData['userMusicList'];
    final maiSongData = await _getMaiMusicData();

    List<Map<String, dynamic>> records = [];
    for (var entry in userMusicData) {
      if (entry['userMusicDetailList'] == null) {
        _log('缺少 \'userMusicDetailList\' 键：$entry');
        continue;
      }

      for (var userMusic in entry['userMusicDetailList']) {
        var songId = userMusic['musicId'];
        var levelIndex = userMusic['level'];

        if (songId == null || levelIndex == null) {
          _log('缺少 \'musicId\' 或 \'level\' 键：$userMusic');
          continue;
        }

        var maiMusic = maiSongData[songId.toString()];
        if (maiMusic == null) {
          _log('未找到对应的音乐数据：songId = $songId');
          continue;
        }

        var achievements = userMusic['achievement'] / 10000.0;
        var ds = maiMusic['ds'][levelIndex];
        var ra = _calRa(achievements, ds);

        var record = {
          'achievements': achievements,
          'ds': ds,
          'dxScore': userMusic['deluxscoreMax'],
          'fc': comboToFc[userMusic['comboStatus']],
          'fs': syncToFs[userMusic['syncStatus']],
          'level': maiMusic['level'][levelIndex],
          'level_index': levelIndex,
          'level_label': levelIndexToLabel[levelIndex],
          'ra': ra,
          'rate': scoreRankToRate[userMusic['scoreRank']],
          'song_id': songId,
          'title': maiMusic['title'],
          'type': maiMusic['type'],
        };
        records.add(record);
      }
    }

    return {'userId': widget.userId, 'records': records};
  }

  Future<Map<String, dynamic>> _getMaiMusicData() async {
    final jsonString = await rootBundle.loadString('assets/mai_music_data.json');
    return jsonDecode(jsonString);
  }

  int _calRa(double achievements, double ds) {
    double coefficient = 0.0;

    if (achievements >= 100.5) {
      achievements = 100.5;
      coefficient = 22.4;
    } else if (achievements >= 100) {
      coefficient = 21.6;
    } else if (achievements >= 99.5) {
      coefficient = 21.1;
    } else if (achievements >= 99) {
      coefficient = 20.8;
    } else if (achievements >= 98) {
      coefficient = 20.3;
    } else if (achievements >= 97) {
      coefficient = 20.0;
    } else if (achievements >= 94) {
      coefficient = 16.8;
    } else if (achievements >= 90) {
      coefficient = 15.2;
    } else if (achievements >= 80) {
      coefficient = 13.6;
    } else if (achievements >= 75) {
      coefficient = 12.0;
    } else if (achievements >= 70) {
      coefficient = 11.2;
    } else if (achievements >= 60) {
      coefficient = 9.6;
    } else if (achievements >= 50) {
      coefficient = 8.0;
    } else if (achievements >= 40) {
      coefficient = 6.4;
    } else if (achievements >= 30) {
      coefficient = 4.8;
    } else if (achievements >= 20) {
      coefficient = 3.2;
    } else if (achievements >= 10) {
      coefficient = 1.6;
    }

    return (achievements / 100.0 * ds * coefficient).toInt();
  }

  void _log(String message) {
    logController.text += '$message\n';
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传成绩至水鱼查分器'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading)
              const LinearProgressIndicator(),
            Expanded(
              child: TextField(
                controller: logController,
                maxLines: null,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '日志',
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _fetchAndUploadMusicData,
              child: const Text('重新上传'),
            ),
          ],
        ),
      ),
    );
  }
}

const comboToFc = ["", "fc", "fcp", "ap", "app", "sync"];
const syncToFs = ["", "fs", "fsp", "fsd", "fsdp", "sync"];
const levelIndexToLabel = ["Basic", "Advanced", "Expert", "Master", "Re:MASTER"];
const scoreRankToRate = [
  "d", "c", "b", "bb", "bbb", "a", "aa", "aaa", "s",
  "sp", "ss", "ssp", "sss", "sssp",
];
