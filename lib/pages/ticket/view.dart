import 'package:flutter/material.dart';
import '../../providers/mai2_login.dart'; // 确保导入路径正确
import '../../models/login.dart'; // 确保导入路径正确
import '../../providers/mai2_ticket.dart'; // 引入发券方法
import '../../providers/mai2_logout.dart'; // 引入登出方法
import '../../providers/mai2_GetUserCharge.dart'; // 引入验证未使用券的方法
import 'package:get/get.dart';

class SendTicketPage extends StatefulWidget {
  final String userName;
  final int userId;

  const SendTicketPage({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  _SendTicketPageState createState() => _SendTicketPageState();
}

class _SendTicketPageState extends State<SendTicketPage> {
  String selectedTicket = '二倍券';
  int chargeId = 2;
  int price = 1;
  String message = '';
  TextEditingController messageController = TextEditingController();
  var isCancelling = false.obs;
  UserModel? user;
  late int timestamp;

  @override
  void initState() {
    super.initState();
    timestamp = _getTokyoTimestamp(); // 初始化东京时间戳
    _checkUnusedTickets(); // 检查未使用的券
  }

  int _getTokyoTimestamp() {
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset.inSeconds; // 获取当前设备的时区偏移量
    const tokyoOffset = 9 * 3600; // 东京时间相对于UTC的偏移量，单位为秒
    final tokyoTimestamp = now.toUtc().millisecondsSinceEpoch ~/ 1000 + tokyoOffset - localOffset; // 计算东京时间戳
    return tokyoTimestamp;
  }


  Future<void> _checkUnusedTickets() async {
    final response = await Mai2Charge.UserLoginIn(userID: widget.userId);
    if (response.success) {
      bool hasUnusedTickets = false;

      if (response.data['userChargeList'] != null) {
        hasUnusedTickets = response.data['userChargeList'].any((charge) => charge['chargeId'] != 11001 && charge['stock'] != 0);
      }

      if (hasUnusedTickets) {
        _showUnusedTicketsDialog();
      } else {
        _loginUser();
      }
    } else {
      setState(() {
        message = "检查未使用券失败: ${response.message}";
        _showErrorDialog(message);
      });
    }
  }

  void _showUnusedTicketsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: const Text('账户中存在未使用的券'),
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

  Future<void> _loginUser() async {
    final response = await Mai2Login.UserLoginOn(userID: widget.userId, timestamp: timestamp);
    if (response.success) {
      setState(() {
        user = response.data;
      });
    } else {
      setState(() {
        message = "登录失败: ${response.message}";
        _showErrorDialog(message);
      });
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

  void _sendTicket() async {
    final response = await Mai2Ticket.SendTicket(
      userID: widget.userId,
      chargeId: chargeId,
      price: price,
    );

    setState(() {
      message = response.message;
      messageController.text = message;
    });

    // 调用登出方法
    final logoutResponse = await Mai2Logout.logout(widget.userId, isCancelling, timestamp);

    setState(() {
      message += "\n${logoutResponse.message}";
      messageController.text = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} - ${widget.userId}'),
      ),
      body: user == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text('登入成功，账号: ${widget.userName}, 登录ID: ${user?.UserLoginID}'),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedTicket,
              onChanged: (String? newValue) {
                setState(() {
                  selectedTicket = newValue!;
                  switch (selectedTicket) {
                    case '二倍券':
                      chargeId = 2;
                      price = 1;
                      break;
                    case '三倍券':
                      chargeId = 3;
                      price = 2;
                      break;
                    case '四倍券':
                      chargeId = 4;
                      price = 3;
                      break;
                    case '五倍券':
                      chargeId = 5;
                      price = 4;
                      break;
                    case '六倍券':
                      chargeId = 6;
                      price = 5;
                      break;
                  }
                });
              },
              items: <String>['二倍券', '三倍券', '四倍券', '五倍券', '六倍券']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendTicket,
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
