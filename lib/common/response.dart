class CommonResponse<T> {
  final bool success;
  final String message;
  final T data;

  CommonResponse(
      {required this.success, required this.message, required this.data});
}
//接收服务器返回的success值，message和data数据