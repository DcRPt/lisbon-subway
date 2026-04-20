import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/models/waiting_time.dart';
import 'package:cmproject/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmproject/data/metro_repository.dart';
import 'package:provider/provider.dart';

void main() {
  runDashboardTests();
}

void runDashboardTests() {

  // ─────────────────────────────────────────────────────────────────────────
  // NETWORK STATUS
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Dashboard - Apresenta uma linha por cada linha unica das estacoes',
          (tester) async {
        await _pump(tester, [
          _station(id: 's1', lineName: 'Azul'),
          _station(id: 's2', lineName: 'Verde'),
          _station(id: 's3', lineName: 'Azul'), // duplicate — should only show once
        ]);

        expect(find.byKey(const Key('dashboard-network-grid')), findsOneWidget,
            reason: "Deveria existir o grid de linhas com a key 'dashboard-network-grid'");
        expect(find.byKey(const Key('dashboard-line-card-Azul')), findsOneWidget,
            reason: "A linha 'Azul' deveria aparecer uma só vez, mesmo com várias estações nessa linha");
        expect(find.byKey(const Key('dashboard-line-card-Verde')), findsOneWidget,
            reason: "A linha 'Verde' deveria aparecer no network status");
      });

  testWidgets('Dashboard - Linha sem incidentes recentes aparece como Normal',
          (tester) async {
        await _pump(tester, [
          _station(id: 's1', lineName: 'Azul', reports: [
            IncidentReport(
              timestamp: DateTime.now().subtract(const Duration(hours: 48)),
              rate: 3, type: IncidentType.Escalator,
            ),
          ]),
        ]);

        expect(find.byKey(const Key('dashboard-line-status-Azul')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-line-status-Azul'))).data,
          'Normal',
          reason: "Uma linha sem incidentes nas últimas 24h deveria ter status 'Normal'",
        );
      });

  testWidgets('Dashboard - Linha com incidente recente aparece como Disrupted',
          (tester) async {
        await _pump(tester, [
          _station(id: 's1', lineName: 'Vermelha', reports: [
            IncidentReport(
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              rate: 4, type: IncidentType.Elevator,
            ),
          ]),
        ]);

        expect(find.byKey(const Key('dashboard-line-status-Vermelha')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-line-status-Vermelha'))).data,
          'Disrupted',
          reason: "Uma linha com incidente nas últimas 24h deveria ter status 'Disrupted'",
        );
      });

  // ─────────────────────────────────────────────────────────────────────────
  // NEAREST STATION
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Dashboard - Apresenta mensagem quando nao ha estacoes',
          (tester) async {
        await _pump(tester, []);

        expect(find.byKey(const Key('dashboard-nearest-empty')), findsOneWidget,
            reason: "Quando não existem estações deveria aparecer o widget 'dashboard-nearest-empty'");
        expect(find.text('No stations available.'), findsOneWidget,
            reason: "Deveria aparecer o texto 'No stations available.'");
      });

  testWidgets('Dashboard - Apresenta o nome da estacao mais proxima',
          (tester) async {
        await _pump(tester, [
          _station(id: 'MP', name: 'Marquês de Pombal', lineName: 'Azul'),
        ]);

        expect(find.byKey(const Key('dashboard-nearest-name')), findsOneWidget,
            reason: "Deveria existir o widget 'dashboard-nearest-name'");
        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-nearest-name'))).data,
          'Marquês de Pombal',
          reason: "O nome da estação mais próxima deveria ser 'Marquês de Pombal'",
        );
      });

  testWidgets('Dashboard - Apresenta os destinos e tempos de chegada da estacao mais proxima',
          (tester) async {
        await _pump(tester, [
          _station(
            id: 'MP', name: 'Marquês de Pombal', lineName: 'Azul',
            waitingTimes: [
              WaitingTime(destinationId: '10', arrivalsSeconds: [180, 540, 960]),
              WaitingTime(destinationId: '20', arrivalsSeconds: [300, 720, 1140]),
            ],
          ),
        ]);

        // Platform rows
        expect(find.byKey(const Key('dashboard-platform-row-0')), findsOneWidget,
            reason: "Deveria existir a linha de plataforma 0 com a key 'dashboard-platform-row-0'");
        expect(find.byKey(const Key('dashboard-platform-row-1')), findsOneWidget,
            reason: "Deveria existir a linha de plataforma 1 com a key 'dashboard-platform-row-1'");

        // Destination names
        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-platform-dest-0'))).data,
          '→ Reboleira',
          reason: "O destino 0 deveria ser '→ Reboleira' para o id '10'",
        );
        expect(
          tester.widget<Text>(find.byKey(const Key('dashboard-platform-dest-1'))).data,
          '→ Santa Apolónia',
          reason: "O destino 1 deveria ser '→ Santa Apolónia' para o id '20'",
        );

        // Arrival times (180s = 3 min, 300s = 5 min)
        expect(
          find.descendant(
            of: find.byKey(const Key('dashboard-platform-chips-0')),
            matching: find.text('3'),
          ),
          findsOneWidget,
          reason: "O primeiro tempo de chegada da plataforma 0 deveria ser '3' min (180s)",
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('dashboard-platform-chips-1')),
            matching: find.text('5'),
          ),
          findsOneWidget,
          reason: "O primeiro tempo de chegada da plataforma 1 deveria ser '5' min (300s)",
        );
      });

  // ─────────────────────────────────────────────────────────────────────────
  // FAVOURITES
  // ─────────────────────────────────────────────────────────────────────────

  testWidgets('Dashboard - Apresenta mensagem quando nao ha favoritos',
          (tester) async {
        await _pump(tester, [
          _station(id: 's1', lineName: 'Azul', isFavourite: false),
        ]);

        expect(find.byKey(const Key('dashboard-favourites-empty')), findsOneWidget,
            reason: "Quando não há favoritos deveria aparecer o widget 'dashboard-favourites-empty'");
        expect(find.text('No favourites yet.'), findsOneWidget,
            reason: "Deveria aparecer o texto 'No favourites yet.'");
      });

  testWidgets('Dashboard - Apresenta apenas estacoes favoritas',
          (tester) async {
        await _pump(tester, [
          _station(id: 's1', name: 'Oriente',  lineName: 'Vermelha', isFavourite: true),
          _station(id: 's2', name: 'Rossio',   lineName: 'Verde',    isFavourite: true),
          _station(id: 's3', name: 'Alameda',  lineName: 'Verde',    isFavourite: false),
        ]);

        expect(find.byKey(const Key('dashboard-fav-card-s1')), findsOneWidget,
            reason: "A estação favorita 's1' (Oriente) deveria ter um card com a key 'dashboard-fav-card-s1'");
        expect(find.byKey(const Key('dashboard-fav-card-s2')), findsOneWidget,
            reason: "A estação favorita 's2' (Rossio) deveria ter um card com a key 'dashboard-fav-card-s2'");
        expect(find.byKey(const Key('dashboard-fav-card-s3')), findsNothing,
            reason: "A estação 's3' (Alameda) não é favorita e não deveria ter um card");
      });

  testWidgets('Dashboard - Card do favorito apresenta nome e linha',
          (tester) async {
        await _pump(tester, [
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
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Station _station({
  required String id,
  String name = 'Test Station',
  required String lineName,
  bool isFavourite = false,
  List<IncidentReport> reports = const [],
  List<WaitingTime> waitingTimes = const [],
}) => Station(
  id: id, name: name,
  latitude: 38.7, longitude: -9.1,
  lineName: lineName,
  isFavourite: isFavourite,
  reports: reports,
  waitingTimes: waitingTimes,
);

Future<void> _pump(WidgetTester tester, List<Station> stations) async {
  final repo = MetroRepository();
  for (final s in stations) {
    repo.insertStation(s);
  }

  await tester.pumpWidget(
    Provider<MetroRepository>.value(
      value: repo,
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}