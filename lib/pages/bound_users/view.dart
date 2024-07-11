import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../models/user.dart';
import 'controller.dart';

class BoundUsersPage extends GetView<BoundUsersController> {
  const BoundUsersPage({super.key});

  Widget _buildBindUserDialog() {
    return Obx(
          () => AlertDialog(
        title: const Text('绑定用户'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.qrCodeController,
              decoration: const InputDecoration(
                labelText: '二维码',
                hintText: '请输入二维码解码后的内容',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: controller.binding
                ? null
                : () {
              controller.qrCodeController.clear();
              Get.back();
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: controller.binding
                ? null
                : () {
              controller.binding = true;
              controller.bindUser().then((value) {
                controller.binding = false;
                showToast(value.message);
                controller.binding = false;
                if (value.success) {
                  Get.back();
                }
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
                _showStartTimeDialog(user.userId);
              },
              child: const ListTile(
                title: Text("逃离小黑屋"),
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
                color:
                Get.theme.colorScheme.secondaryContainer.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(user.playerRating.toString()),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartTimeDialog(int userId) {
    final TextEditingController startTimeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('输入开始时间'),
        content: TextField(
          controller: startTimeController,
          decoration: const InputDecoration(
            labelText: '开始时间',
            hintText: '请输入四位数字，如0930',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              String startTime = startTimeController.text;
              if (_validateStartTime(startTime)) {
                startTime = _formatStartTime(startTime); // 添加冒号以匹配解析格式
                Get.back();
                controller.logout(userId, startTime); // 传递两个参数
              } else {
                showToast('请输入有效的四位数字时间，格式如0930');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  bool _validateStartTime(String startTime) {
    if (startTime.length != 4 || int.tryParse(startTime) == null) {
      return false;
    }
    int hour = int.parse(startTime.substring(0, 2));
    int minute = int.parse(startTime.substring(2, 4));
    return hour < 24 && minute < 60;
  }

  String _formatStartTime(String startTime) {
    return "${startTime.substring(0, 2)}:${startTime.substring(2, 4)}";
  }

  Widget _buildBody() {
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
}

class ProgressDialog extends StatelessWidget {
  final Stream<String> progressStream;

  const ProgressDialog({super.key, required this.progressStream});

  @override
  Widget build(BuildContext context) {
    final BoundUsersController controller = Get.find();

    return AlertDialog(
      title: const Text('正在处理'),
      content: StreamBuilder<String>(
        stream: progressStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('准备中...'),
              ],
            );
          } else if (snapshot.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('发生错误'),
                const SizedBox(height: 16),
                Text(snapshot.error.toString()),
              ],
            );
          } else if (snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(snapshot.data!),
              ],
            );
          } else {
            return const Text('未知状态');
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.isCancelling.value = true;
            Get.back();
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
}
