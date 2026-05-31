import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/models/waiting_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../teacher/helpers/test_helpers.dart';

void main() {
  runDashboardTests();
  runListFilterTests();
  runStationDetailTests();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Station _station({
  required String id,
  String name = 'Test Station',
  required String lineName,
  bool isFavourite = false,
  List<IncidentReport> reports = const [],
  List<WaitingTime> waitingTimes = const [],
}) =>
    Station(
      id: id,
      name: name,
      latitude: 38.7,
      longitude: -9.1,
      lineName: lineName,
      isFavourite: isFavourite,
      reports: List.from(reports),
      waitingTimes: waitingTimes,
    );

// ── Dashboard tests ───────────────────────────────────────────────────────────

void runDashboardTests() {
  // NETWORK STATUS

  testWidgets('Dashboard - Apresenta uma linha por cada linha unica das estacoes',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', lineName: 'Azul'),
          _station(id: 's2', lineName: 'Verde'),
          _station(id: 's3', lineName: 'Azul'), // duplicate — should only show once
        ]);

        expect(find.byKey(const Key('dashboard-network-grid')), findsOneWidget,
            reason: "Deveria existir o grid de linhas com a key 'dashboard-network-grid'");
        expect(find.byKey(const Key('dashboard-line-card-Azul')), findsOneWidget,
            reason: "A linha 'Azul' deveria aparecer uma só vez, mesmo com várias estações");
        expect(find.byKey(const Key('dashboard-line-card-Verde')), findsOneWidget,
            reason: "A linha 'Verde' deveria aparecer no network status");
      });

  testWidgets('Dashboard - Apresenta mensagem quando nao ha estacoes',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: []);
        // pump past the 500ms location timeout in the dashboard _load()
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('dashboard-nearest-empty')), findsOneWidget,
            reason:
            "Quando não existem estações deveria aparecer o widget 'dashboard-nearest-empty'");
      });

  testWidgets('Dashboard - Apresenta o nome da estacao mais proxima',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 'MP', name: 'Marquês de Pombal', lineName: 'Azul'),
        ]);

        expect(find.byKey(const Key('dashboard-nearest-name')), findsOneWidget,
            reason: "Deveria existir o widget 'dashboard-nearest-name'");
        expect(
          tester
              .widget<Text>(find.byKey(const Key('dashboard-nearest-name')))
              .data,
          'Marquês de Pombal',
          reason: "O nome da estação mais próxima deveria ser 'Marquês de Pombal'",
        );
      });

  // FAVOURITES

  testWidgets('Dashboard - Apresenta mensagem quando nao ha favoritos',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', lineName: 'Azul', isFavourite: false),
        ]);

        expect(find.byKey(const Key('dashboard-favourites-empty')), findsOneWidget,
            reason:
            "Quando não há favoritos deveria aparecer o widget 'dashboard-favourites-empty'");
      });

  testWidgets('Dashboard - Apresenta apenas estacoes favoritas',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Oriente', lineName: 'Vermelha', isFavourite: true),
          _station(id: 's2', name: 'Rossio', lineName: 'Verde', isFavourite: true),
          _station(id: 's3', name: 'Alameda', lineName: 'Verde', isFavourite: false),
        ]);

        expect(find.byKey(const Key('dashboard-fav-card-s1')), findsOneWidget,
            reason:
            "A estação favorita 's1' deveria ter um card com a key 'dashboard-fav-card-s1'");
        expect(find.byKey(const Key('dashboard-fav-card-s2')), findsOneWidget,
            reason:
            "A estação favorita 's2' deveria ter um card com a key 'dashboard-fav-card-s2'");
        expect(find.byKey(const Key('dashboard-fav-card-s3')), findsNothing,
            reason: "A estação 's3' não é favorita e não deveria ter um card");
      });

  testWidgets('Dashboard - Card do favorito apresenta nome e linha',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Oriente', lineName: 'Vermelha', isFavourite: true),
        ]);

        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-fav-name-s1'))).data,
          'Oriente',
          reason: "O nome do favorito 's1' deveria ser 'Oriente'",
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-fav-line-s1'))).data,
          'Vermelha',
          reason: "A linha do favorito 's1' deveria ser 'Vermelha'",
        );
      });

  // NAVIGATION

  testWidgets('Dashboard - Clicar numa linha navega para a lista filtrada',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', lineName: 'Azul'),
        ]);

        await tester.tap(find.byKey(const Key('dashboard-line-card-Azul')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list-screen')), findsOneWidget,
            reason:
            "Depois de clicar numa linha deveria navegar para o ecrã da lista com a key 'list-screen'");
      });

  testWidgets('Dashboard - Clicar na estacao mais proxima navega para o detalhe',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 'MP', name: 'Marquês de Pombal', lineName: 'Azul'),
        ]);

        await tester.tap(find.byKey(const Key('dashboard-nearest-card')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('detail-screen')), findsOneWidget,
            reason:
            "Depois de clicar na estação mais próxima deveria navegar para o ecrã de detalhe");
        expect(find.text('Marquês de Pombal'), findsAtLeastNWidgets(1),
            reason: "O ecrã de detalhe deveria apresentar o nome da estação");
      });

  testWidgets('Dashboard - Clicar num favorito navega para o detalhe',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Oriente', lineName: 'Vermelha', isFavourite: true),
        ]);

        await tester.ensureVisible(find.byKey(const Key('dashboard-fav-card-s1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dashboard-fav-card-s1')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('detail-screen')), findsOneWidget,
            reason:
            "Depois de clicar num favorito deveria navegar para o ecrã de detalhe");
        expect(find.text('Oriente'), findsAtLeastNWidgets(1),
            reason: "O ecrã de detalhe deveria apresentar o nome da estação 'Oriente'");
      });
}

// ── List filter tests ─────────────────────────────────────────────────────────

void runListFilterTests() {
  // INITIAL STATE

  testWidgets('Lista - Apresenta todas as estacoes por defeito',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
          _station(id: 's2', name: 'Oriente', lineName: 'Vermelha'),
          _station(id: 's3', name: 'Alameda', lineName: 'Azul'),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget,
            reason: "Por defeito todas as estações deveriam ser visíveis");
        expect(find.byKey(const Key('list-station-tile-s2')), findsOneWidget);
        expect(find.byKey(const Key('list-station-tile-s3')), findsOneWidget);
      });

  // SEARCH

  testWidgets('Lista - Pesquisa filtra estacoes por nome', (tester) async {
    await tester.pumpAppWithDependencies(localStations: [
      _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
      _station(id: 's2', name: 'Oriente', lineName: 'Vermelha'),
    ]);

    await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ross');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget,
        reason: "Estação 'Rossio' deveria aparecer ao pesquisar 'ross'");
    expect(find.byKey(const Key('list-station-tile-s2')), findsNothing,
        reason: "Estação 'Oriente' não deveria aparecer ao pesquisar 'ross'");
  });

  testWidgets('Lista - Pesquisa vazia mostra todas as estacoes', (tester) async {
    await tester.pumpAppWithDependencies(localStations: [
      _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
      _station(id: 's2', name: 'Oriente', lineName: 'Vermelha'),
    ]);

    await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ross');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget);
    expect(find.byKey(const Key('list-station-tile-s2')), findsOneWidget);
  });

  // LINE CHIPS

  testWidgets('Lista - Filtro por linha mostra apenas estacoes dessa linha',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
          _station(id: 's2', name: 'Oriente', lineName: 'Vermelha'),
          _station(id: 's3', name: 'Alameda', lineName: 'Verde'),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('list-line-chip-Verde')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget,
            reason: "Estações da linha Verde devem aparecer");
        expect(find.byKey(const Key('list-station-tile-s3')), findsOneWidget,
            reason: "Estações da linha Verde devem aparecer");
        expect(find.byKey(const Key('list-station-tile-s2')), findsNothing,
            reason: "Estações de outras linhas não devem aparecer");
      });

  testWidgets('Lista - Chip Todas remove o filtro de linha', (tester) async {
    await tester.pumpAppWithDependencies(localStations: [
      _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
      _station(id: 's2', name: 'Oriente', lineName: 'Vermelha'),
    ]);

    await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('list-line-chip-Verde')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('list-line-chip-all')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget);
    expect(find.byKey(const Key('list-station-tile-s2')), findsOneWidget);
  });

  // FAVOURITES TAB

  testWidgets('Lista - Tab favoritos mostra apenas estacoes favoritas',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde', isFavourite: true),
          _station(id: 's2', name: 'Oriente', lineName: 'Vermelha', isFavourite: false),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('list-tab-favourites')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget,
            reason: "Estação favorita deve aparecer no tab de favoritos");
        expect(find.byKey(const Key('list-station-tile-s2')), findsNothing,
            reason: "Estação não favorita não deve aparecer no tab de favoritos");
      });

  testWidgets('Lista - Tab todos volta a mostrar todas as estacoes',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde', isFavourite: true),
          _station(id: 's2', name: 'Oriente', lineName: 'Vermelha', isFavourite: false),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('list-tab-favourites')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('list-tab-all')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget);
        expect(find.byKey(const Key('list-station-tile-s2')), findsOneWidget);
      });

  // FILTER SHEET

  testWidgets('Lista - Filtro sem incidentes esconde estacoes com incidentes',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
          _station(id: 's2', name: 'Oriente', lineName: 'Vermelha', reports: [
            IncidentReport(
                timestamp: DateTime.now(), rate: 3, type: IncidentType.Elevator),
          ]),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('list-filter-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('list-filter-no-incidents-switch')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('list-filter-apply')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('list-filter-apply')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget,
            reason: "Estação sem incidentes deve aparecer");
        expect(find.byKey(const Key('list-station-tile-s2')), findsNothing,
            reason: "Estação com incidentes não deve aparecer com filtro ativo");
      });

  testWidgets('Lista - Ordenar por nome ordena estacoes alfabeticamente',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
          _station(id: 's2', name: 'Alameda', lineName: 'Vermelha'),
          _station(id: 's3', name: 'Oriente', lineName: 'Azul'),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('list-filter-button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('list-sort-chip-name')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('list-filter-apply')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('list-filter-apply')));
        await tester.pumpAndSettle();

        final tiles = tester
            .widgetList<ListTile>(find.descendant(
          of: find.byKey(const Key('list-view')),
          matching: find.byType(ListTile),
        ))
            .toList();

        expect((tiles[0].key as ValueKey).value, 'list-station-tile-s2',
            reason: "Alameda deveria ser a primeira estação ordenada por nome");
        expect((tiles[1].key as ValueKey).value, 'list-station-tile-s3',
            reason: "Oriente deveria ser a segunda estação ordenada por nome");
        expect((tiles[2].key as ValueKey).value, 'list-station-tile-s1',
            reason: "Rossio deveria ser a terceira estação ordenada por nome");
      });

  testWidgets('Lista - Limpar filtros volta ao estado inicial', (tester) async {
    await tester.pumpAppWithDependencies(localStations: [
      _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
      _station(id: 's2', name: 'Oriente', lineName: 'Vermelha', reports: [
        IncidentReport(
            timestamp: DateTime.now(), rate: 3, type: IncidentType.Elevator),
      ]),
    ]);

    await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
    await tester.pumpAndSettle();

    // apply filter
    await tester.tap(find.byKey(const Key('list-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('list-filter-no-incidents-switch')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('list-filter-apply')));
    await tester.tap(find.byKey(const Key('list-filter-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('list-station-tile-s2')), findsNothing);

    // clear filter
    await tester.tap(find.byKey(const Key('list-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('list-filter-clear')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('list-filter-apply')));
    await tester.tap(find.byKey(const Key('list-filter-apply')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('list-station-tile-s1')), findsOneWidget);
    expect(find.byKey(const Key('list-station-tile-s2')), findsOneWidget,
        reason: "Após limpar filtros todas as estações devem aparecer");
  });

  // EMPTY STATE

  testWidgets('Lista - Mostra estado vazio quando nenhuma estacao corresponde',
          (tester) async {
        await tester.pumpAppWithDependencies(localStations: [
          _station(id: 's1', name: 'Rossio', lineName: 'Verde'),
        ]);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'xxxxxxxxxxx');
        await tester.pumpAndSettle(const Duration(milliseconds: 400));

        expect(find.text('Nenhuma estação encontrada'), findsOneWidget,
            reason:
            "Deveria aparecer mensagem de estado vazio quando não há resultados");
        expect(find.byKey(const Key('list-station-tile-s1')), findsNothing);
      });
}

// ── Station detail tests ─────────────────────────────────────────────────────

void runStationDetailTests() {
  testWidgets('Detalhe - Apresenta tempos de espera quando disponiveis na estacao',
          (tester) async {
        final stations = [
          _station(
            id: 'st1',
            name: 'Station 1',
            lineName: 'Rosa',
            waitingTimes: [
              WaitingTime(destinationId: '10', arrivalsSeconds: [180, 540, 960]),
              WaitingTime(destinationId: '20', arrivalsSeconds: [300, 720, 1140]),
            ],
          ),
          _station(id: 'st2', name: 'Station 2', lineName: 'Castanha'),
        ];

        await tester.pumpAppWithDependencies(localStations: stations);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.descendant(
          of: find.byKey(const Key('list-view')),
          matching: find.byType(ListTile),
        ).first);
        await tester.pumpAndSettle();

        // section header should appear
        expect(find.text('PRÓXIMAS PARTIDAS'), findsOneWidget,
            reason:
            "Deveria aparecer a secção 'PRÓXIMAS PARTIDAS' quando existem tempos de espera");

        // first arrival chip for direction 0: 180s = 3 min
        expect(find.text('3'), findsAtLeastNWidgets(1),
            reason: "Deveria aparecer o tempo '3' min (180s / 60)");

        // first arrival chip for direction 1: 300s = 5 min
        expect(find.text('5'), findsAtLeastNWidgets(1),
            reason: "Deveria aparecer o tempo '5' min (300s / 60)");
      });

  testWidgets('Detalhe - Nao apresenta seccao de tempos de espera quando nao ha dados',
          (tester) async {
        final stations = [
          _station(id: 'st1', name: 'Station 1', lineName: 'Rosa'),
          _station(id: 'st2', name: 'Station 2', lineName: 'Castanha'),
        ];

        await tester.pumpAppWithDependencies(localStations: stations);

        await tester.tap(find.byKey(const Key('list-bottom-bar-item')));
        await tester.pumpAndSettle();

        await tester.tap(find.descendant(
          of: find.byKey(const Key('list-view')),
          matching: find.byType(ListTile),
        ).first);
        await tester.pumpAndSettle();

        expect(find.text('PRÓXIMAS PARTIDAS'), findsNothing,
            reason:
            "A secção 'PRÓXIMAS PARTIDAS' não deveria aparecer quando não há tempos");
      });
}