import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:mai2_revive/providers/storage_provider.dart';
import '../../components/loading_dialog/controller.dart';
import '../../models/user.dart';
import '../../providers/mai2_provider.dart';
import '../../pages/bound_users/repository.dart';

class CrackUsersController extends GetxController {
  late EasyRefreshController refreshController;
  final BoundUsersRepository repository = BoundUsersRepository();

  TextEditingController BoundUserID = TextEditingController(); // 确保定义了这个变量

  final RxList _boundUsers = [].obs;
  List get boundUsers => _boundUsers;

  final RxBool _binding = false.obs;
  bool get binding => _binding.value;
  set binding(bool value) => _binding.value = value;

  @override
  void onInit() {
    super.onInit();
    refreshController = EasyRefreshController(
      controlFinishLoad: true,
      controlFinishRefresh: true,
    );
    refreshData();
  }

  Future<void> refreshData() async {
    int total = 16;
    int pageNum = 0;
    List<dynamic> users = [];

    boundUsers.clear();

    while (users.length < total) {
      final result = await repository.getUsers(pageNum);
      total = result.count;
      users.addAll(result.results);
      pageNum++;
    }

    if (users.isEmpty) {
      refreshController.finishRefresh(IndicatorResult.noMore);
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((Duration callback) {
      _boundUsers.assignAll(users);
    });

    refreshController.finishRefresh(IndicatorResult.success);
  }

  Future<TaskResult> bindUser() async {
    String message = '';
    String userIdString = BoundUserID.text;  // 获取字符串输入
    int userId = int.parse(userIdString);    // 将字符串转换为整型


    UserModel user = await Mai2Provider.getUserPreview(userID: userId).then((value) {
      if (value.success) {
        return value.data!;
      } else {
        message = "获取用户信息失败：${value.message}";
        return UserModel(
          userId: -1,
          userName: "未知",
        );
      }
    });

    if (user.userId == -1) {
      showToast(message);
      return TaskResult(
        success: false,
        message: message,
      );
    }

    StorageProvider.userList.add(user);

    await refreshData();

    return TaskResult(
      success: true,
      message: "绑定用户成功：${user.userName}",
    );
  }
  void unbindUser(int userId) async {
    StorageProvider.userList.deleteWhere((item) => item.userId == userId);
    await refreshData();
  }  //删除已绑定账号并刷新数据

  void showToast(String message) {
    Get.snackbar('提示', message);
  }
}