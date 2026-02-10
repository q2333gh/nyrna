import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:helpers/helpers.dart';
import 'package:tray_manager/tray_manager.dart';

import '../core/core.dart';
import '../logs/logging_manager.dart';
import 'system_tray.dart';

class SystemTrayManager {
  SystemTrayManager();

  /// Stream of [SystemTrayEvent] events that are emitted for other services to
  /// react to.
  Stream<SystemTrayEvent> get eventStream => _eventStreamController.stream;

  /// Controller for the system tray event stream.
  final _eventStreamController = StreamController<SystemTrayEvent>.broadcast();

  Future<void> initialize() async {
    final String iconPath;

    if (runningInFlatpak() || runningInSnap()) {
      // When running in Flatpak the icon must be specified by the icon's name, not the path.
      iconPath = kPackageId;
    } else {
      iconPath = (defaultTargetPlatform.isWindows) ? AppIcons.windows : AppIcons.linux;
    }

    log.t('Setting system tray icon to $iconPath');
    await trayManager.setIcon(iconPath);

    final Menu menu = Menu(
      items: [
        MenuItem(
          label: 'Show',
          onClick: (_) {
            _eventStreamController.add(SystemTrayEvent.windowShow);
          },
        ),
        MenuItem(
          label: 'Hide',
          onClick: (_) {
            _eventStreamController.add(SystemTrayEvent.windowHide);
          },
        ),
        MenuItem(
          label: 'Reset Window',
          onClick: (_) {
            _eventStreamController.add(SystemTrayEvent.windowReset);
          },
        ),
        MenuItem(
          label: 'Exit',
          onClick: (_) {
            _eventStreamController.add(SystemTrayEvent.exit);
          },
        ),
        // Workaround for a Windows tray menu rendering bug where the last
        // visible item can be clipped in some environments.
        MenuItem(
          label: ' ',
          onClick: (_) {},
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
  }
}
