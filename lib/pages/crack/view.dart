import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user.dart';
import '../../providers/mai2_logout.dart';
import '../sendcode/view.dart';
import '../ticket/view.dart';
import 'controller.dart' as crack;
import 'controller.dart';
import '../../providers/mai2_login.dart'; // 确保导入路径正确

class CrackController extends GetView<CrackUsersController> {
  const CrackController({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('绑定的用户'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.dialog(_buildBindUserDialog());
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBindUserDialog() {
    final controller = Get.find<crack.CrackUsersController>(); // 使用 Get.find 获取控制器实例
    return Obx(() => AlertDialog(
      title: const Text('绑定用户'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.BoundUserID,
            decoration: const InputDecoration(
              labelText: 'UserID',
              hintText: '请输入UserID',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: controller.binding ? null : () {
            controller.BoundUserID.clear();
            Get.back();
          },
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: controller.binding ? null : () {
            controller.binding = true;
            controller.bindUser().then((value) {
              controller.binding = false;
              showToast(value.message);
              if (value.success) {
                Get.back();
              }
            });
          },
          child: const Text('确定'),
        ),
      ],
    ));
  }

  void showToast(String message) {
    Get.snackbar('提示', message);
  }

  Widget _buildUserPreview(UserModel user) {
    return InkWell(
      onTap: () {
        Get.dialog(SimpleDialog(
          clipBehavior: Clip.antiAlias,
          title: const Text("请选择操作"),
          children: [
            InkWell(
              onTap: () {
                Get.back();
                Get.to(() => SendCodePage(userName: user.userName, userId: user.userId));
              },
              child: const ListTile(
                title: Text("获取信息"),
                leading: Icon(Icons.message),
              ),
            ),
            InkWell(
              onTap: () {
                Get.back();
                Get.to(() => SendTicketPage(userName: user.userName, userId: user.userId));
              },
              child: const ListTile(
                title: Text("发券"),
                leading: Icon(Icons.airplane_ticket),
              ),
            ),
            InkWell(
              onTap: () {
                Get.back();
                _showCustomTimestampDialog(user.userId);
              },
              child: const ListTile(
                title: Text("自定义时间戳登出"),
                leading: Icon(Icons.logout),
              ),
            ),
            InkWell(
              onTap: () {
                Get.back();
                controller.unbindUser(user.userId);
              },
              child: const ListTile(
                title: Text("解除绑定"),
                leading: Icon(Icons.delete),
              ),
            ),
          ],
        ));
      },
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Get.theme.colorScheme.secondaryContainer,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.person,
            size: 24,
          ),
        ),
        title: Text(user.userName),
        subtitle: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Get.theme.colorScheme.secondaryContainer.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(user.playerRating.toString()),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomTimestampDialog(int userId) {
    final TextEditingController timestampController = TextEditingController();
    final isCancelling = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('自定义时间戳登出'),
        content: TextField(
          controller: timestampController,
          decoration: const InputDecoration(
            labelText: '时间戳',
            hintText: '请输入时间戳',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final timestamp = int.tryParse(timestampController.text);
              if (timestamp != null) {
                final loginResponse = await Mai2Login.UserLoginOn(userID: userId, timestamp: timestamp);
                final response = await Mai2Logout.logout(userId, isCancelling, timestamp);
                Get.back();
                Get.dialog(AlertDialog(
                  title: const Text('登出状态'),
                  content: Text('${loginResponse.message}\n${response.message}'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ));
              } else {
                Get.snackbar('错误', '请输入有效的时间戳');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final controller = Get.find<crack.CrackUsersController>(); // 确保使用 Get.find
    return EasyRefresh.builder(
      childBuilder: (context, physics) {
        return Obx(() {
          if (controller.boundUsers.isEmpty) {
            return CustomScrollView(
              physics: physics,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          const Text('暂无绑定用户'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: physics,
            itemCount: controller.boundUsers.length,
            itemBuilder: (context, index) {
              return _buildUserPreview(controller.boundUsers[index]);
            },
          );
        });
      },
      onRefresh: controller.refreshData,
      header: const MaterialHeader(),
      footer: const ClassicFooter(
        dragText: "下拉刷新",
        armedText: "松开刷新",
        readyText: "正在刷新...",
        processingText: "正在刷新...",
        processedText: "刷新成功",
        noMoreText: "没有更多了",
        failedText: "刷新失败",
        messageText: "最后更新于 %T",
      ),
    );
  }
}
