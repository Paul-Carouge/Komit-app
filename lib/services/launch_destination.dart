import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../router.dart';

/// Sends the destination of the intent that started or resumed MainActivity.kt.
const MethodChannel _launchDestinationChannel = MethodChannel('com.paulcarouge.komit/launch_destination');

/// The screens a home-screen shortcut or the widget may open. The names match
/// LaunchDestination.kt; Flutter deep links stay disabled, so nothing else can pick a route.
enum LaunchDestination {
  today(AppRoutes.habits),
  newHabit(AppRoutes.newHabit);

  const LaunchDestination(this.route);

  final String route;
}

/// Null for anything but a [LaunchDestination] name: the value crosses a platform channel.
LaunchDestination? launchDestinationNamed(Object? name) {
  for (final destination in LaunchDestination.values) {
    if (destination.name == name) return destination;
  }
  return null;
}

/// The destination the app was started with, then each one it is resumed with. Empty off
/// Android, where there are no shortcuts or widget.
Stream<LaunchDestination> watchLaunchDestinations() {
  if (!Platform.isAndroid) return const Stream.empty();
  final controller = StreamController<LaunchDestination>();
  void addIfKnown(Object? name) {
    final destination = launchDestinationNamed(name);
    if (destination != null) controller.add(destination);
  }

  _launchDestinationChannel.setMethodCallHandler((call) async {
    if (call.method == 'openDestination') addIfKnown(call.arguments);
  });
  unawaited(
    _launchDestinationChannel
        .invokeMethod<String>('takeInitialDestination')
        .then(addIfKnown, onError: controller.addError),
  );
  controller.onCancel = () => _launchDestinationChannel.setMethodCallHandler(null);
  return controller.stream;
}
