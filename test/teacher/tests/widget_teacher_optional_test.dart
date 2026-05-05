import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmproject/models/station.dart';

import '../helpers/test_helpers.dart';

void main() {
  runWidgetTests();
}

void runWidgetTests() {
  testWidgets('Lista estacoes - Offline - Apresentar mensagem de erro ao inicializar sem estacoes', (WidgetTester tester) async {
    await tester.pumpAppWithDependencies(remoteStations: [], localStations: [], isOnline: false);

    final listBottomBarItemFinder = find.byKey(Key('list-bottom-bar-item'));
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    expect(find.text("Não foi possível obter as estações de metro. Verifique a conectividade e volte a tentar"), findsOneWidget,
        reason: "Deveria existir pelo menos um Text com o texto 'Não foi possível obter as estações de metro. "
            "Verifique a conectividade e volte a tentar' quando se arranca a app em offline sem nunca ter estado online");
  });

  testWidgets('Offline - Atualizar estacoes quando ao voltar a ficar online', (WidgetTester tester) async {
    final dependencies = await tester.pumpAppWithDependencies();

    final listBottomBarItemFinder = find.byKey(Key('list-bottom-bar-item'));
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder listViewFinder = find.byKey(Key('list-view'));
    final Finder listTilesFinder = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
    final firstTiles = List.from(tester.widgetList<ListTile>(listTilesFinder));

    expect(firstTiles.length, 2, reason: "Deveriam existir 2 ListTiles dentro do ListView das estações");

    final dashboardBottomBarItemFinder = find.byKey(Key('dashboard-bottom-bar-item'));
    await tester.tap(dashboardBottomBarItemFinder);
    await tester.pumpAndSettle();

    dependencies.connectivityModule.isOnline = false;
    dependencies.remoteDataSource.stations.add(
      Station(
        id: "st3",
        name: 'Station 3',
        latitude: 43.9128,
        longitude: -71.1060,
        lineName: 'Castanha',
      )
    );

    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    final secondTiles = List.from(tester.widgetList<ListTile>(listTilesFinder));

    expect(secondTiles.length, 2, reason: "Devia ter apresentado 2 estações vindas da base de dados, uma vez que está offline");

    await tester.tap(dashboardBottomBarItemFinder);
    await tester.pumpAndSettle();

    dependencies.connectivityModule.isOnline = true;

    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();
    final thirdTiles = List.from(tester.widgetList<ListTile>(listTilesFinder));

    expect(thirdTiles.length, 3, reason: "Devia ter apresentado 3 estações vindas do servidor, uma vez que está online");
  });
}