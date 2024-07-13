import 'package:flutter/material.dart';
import '../../providers/mai2_login.dart'; // 确保导入路径正确
import '../../common/response.dart';
import '../../models/login.dart'; // 确保导入路径正确

class SendTikcetPage extends StatelessWidget {
  final String userName;
  final int userId;

  const SendTikcetPage({
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
      body: FutureBuilder<CommonResponse<UserModel?>>(
        future: Mai2Login.UserLoginOn(
          userID: userId,
        ), // 调用登录方法
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // 加载中显示进度条
          } else if (snapshot.hasError) {
            return Center(child: Text("获取失败: ${snapshot.error}")); // 显示错误信息
          } else if (snapshot.hasData) {
            final response = snapshot.data!;
            if (response.success) {
              final user = response.data;
              return Center(
                child: Text('登入成功，账号: $userName, 登录ID: ${user?.UserLoginID}'), // 显示用户数据
              );
            } else {
              return Center(child: Text("获取失败: ${response.message}")); // 显示错误信息
            }
          } else {
            return Center(child: Text("未能获取到数据")); // 显示失败信息
          }
        },
      ),
    );
  }
}
