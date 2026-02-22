import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nyrna/app_version/app_version.dart';
import 'package:nyrna/logs/logs.dart';
import 'package:nyrna/apps_list/apps_list.dart';
import 'package:nyrna/hotkey/global/hotkey_service.dart';
import 'package:nyrna/localization/app_localizations.dart';
import 'package:nyrna/native_platform/native_platform.dart';
import 'package:nyrna/settings/settings.dart';
import 'package:nyrna/storage/storage_repository.dart';
import 'package:nyrna/system_tray/system_tray_manager.dart';
import 'package:nyrna/window/app_window.dart';

@GenerateNiceMocks(<MockSpec>[
  MockSpec<AppVersion>(),
  MockSpec<AppWindow>(),
  MockSpec<HotkeyService>(),
  MockSpec<NativePlatform>(),
  MockSpec<ProcessRepository>(),
  MockSpec<SettingsCubit>(),
  MockSpec<StorageRepository>(),
  MockSpec<SystemTrayManager>(),
])
import 'window_tile_test.mocks.dart';

final mockAppVersion = MockAppVersion();
final mockAppWindow = MockAppWindow();
final mockHotkeyService = MockHotkeyService();
final mockNativePlatform = MockNativePlatform();
final mockProcessRepository = MockProcessRepository();
final SettingsCubit mockSettingsCubit = MockSettingsCubit();
final mockStorageRepository = MockStorageRepository();
final mockSystemTrayManager = MockSystemTrayManager();

const defaultTestWindow = Window(
  id: 548331,
  process: Process(
    executable: 'firefox-bin',
    pid: 8749655,
    status: ProcessStatus.normal,
  ),
  title: 'Home - KDE Community',
);

/// Pumps [WindowTile] with the required bloc providers.
Future<AppsListCubit> _pumpWindowTile(WidgetTester tester) async {
  final appsListCubit = AppsListCubit(
    appVersion: mockAppVersion,
    appWindow: mockAppWindow,
    hotkeyService: mockHotkeyService,
    nativePlatform: mockNativePlatform,
    processRepository: mockProcessRepository,
    settingsCubit: mockSettingsCubit,
    storage: mockStorageRepository,
    systemTrayManager: mockSystemTrayManager,
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
            BlocProvider<AppsListCubit>.value(value: appsListCubit),
          ],
          child: const WindowTile(
            window: defaultTestWindow,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return appsListCubit;
}

void main() {
  setUpAll(() async {
    await LoggingManager.initialize(verbose: false);
  });

  setUp(() {
    reset(mockAppVersion);
    reset(mockHotkeyService);
    reset(mockNativePlatform);
    reset(mockProcessRepository);
    reset(mockSettingsCubit);
    reset(mockStorageRepository);
    reset(mockSystemTrayManager);

    when(mockSettingsCubit.state).thenReturn(SettingsState.initial());
  });

  testWidgets('Clicking more actions button shows context menu', (tester) async {
    final appsListCubit = await _pumpWindowTile(tester);

    final detailsButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.byType(IconButton),
      ),
    );
    detailsButton.onPressed!.call();
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(WindowTile));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.suspendAllInstances), findsOneWidget);
    expect(find.text('Kill process'), findsOneWidget);

    await appsListCubit.close();
  });

  testWidgets('PID line respects hideProcessPid flag', (tester) async {
    when(mockSettingsCubit.state).thenReturn(
      SettingsState.initial().copyWith(hideProcessPid: true),
    );

    final appsListCubit = await _pumpWindowTile(tester);
    expect(find.byKey(const Key('window-tile-pid')), findsNothing);
    await appsListCubit.close();
  });

  testWidgets('Executable moves to title when showExecutableFirst is enabled', (
    tester,
  ) async {
    when(mockSettingsCubit.state).thenReturn(
      SettingsState.initial().copyWith(showExecutableFirst: true),
    );

    final appsListCubit = await _pumpWindowTile(tester);
    expect(
      find.byKey(const Key('window-tile-executable-first')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('window-tile-executable-subtitle')),
      findsNothing,
    );
    await appsListCubit.close();
  });

  testWidgets('ListTile shrinks inner padding when compactCards is enabled', (
    tester,
  ) async {
    when(mockSettingsCubit.state).thenReturn(
      SettingsState.initial().copyWith(compactCards: true),
    );

    final appsListCubit = await _pumpWindowTile(tester);

    final ListTile listTile = tester.widget(find.byType(ListTile));
    expect(listTile.dense, true);
    expect(
      listTile.contentPadding,
      const EdgeInsets.symmetric(vertical: 2, horizontal: 18),
    );

    await appsListCubit.close();
  });

  testWidgets('Card margin tightens with compactCards', (tester) async {
    when(mockSettingsCubit.state).thenReturn(
      SettingsState.initial().copyWith(compactCards: true),
    );

    final appsListCubit = await _pumpWindowTile(tester);
    final Card card = tester.widget(find.byType(Card));
    expect(
      card.margin,
      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );

    await appsListCubit.close();
  });

  testWidgets('Kill process action calls terminate for window pid', (
    tester,
  ) async {
    when(
      mockProcessRepository.terminate(defaultTestWindow.process.pid),
    ).thenAnswer((_) async => true);

    final appsListCubit = await _pumpWindowTile(tester);

    final detailsButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.byType(IconButton),
      ),
    );
    detailsButton.onPressed!.call();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kill process'));
    await tester.pumpAndSettle();

    verify(
      mockProcessRepository.terminate(defaultTestWindow.process.pid),
    ).called(1);

    await appsListCubit.close();
  });

  testWidgets('compact mode title uses tighter font size', (tester) async {
    when(mockSettingsCubit.state).thenReturn(
      SettingsState.initial().copyWith(compactCards: true),
    );

    final appsListCubit = await _pumpWindowTile(tester);
    final Text titleText = tester.widget(find.byKey(const Key('window-tile-title')));
    expect(titleText.style?.fontSize, 14.2);
    await appsListCubit.close();
  });
}
