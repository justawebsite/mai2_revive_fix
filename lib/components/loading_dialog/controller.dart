import 'package:get/get.dart';

class TaskResult {
  final bool success;
  final String message;

  TaskResult({
    required this.success,
    required this.message,
  });
}  //接收success值和message数据

class LoadingDialogController extends GetxController with StateMixin {
  late Function() _task;

  void init(Function() task) {
    _task = task;
    _runTask();
  }

  Future<void> _runTask() async {
    TaskResult result = await _task();
    if (result.success) {
      change(result.message, status: RxStatus.success());
    } else {
      change(null, status: RxStatus.error(result.message));
    }
  }
}  //通过UI反应状态变化
