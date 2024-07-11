import 'constants.dart';

class ChimeQrCode {
  final String rawQRCode;  //识别二维码内容

  ChimeQrCode(this.rawQRCode);  //将二维码内容赋值给ChimeQrCode

  static bool isValid(String rawQRCode) {
    return rawQRCode.indexOf(AppConstants.wechatID) == 0 &&
        rawQRCode.indexOf(AppConstants.gameID) == 4;
  }  //识别二维码是否为constants文件中的AppConstants.wechatID开头，也就是SGWC并查询四个字符串后是否是MAID

  bool get valid => isValid(rawQRCode); //检查二维码有效性
  String get timestamp => rawQRCode.substring(8, 20);  //获取二维码内容的第8到20位内容验证时间戳得到生成时间，判断是否为过期二维码
  String get qrCode => rawQRCode.substring(20);  //获取二维码从第20位到最后的内容
}
