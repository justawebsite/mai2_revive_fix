class UserModel {
  String? UserLoginID;
  // 其他属性和方法...

  UserModel.fromJson(Map<String, dynamic> json) {
    UserLoginID = json['loginId'];
    // 初始化其他属性...
  }
}
