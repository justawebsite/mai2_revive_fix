class UserModel {
  int userId;
  String userName;
  int? playerRating;
  String? divingtoken;

  UserModel({
    required this.userId,
    required this.userName,
    this.playerRating,
    this.divingtoken,
  }); //构造函数，其中rating为可选项

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      userName: json['userName'],
      playerRating: json.containsKey('playerRating') ? json['playerRating'] : null,
      divingtoken: json['divingtoken'],
    );
  } //从Map<String, dynamic> 类型的 JSON文件中创建usermodel实例

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'playerRating': playerRating,
      'divingtoken': divingtoken,
    };
  }
} //将实例转回为json对象，并返回包含userid和username，playrating的字典
