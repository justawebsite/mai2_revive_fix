import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart';
import '../../providers/mai2_bonus.dart'; // 引入发券方法
import '../../providers/mai2_GetHistoryBonus.dart'; // 引入Mai2Getdata方法
import '../../providers/mai2_login.dart'; // 确保导入路径正确
import '../../providers/mai2_logout.dart'; // 引入登出方法
import '../../models/login.dart'; // 确保导入路径正确

class SignbonusPage extends StatefulWidget {
  final String userName;
  final int userId;

  const SignbonusPage({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  _SignbonusPageState createState() => _SignbonusPageState();
}

class _SignbonusPageState extends State<SignbonusPage> {
  List<Map<String, dynamic>> bonusOptions = [];
  int? selectedBonusId;
  int? points;
  String message = '';
  TextEditingController pointsController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  var isCancelling = false.obs;
  UserModel? user;
  late int timestamp;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    timestamp = _getTokyoTimestamp(); // 初始化东京时间戳
    _initializePage(); // 初始化页面
  }

  int _getTokyoTimestamp() {
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset.inSeconds; // 获取当前设备的时区偏移量
    const tokyoOffset = 9 * 3600; // 东京时间相对于UTC的偏移量，单位为秒
    final tokyoTimestamp = now.toUtc().millisecondsSinceEpoch ~/ 1000 + tokyoOffset - localOffset; // 计算东京时间戳
    return tokyoTimestamp;
  }

  Future<void> _initializePage() async {
    await _loadBonusOptions();
    await _loginUser();
  }

  Future<void> _loginUser() async {
    print("开始登录用户...");
    final response = await Mai2Login.UserLoginOn(userID: widget.userId, timestamp: timestamp);
    if (response.success) {
      setState(() {
        user = response.data;
      });
      print("用户登录成功: ${user?.UserLoginID}");
    } else {
      setState(() {
        message = "登录失败: ${response.message}";
        _showErrorDialog(message);
      });
      print("用户登录失败: ${response.message}");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('错误'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 退出页面
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadBonusOptions() async {
    try {
      // 加载XML文件
      print("开始加载XML文件...");
      final xmlString = await rootBundle.loadString('assets/LoginBonusSort.xml');
      final document = XmlDocument.parse(xmlString);
      final bonusList = document.findAllElements('StringID');

      // 解析XML文件
      List<Map<String, dynamic>> options = bonusList.map((node) {
        final id = int.parse(node.findElements('id').single.text);
        final str = node.findElements('str').single.text;
        return {'id': id, 'str': str, 'point': null};
      }).toList();
      print("XML文件加载并解析成功");

      // 获取当前bonus数据
      print("开始获取当前bonus数据...");
      final response = await Mai2GetBonus.GetData(userID: widget.userId);
      if (response.success) {
        final userLoginBonusList = response.data['userLoginBonusList'] as List<dynamic>;

        // 将服务器返回的point值附加到options中
        options = options.map((option) {
          final bonus = userLoginBonusList.firstWhere((bonus) => bonus['bonusId'] == option['id'], orElse: () => {'point': null});
          option['point'] = bonus['point'];
          return option;
        }).toList();

        // 过滤掉已完成的bonus选项
        final completedBonusIds = userLoginBonusList.where((bonus) => bonus['isComplete'] == true).map((bonus) => bonus['bonusId']).toSet();
        options = options.where((option) => !completedBonusIds.contains(option['id'])).toList();

        setState(() {
          bonusOptions = options;
          isLoading = false;
        });
        print("当前bonus数据获取成功");
      } else {
        setState(() {
          hasError = true;
          errorMessage = response.message;
        });
        print("获取当前bonus数据失败: ${response.message}");
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = '加载选项失败: $e';
      });
      print("加载选项失败: $e");
    }
  }

  void _sendBonus() async {
    print("开始发送bonus...");
    final response = await Mai2Bonus.SendBonus(
      userID: widget.userId,
      loginId: user!.UserLoginID,
      bonusIds: [selectedBonusId!],
      points: [points!],
    );

    setState(() {
      message = response.message;
      messageController.text = message;
    });
    print("bonus发送结果: ${response.message}");

    // 调用登出方法
    final logoutResponse = await Mai2Logout.logout(widget.userId, isCancelling, timestamp);

    setState(() {
      message += "\n${logoutResponse.message}";
      messageController.text = message;
    });
    print("登出结果: ${logoutResponse.message}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} - ${widget.userId}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text("错误: $errorMessage"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text('登入成功，账号: ${widget.userName}, 登录ID: ${user?.UserLoginID}'),
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: selectedBonusId,
              hint: Text('请选择一个Bonus'),
              isExpanded: true,
              onChanged: (int? newValue) {
                setState(() {
                  selectedBonusId = newValue!;
                  final selectedOption = bonusOptions.firstWhere((option) => option['id'] == selectedBonusId, orElse: () => {'point': null});
                  points = selectedOption['point'];
                  pointsController.text = points?.toString() ?? '';
                });
              },
              items: bonusOptions.map<DropdownMenuItem<int>>((option) {
                return DropdownMenuItem<int>(
                  value: option['id'],
                  child: Text(option['str']),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Points',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  points = int.tryParse(value);
                });
              },
              controller: pointsController,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendBonus,
              child: const Text('发送'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '输出',
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
