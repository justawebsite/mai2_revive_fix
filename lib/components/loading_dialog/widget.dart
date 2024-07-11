import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

class LoadingDialog extends GetWidget<LoadingDialogController> {
  final Future<TaskResult> Function() task;  //返回 Future<TaskResult> 类型的函数，表示将要执行的异步任务
  final Function()? onSuccess;  //逃离成功时调用该函数
  final Function()? onFail;  //失败时调用函数

  const LoadingDialog({
    super.key,
    required this.task,
    this.onSuccess,
    this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    controller.init(task);  //初始化对话框，监听控制器状态的变化，并显示不同的对话框

    return controller.obx(
      (successMessage) => AlertDialog(
        title: const Text("逃离小黑屋成功"),
        content: Text(successMessage ?? "逃离小黑屋成功"),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onSuccess?.call();
            },
            child: const Text(
              "确定",
            ),
          )
        ],
      ),  //显示一个 AlertDialog，标题为“逃离小黑屋成功”，内容为从控制器返回的成功消息。对话框底部有一个“确定”按钮，点击后关闭对话框并调用 onSuccess 回调。
      onLoading: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IntrinsicWidth(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      child: const CircularProgressIndicator(),
                    ),
                    const Text("逃离小黑屋中..."),
                  ],
                ),
              ),
            )
          ],
        ),
      ),  //显示一个模态加载对话框，中间有一个旋转的 CircularProgressIndicator 和一条消息“逃离小黑屋中...”，表明任务正在进行
      onError: (error) => AlertDialog(
        title: const Text("逃离小黑屋失败"),
        content: Text(error ?? "未知错误"),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              onFail?.call();
            },
            child: const Text(
              "确定",
            ),
          ),
        ],
      ),
    );
  }
}  //显示一个 AlertDialog，标题为“逃离小黑屋失败”，内容为错误信息。对话框底部同样设有“确定”按钮，点击后关闭对话框并调用 onFail 回调
