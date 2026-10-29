import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/router.dart';
import 'package:komit/services/launch_destination.dart';

void main() {
  test('each known destination name maps to its route', () {
    expect(launchDestinationNamed('today')?.route, AppRoutes.habits);
    expect(launchDestinationNamed('newHabit')?.route, AppRoutes.newHabit);
  });

  test('unknown or malformed values are rejected', () {
    for (final value in <Object?>[null, '', 'TODAY', 'new_habit', '/habit/1/edit', 'settings', 1, true]) {
      expect(launchDestinationNamed(value), isNull, reason: '$value');
    }
  });

  test('every Android shortcut opens a known destination', () {
    final shortcuts = File('android/app/src/main/res/xml/shortcuts.xml').readAsStringSync();
    final destinationNames = RegExp(
      r'android:name="com\.paulcarouge\.komit\.extra\.DESTINATION"\s+android:value="(\w+)"',
    ).allMatches(shortcuts).map((match) => match.group(1));

    expect(destinationNames.map(launchDestinationNamed), [LaunchDestination.newHabit, LaunchDestination.today]);
  });
}
