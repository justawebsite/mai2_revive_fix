import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mai2_revive/pages/fast_logout/view.dart';

import '../../common/qr_code.dart';
import '../../components/loading_dialog/controller.dart';
import '../../components/loading_dialog/widget.dart';
import '../../providers/chime_provider.dart';
import '../../providers/mai2_provider.dart';

class FastLogoutController extends GetxController {
  TextEditingController qrCodeController = TextEditingController();
  TextEditingController starttime = TextEditingController();

  void logout(String rawQrCode) async {
    ChimeQrCode qrCode = ChimeQrCode(rawQrCode);

    Get.dialog(
      ProgressDialog(
        progressStream: _logoutWithProgress(qrCode),
      ),
      barrierDismissible: false,
    );
  }

  Stream<String> _logoutWithProgress(ChimeQrCode qrCode) async* {
    String message = "";

    if (!qrCode.valid) {
      yield '无效的二维码';
      return;
    }
    String chipId = "A63E-01E${Random().nextInt(999999999).toString().padLeft(8, '0')}";
    int userID = await ChimeProvider.getUserId(
      chipId: chipId,
      timestamp: qrCode.timestamp,
      qrCode: qrCode.qrCode,
    ).then((value) {
      if (value.success) {
        return value.data;
      } else {
        message = "获取用户ID失败：${value.message}";
        return -1;
      }
    });

    if (userID == -1) {
      yield message;
      return;
    }

    String startTime = starttime.text;

    await for (var response in Mai2Provider.logout(userID, startTime)) {
      yield "进度：${response.message}";
      if (response.success) {
        yield response.message;
        return;
      }
    }
  }
}
