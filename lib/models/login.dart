class UserModel {
  String? UserLoginID;
  // 其他属性和方法...

  UserModel.fromJson(Map<String, dynamic> json) {
    UserLoginID = json['loginId']?.toString(); // 将 loginId 转换为字符串
    // 初始化其他属性...
  }
}
