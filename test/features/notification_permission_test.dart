import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/router.dart';
import 'package:komit/services/notification_permission_service.dart';

import '../support/komit_test_app.dart';

Finder get _reminderSwitch => find.widgetWithText(SwitchListTile, 'Daily reminder');

bool _isReminderSwitchOn(WidgetTester tester) => tester.widget<SwitchListTile>(_reminderSwitch).value;

Future<void> _turnReminderOn(WidgetTester tester) async {
  await tester.scrollUntilVisible(_reminderSwitch, 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(_reminderSwitch);
  await tester.pumpAndSettle();
}

void main() {
  group('habit editor reminder switch', () {
    testWidgets('explains the reminder before Android asks, naming the habit and the time', (tester) async {
      final environment = await KomitTestEnvironment.create(tester);
      final permissionService = FakeNotificationPermissionService(status: NotificationStatus.disabled);
      await pumpKomitApp(
        tester,
        environment,
        theme: lightAppTheme,
        location: AppRoutes.habitEditor(environment.runningHabitId),
        notificationPermissionService: permissionService,
      );

      await _turnReminderOn(tester);

      expect(find.text('Remind you about Morning run?'), findsOneWidget);
      expect(find.textContaining('8:00 PM'), findsWidgets);
      expect(permissionService.permissionRequestCount, 0);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(permissionService.permissionRequestCount, 1);
      expect(_isReminderSwitchOn(tester), isTrue);
      await environment.dispose(tester);
    });

    testWidgets('a refusal turns the switch back off and offers the system settings', (tester) async {
      final environment = await KomitTestEnvironment.create(tester);
      final permissionService = FakeNotificationPermissionService(
        status: NotificationStatus.disabled,
        isPermissionGranted: false,
      );
      await pumpKomitApp(
        tester,
        environment,
        theme: lightAppTheme,
        location: AppRoutes.habitEditor(environment.runningHabitId),
        notificationPermissionService: permissionService,
      );

      await _turnReminderOn(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(_isReminderSwitchOn(tester), isFalse);
      expect(find.textContaining('Reminders need notifications'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(permissionService.settingsOpenCount, 1);
      await environment.dispose(tester);
    });

    testWidgets('turns on at once when notifications are already allowed', (tester) async {
      final environment = await KomitTestEnvironment.create(tester);
      final permissionService = FakeNotificationPermissionService();
      await pumpKomitApp(
        tester,
        environment,
        theme: lightAppTheme,
        location: AppRoutes.habitEditor(environment.runningHabitId),
        notificationPermissionService: permissionService,
      );

      await _turnReminderOn(tester);

      expect(find.text('Remind you about Morning run?'), findsNothing);
      expect(permissionService.permissionRequestCount, 0);
      expect(_isReminderSwitchOn(tester), isTrue);
      await environment.dispose(tester);
    });
  });

  group('settings notification status', () {
    for (final (status, expectedText) in [
      (NotificationStatus.enabled, 'On: your reminders can appear.'),
      (NotificationStatus.disabled, 'Off: your reminders will not appear.'),
    ]) {
      testWidgets('shows ${status.name}', (tester) async {
        final environment = await KomitTestEnvironment.create(tester);
        final permissionService = FakeNotificationPermissionService(status: status);
        await pumpKomitApp(
          tester,
          environment,
          theme: lightAppTheme,
          location: AppRoutes.settings,
          notificationPermissionService: permissionService,
        );

        await tester.scrollUntilVisible(
          find.text('Open system settings'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(expectedText), findsOneWidget);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open system settings'));
        await tester.pumpAndSettle();
        expect(permissionService.settingsOpenCount, 1);
        await environment.dispose(tester);
      });
    }
  });
}
