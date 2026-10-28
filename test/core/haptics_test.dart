import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final recordedFeedbackTypes = <String?>[];

  setUp(() {
    recordedFeedbackTypes.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') recordedFeedbackTypes.add(call.arguments as String?);
        return null;
      },
    );
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  test('each meaning maps to its own platform feedback', () async {
    await KomitHaptics.selection();
    await KomitHaptics.success();
    await KomitHaptics.warning();
    await KomitHaptics.error();

    expect(recordedFeedbackTypes, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  test('celebration plays a strong tap followed by a light one', () async {
    await KomitHaptics.celebration();

    expect(recordedFeedbackTypes, ['HapticFeedbackType.mediumImpact', 'HapticFeedbackType.lightImpact']);
  });
}
