import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/pages.dart';
import 'controller.dart';

class FastLogoutPage extends GetView<FastLogoutController> {
  const FastLogoutPage({super.key});

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: controller.qrCodeController,
                    decoration: const InputDecoration(
                      labelText: '二维码',
                      hintText: "请输入二维码解码后的内容",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller.starttime,
                    decoration: const InputDecoration(
                      labelText: '机台开机时间',
                      hintText: "请输入四位数字，如0930",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (value) {
                      if (value.length == 4) {
                        final hour = int.tryParse(value.substring(0, 2));
                        final minute = int.tryParse(value.substring(2, 4));
                        if (hour == null || minute == null || hour >= 24 || minute >= 60) {
                          // 无效的时间格式
                          controller.starttime.clear();
                          Get.snackbar('无效时间', '请输入有效的时间，格式为四位数字，前两位小于24，后两位小于60');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final startTime = controller.starttime.text;
                      if (startTime.length != 4) {
                        Get.snackbar('无效时间', '请输入四位数字时间，格式如0930，09代表小时，30代表分钟，请使用24小时值且自行转换为东京时间输入');
                        return;
                      }
                      final hour = int.tryParse(startTime.substring(0, 2));
                      final minute = int.tryParse(startTime.substring(2, 4));
                      if (hour == null || minute == null || hour >= 24 || minute >= 60) {
                        Get.snackbar('无效时间', '请输入有效的时间，格式为四位数字，前两位小于24，后两位小于60');
                        return;
                      }
                      controller.logout(controller.qrCodeController.text);
                    },
                    child: const Text('逃离小黑屋'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mai批复活'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.qrCodeScanner);
        },
        child: const Icon(Icons.qr_code),
      ),
    );
  }
}

class ProgressDialog extends StatelessWidget {
  final Stream<String> progressStream;
  final VoidCallback onCancel;

  const ProgressDialog({super.key, required this.progressStream, required this.onCancel});

  @override
  Widget build(BuildContext context) {
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
            onCancel();
            Get.back(); // 关闭对话框
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
}
