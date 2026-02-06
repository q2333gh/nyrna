import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nyrna/localization/app_localizations.dart';
import 'package:nyrna/settings/settings.dart';

@GenerateNiceMocks(<MockSpec>[
  MockSpec<SettingsCubit>(),
])
import 'personalization_section_test.mocks.dart';

final SettingsCubit mockSettingsCubit = MockSettingsCubit();

void main() {
  setUp(() {
    reset(mockSettingsCubit);
    when(mockSettingsCubit.state).thenReturn(SettingsState.initial());
    when(mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());
    when(mockSettingsCubit.updateHideProcessPid(true)).thenAnswer((_) async {});
    when(mockSettingsCubit.updateHideProcessPid(false)).thenAnswer((_) async {});
    when(mockSettingsCubit.updateShowExecutableFirst(true)).thenAnswer((_) async {});
    when(mockSettingsCubit.updateShowExecutableFirst(false)).thenAnswer((_) async {});
    when(
      mockSettingsCubit.updateLimitWindowTitleToOneLine(true),
    ).thenAnswer((_) async {});
    when(
      mockSettingsCubit.updateLimitWindowTitleToOneLine(false),
    ).thenAnswer((_) async {});
    when(mockSettingsCubit.updatePinSuspendedWindows(true)).thenAnswer((_) async {});
    when(mockSettingsCubit.updatePinSuspendedWindows(false)).thenAnswer((_) async {});
    when(mockSettingsCubit.updateCompactCards(true)).thenAnswer((_) async {});
    when(mockSettingsCubit.updateCompactCards(false)).thenAnswer((_) async {});
  });

  testWidgets('renders personalization tiles and toggles for each setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<SettingsCubit>.value(
            value: mockSettingsCubit,
            child: const PersonalizationSection(),
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(PersonalizationSection));
    final l10n = AppLocalizations.of(context)!;

    expect(find.text(l10n.hidePidSetting), findsOneWidget);
    expect(find.text(l10n.exeFirstSetting), findsOneWidget);
    expect(find.text(l10n.limitWindowTitleToOneLine), findsOneWidget);
    expect(find.text(l10n.compactModeTitle), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNWidgets(5));

    await tester.tap(find.widgetWithText(SwitchListTile, l10n.hidePidSetting));
    await tester.pumpAndSettle();
    verify(mockSettingsCubit.updateHideProcessPid(true)).called(1);

    await tester.tap(find.widgetWithText(SwitchListTile, l10n.exeFirstSetting));
    await tester.pumpAndSettle();
    verify(mockSettingsCubit.updateShowExecutableFirst(true)).called(1);

    await tester.tap(
      find.widgetWithText(SwitchListTile, l10n.limitWindowTitleToOneLine),
    );
    await tester.pumpAndSettle();
    verify(mockSettingsCubit.updateLimitWindowTitleToOneLine(true)).called(1);

    await tester.tap(find.byType(SwitchListTile).at(4));
    await tester.pumpAndSettle();
    verify(mockSettingsCubit.updatePinSuspendedWindows(true)).called(1);

    await tester.tap(find.widgetWithText(SwitchListTile, l10n.compactModeTitle));
    await tester.pumpAndSettle();
    verify(mockSettingsCubit.updateCompactCards(true)).called(1);
  });
}
