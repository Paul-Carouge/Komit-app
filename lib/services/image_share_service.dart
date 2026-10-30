import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _imageShareChannel = MethodChannel('com.paulcarouge.komit/image_share');

/// Opens the system share sheet with a PNG (see ImageShare.kt). Only ever called on a tap.
class ImageShareService {
  bool get isSupported => Platform.isAndroid;

  Future<void> sharePng(Uint8List pngBytes, {required String chooserTitle}) =>
      _imageShareChannel.invokeMethod<void>('sharePng', {'bytes': pngBytes, 'chooserTitle': chooserTitle});
}
