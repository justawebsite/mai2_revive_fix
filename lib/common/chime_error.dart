enum ChimeErrorId {
  none("None"),
  readerSetupFail("ReaderSetupFail"),
  readerAccessFail("二维码可能已过期，请刷新重试"),
  readerIncompatible("ReaderIncompatible"),
  dBResolveFail("DBResolveFail"),
  dBAccessTimeout("DBAccessTimeout"),
  dBAccessFail("DBAccessFail"),
  aimeIdInvalid("AimeIdInvalid"),
  noBoardInfo("NoBoardInfo"),
  lockBanSystemUser("LockBanSystemUser"),
  lockBanSystem("LockBanSystem"),
  lockBanUser("LockBanUser"),
  lockBan("LockBan"),
  lockSystem("LockSystem"),
  lockUser("LockUser");

  final String value;

  const ChimeErrorId(this.value);
}  //枚举可能出现的错误类型并将相关错误的value赋值

class ChimeError {
  final int id;

  ChimeError(this.id);  //创建具体的错误对象，id属于ChimeErrorId中的某个定义

  @override
  String toString() {
    if (id < 0 || id >= ChimeErrorId.values.length) {
      return "未知错误";
    }  //如果不为上方枚举出的错误则返回未知错误
    ChimeErrorId errorId = ChimeErrorId.values[id];
    return errorId.value;
  }  //反之，则返回相对应的错误
}
