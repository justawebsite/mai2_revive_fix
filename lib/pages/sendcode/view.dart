import 'package:flutter/material.dart';
import '../../providers/mai2_preview.dart'; // 确保导入路径正确

class SendCodePage extends StatelessWidget {
  final String userName;
  final int userId;

  const SendCodePage({
    Key? key,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName - $userId'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Mai2Preview.UserLoginIn(
          userID: userId,
        ), // 调用登录方法
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // 加载中显示进度条
          } else if (snapshot.hasError) {
            return Center(child: Text("获取失败: ${snapshot.error}")); // 显示错误信息
          } else if (snapshot.hasData) {
            final jsonData = snapshot.data!;
            return Center(
              child: Text('获取成功，JSON 数据: $jsonData'), // 显示 JSON 数据
            );
          } else {
            return Center(child: Text("未能获取到数据")); // 显示失败信息
          }
        },
      ),
    );
  }
}
