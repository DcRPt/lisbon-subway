import 'package:cmproject/models/incident_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cmproject/models/station.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:testable_form_field/testable_form_field.dart';

import '../helpers/test_helpers.dart';

void main() {
  runWidgetTests();
}

void runWidgetTests() {
  // Tests start here
  testWidgets('Navegacao - Tem uma bottom bar com 4 opcoes', (WidgetTester tester) async {
    await tester.pumpAppWithDependencies();

    expect(find.byType(NavigationBar), findsOneWidget,
        reason: "Deveria existir uma NavigationBar (atenção que a BottomNavigationBar deve deixar de ser usada)");

    expect(find.byType(NavigationDestination), findsNWidgets(4),
        reason: "Deveriam existir 4 NavigationDestination dentro da NavigationBar");

    for (String key in [
      'dashboard-bottom-bar-item',
      'list-bottom-bar-item',
      'map-bottom-bar-item',
      'incidents-report-bottom-bar-item'
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget,
          reason: "Deveria existir um NavigationDestination com a key '$key'");
    }
  });

  testWidgets('Navegacao - Bottom bar navega para os 4 ecras', (WidgetTester tester) async {
    await tester.pumpAppWithDependencies();

    // Navigate to Dashboard
    final dashboardBottomBarItemFinder = find.byKey(Key('dashboard-bottom-bar-item'));
    await tester.tap(dashboardBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder dashboardScreenFinder = find.byKey(Key("dashboard-screen"));

    expect(dashboardScreenFinder, findsOneWidget,
        reason: "O ecrã do dashboard deveria ter um Scaffold com a key 'dashboard-screen'");

    expect(tester.widget(dashboardScreenFinder), isA<Scaffold>(),
        reason: "A key 'dashboard-screen' deveria estar associada a um Scaffold no ecrã do dashboard");

    // Navigate to List
    final listBottomBarItemFinder = find.byKey(Key('list-bottom-bar-item'));
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder listScreenFinder = find.byKey(Key("list-screen"));

    expect(listScreenFinder, findsOneWidget,
        reason: "O ecrã da lista de estações deveria ter um Scaffold com a key 'list-screen'");

    expect(tester.widget(listScreenFinder), isA<Scaffold>(),
        reason: "A key 'list-screen' deveria estar associada a um Scaffold no ecrã da lista de estações");

    // Navigate to Map
    final mapBottomBarItemFinder = find.byKey(Key('map-bottom-bar-item'));
    await tester.tap(mapBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder mapScreenFinder = find.byKey(Key("map-screen"));

    expect(mapScreenFinder, findsOneWidget,
        reason: "O ecrã do mapa de estações deveria ter um Scaffold com a key 'map-screen'");

    expect(tester.widget(mapScreenFinder), isA<Scaffold>(),
        reason: "A key 'map-screen' deveria estar associada a um Scaffold no ecrã do mapa de estações");

    // Navigate to Incidents
    final incidentsBottomBarItemFinder = find.byKey(
        Key('incidents-report-bottom-bar-item'));
    await tester.tap(incidentsBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder incidentsScreenFinder = find.byKey(
        Key("incidents-report-screen"));

    expect(incidentsScreenFinder, findsOneWidget,
        reason: "O ecrã do registo de incidentes deveria ter um Scaffold com a key 'incidents-report-screen'");

    expect(tester.widget(incidentsScreenFinder), isA<Scaffold>(),
        reason: "A key 'incidents-report-screen' deveria estar associada a um Scaffold no ecrã do registo de incidentes");
  });

  testWidgets('Lista estacoes - Apresenta estacoes', (WidgetTester tester) async {
    await tester.pumpAppWithDependencies();

    final listBottomBarItemFinder = find.byKey(Key('list-bottom-bar-item'));
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder listViewFinder = find.byKey(Key('list-view'));

    expect(listViewFinder, findsOneWidget,
        reason: "Depois de saltar para o ecrã com a lista, deveria existir um ListView com a key 'list-view'");

    expect(tester.widget(listViewFinder), isA<ListView>(),
        reason: "O widget com a key 'list-view' deveria ser um ListView");

    final Finder listTilesFinder = find.descendant(of: listViewFinder, matching: find.byType(ListTile));
    final tiles = List.from(tester.widgetList<ListTile>(listTilesFinder));

    expect(tiles.length, 2,
        reason: "Deveriam existir 2 ListTiles dentro do ListView das estações");

    // First element
    // Ensure the second ListTile contains a Text widget with "Station 1"
    expect(find.descendant(
        of: listTilesFinder.first, matching: find.text("Station 1")),
        findsOneWidget,
        reason: "O primeiro ListTile deveria conter um Text com o texto 'Station 1'");

    // Ensure the second ListTile contains a Text widget with "Linha Rosa"
    expect(find.descendant(
        of: listTilesFinder.first, matching: find.text("Linha Rosa")),
        findsOneWidget,
        reason: "Deveria existir pelo menos um Text com o texto 'Linha Rosa' (no primeiro elemento da lista)");

    // Last element
    // Ensure the second ListTile contains a Text widget with "Station 2"
    expect(find.descendant(
        of: listTilesFinder.last, matching: find.text("Station 2")),
        findsOneWidget,
        reason: "O segundo ListTile deveria conter um Text com o texto 'Station 2'");

    // Ensure the second ListTile contains a Text widget with "Linha Castanha"
    expect(find.descendant(
        of: listTilesFinder.last, matching: find.text("Linha Castanha")),
        findsOneWidget,
        reason: "Deveria existir pelo menos um Text com o texto 'Linha Castanha' (no primeiro elemento da lista)");
  });

  testWidgets("Lista estacoes - Navega para o detalhe da estacao escolhida", (WidgetTester tester) async {
    await tester.pumpAppWithDependencies();

    await tester.tap(find.byKey(Key('list-bottom-bar-item')));
    await tester.pumpAndSettle();

    final Finder listTilesFinder = find.descendant(
        of: find.byKey(Key('list-view')),
        matching: find.byType(ListTile)
    );

    // tap the first tile
    await tester.tap(listTilesFinder.first);
    await tester.pumpAndSettle();

    final Finder detailScreenFinder = find.byKey(Key("detail-screen"));

    expect(detailScreenFinder, findsOneWidget,
        reason: "O ecrã de detalhe deveria ter um Scaffold com a key 'detail-screen'");

    expect(tester.widget(detailScreenFinder), isA<Scaffold>(),
        reason: "A key 'detail-screen' deveria estar associada a um Scaffold no ecrã de detalhe");

    // find if the text 'Station 1' is present
    expect(find.text('Station 1'), findsAtLeastNWidgets(1),
        reason: "O ecrã de detalhe deveria apresentar o nome da estação 'Station 1' (primeiro elemento da lista)");

    // find if the text 'Linha Azul' is present
    expect(find.text('Linha Rosa'), findsOneWidget,
        reason: "O ecrã de detalhe deveria apresentar o nome da linha 'Linha Rosa' (primeiro elemento da lista)");

    // go back
    await tester.pageBack();
    await tester.pumpAndSettle();

    // tap the second tile
    await tester.tap(listTilesFinder.last);
    await tester.pumpAndSettle();

    // find if the text 'Station 2' is present
    expect(find.text('Station 2'), findsAtLeastNWidgets(1),
        reason: "O ecrã de detalhe deveria apresentar o nome da estação 'Station 2' (segundo elemento da lista)");

    expect(find.text('Linha Castanha'), findsOneWidget,
        reason: "O ecrã de detalhe deveria apresentar o nome da linha 'Linha Castanha' (segundo elemento da lista)");
  });

  testWidgets("Incidentes - Existencia de campos do formulario e botao de submeter", (WidgetTester tester) async {
    await tester.pumpAppWithDependencies();

    // Navigate to Incidents
    await tester.tap(find.byKey(Key('incidents-report-bottom-bar-item')));
    await tester.pumpAndSettle();

    final Finder stationSelectionViewFinder = find.byKey(Key('incident-station-selection-field'));

    expect(stationSelectionViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'incident-station-selection-field'");
    expect(tester.widget(stationSelectionViewFinder),
        isA<TestableFormField<Station>>(),
        reason: "O widget com a key 'incident-station-selection-field' deveria ser um TestableFormField<Station>");

    final Finder incidentTypeSelectionViewFinder = find.byKey(Key('incident-type-selection-field'));

    expect(incidentTypeSelectionViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'incident-type-selection-field'");
    expect(tester.widget(incidentTypeSelectionViewFinder),
        isA<TestableFormField<IncidentType>>(),
        reason: "O widget com a key 'incident-type-selection-field' deveria ser um TestableFormField<IncidentType>");

    final Finder ratingViewFinder = find.byKey(Key('incident-rating-field'));

    expect(ratingViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'incident-rating-field'");
    expect(tester.widget(ratingViewFinder), isA<TestableFormField<int>>(),
        reason: "O widget com a key 'incident-rating-field' deveria ser um TestableFormField<int>");

    final Finder dateTimeViewFinder = find.byKey(Key('incident-datetime-field'));

    expect(dateTimeViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'incident-datetime-field'");
    expect(tester.widget(dateTimeViewFinder), isA<TestableFormField<DateTime>>(),
        reason: "O widget com a key 'incident-datetime-field' deveria ser um TestableFormField<DateTime>");

    final Finder notesViewFinder = find.byKey(Key('incident-notes-field'));

    expect(notesViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'incident-notes-field'");
    expect(tester.widget(notesViewFinder), isA<TestableFormField<String>>(),
        reason: "O widget com a key 'incident-notes-field' deveria ser um TestableFormField<String>");

    final Finder submitButtonViewFinder = find.byKey(Key('incident-form-submit-button'));

    expect(submitButtonViewFinder, findsOneWidget,
        reason: "No ecrã do formulário, deveria existir um Widget com a key 'incident-form-submit-button");
  });

  testWidgets('Incidentes - Valicadoes de erro', (WidgetTester tester) async {;
    final incident = IncidentReport(
        timestamp: DateTime(2024, 6, 5, 10, 0),
        rate: 4,
        type: IncidentType.Elevator
    );

    final dependencies = await tester.pumpAppWithDependencies();
    final stations = dependencies.localDataSource.stations;

    // Navigate to Incidents
    await tester.tap(find.byKey(Key('incidents-report-bottom-bar-item')));
    await tester.pumpAndSettle();

    final TestableFormField<Station> stationSelectionFormField = tester
        .widget(find.byKey(Key('incident-station-selection-field')));

    final TestableFormField<IncidentType> incidentTypeSelectionFormField = tester
        .widget(find.byKey(Key('incident-type-selection-field')));

    final TestableFormField<int> ratingViewFormField = tester
        .widget(find.byKey(Key('incident-rating-field')));

    final TestableFormField<DateTime> dateTimeViewFormField = tester
        .widget(find.byKey(Key('incident-datetime-field')));

    final Finder submitButtonViewFinder = find.byKey(Key('incident-form-submit-button'));

    await tester.ensureVisible(submitButtonViewFinder);
    await tester.tap(submitButtonViewFinder);
    await tester.pumpAndSettle();

    // Test without filling anything
    expect(find.textContaining('Preencha a estação'), findsOneWidget);
    expect(find.textContaining('Preencha o tipo de incidente'), findsOneWidget);
    expect(find.textContaining('Preencha a avaliação'), findsOneWidget);
    expect(find.textContaining('Preencha a data e hora'), findsOneWidget);

    await tester.pumpAndSettle(Duration(seconds: 5));

    // Test with all mandatory fields filled but notes empty (optional)
    stationSelectionFormField.setValue(stations.first);
    incidentTypeSelectionFormField.setValue(incident.type);
    ratingViewFormField.setValue(4);
    dateTimeViewFormField.setValue(incident.timestamp);

    await tester.ensureVisible(submitButtonViewFinder);
    await tester.tap(submitButtonViewFinder);
    await tester.pumpAndSettle();
  });

  testWidgets("Incidentes - Inserir incidente", (WidgetTester tester) async {
    final expectedReport = IncidentReport(
        timestamp: DateTime(2024, 6, 5, 10, 0),
        rate: 4,
        type: IncidentType.Elevator,
        notes: "Elevador estava avariado"
    );

    final dependencies = await tester.pumpAppWithDependencies();
    final local = dependencies.localDataSource;

    // Navigate to Incidents
    await tester.tap(find.byKey(Key('incidents-report-bottom-bar-item')));
    await tester.pumpAndSettle();

    final TestableFormField<Station> stationSelectionFormField = tester
        .widget(find.byKey(Key('incident-station-selection-field')));

    final TestableFormField<IncidentType> incidentTypeSelectionFormField = tester
        .widget(find.byKey(Key('incident-type-selection-field')));

    final TestableFormField<int> ratingViewFormField = tester
        .widget(find.byKey(Key('incident-rating-field')));

    final TestableFormField<DateTime> dateTimeViewFormField = tester
        .widget(find.byKey(Key('incident-datetime-field')));

    final TestableFormField<String> notesViewFormField = tester
        .widget(find.byKey(Key('incident-notes-field')));

    stationSelectionFormField.setValue(local.stations.first);
    incidentTypeSelectionFormField.setValue(expectedReport.type);
    ratingViewFormField.setValue(expectedReport.rate);
    dateTimeViewFormField.setValue(expectedReport.timestamp);
    notesViewFormField.setValue(expectedReport.notes!);

    final Finder submitButtonViewFinder = find.byKey(Key('incident-form-submit-button'));

    await tester.ensureVisible(submitButtonViewFinder);
    await tester.tap(submitButtonViewFinder);
    await tester.pumpAndSettle(Duration(milliseconds: 200));

    final actualReport = local
        .stations.first
        .reports.first;

    expect(actualReport.type, expectedReport.type,
        reason: "O tipo do incidente reportado deveria ser "
            "'${expectedReport.type}' e não '${actualReport.type}'"
    );

    final df = DateFormat("dd/MM/yyyy HH:mm");
    expect(actualReport.timestamp, expectedReport.timestamp,
        reason: "O tipo do incidente reportado deveria ser "
            "'${df.format(expectedReport.timestamp)}' e não '${df.format(actualReport.timestamp)}'"
    );

    expect(actualReport.rate, expectedReport.rate,
        reason: "A severidade do incidente reportado deveria ser "
            "'${expectedReport.rate}' e não '${actualReport.rate}'"
    );

    expect(actualReport.notes, expectedReport.notes,
        reason: "Os comentários do incidente reportado deveriam ser "
            "'${expectedReport.notes}' e não '${actualReport.notes}'"
    );
  });

  testWidgets("Detalhe - Apresenta incidente", (WidgetTester tester) async {
    final expectedIncident = IncidentReport(
      timestamp: DateTime(2024, 6, 2, 14, 30),
      type: IncidentType.Elevator,
      rate: 1,
      notes: "Elevador a funcionar mas estava muito sujo",
    );

    final stations = [
      Station(
        id: "st1",
        name: 'Station 1',
        latitude: 40.7128,
        longitude: -74.0060,
        lineName: 'Rosa',
        reports: [expectedIncident],
      ),
      Station(
          id: "st2",
          name: 'Station 2',
          latitude: 43.7128,
          longitude: -71.0060,
          lineName: 'Castanha',
          reports: [
            IncidentReport(
              timestamp: DateTime(2024, 6, 3, 9, 15),
              type: IncidentType.Turnstile,
              rate: 5,
              notes: "Turniquete para pessoas com mobilidade reduzida estava avariado",
            ),
          ]
      ),
    ];

    await tester.pumpAppWithDependencies(localStations: stations);

    await tester.tap(find.byKey(Key('list-bottom-bar-item')));
    await tester.pumpAndSettle();

    final Finder listTilesFinder = find.descendant(
        of: find.byKey(Key('list-view')),
        matching: find.byType(ListTile)
    );

    // tap the first tile
    await tester.tap(listTilesFinder.first);
    await tester.pumpAndSettle();

    await tester.pumpAndSettle(Duration(milliseconds: 200));

    final Finder incidentsListFinder = find.byKey(
        Key("detail-screen-incidents-list"));

    expect(incidentsListFinder, findsOneWidget,
        reason: "O ecrã de detalhe deveria ter uma ListView com a key 'detail-screen-incidents-list'");
    expect(tester.widget(incidentsListFinder), isA<ListView>(),
        reason: "A key 'detail-screen-incidents-list' deveria estar associada a uma ListeView no ecrã de detalhe");

    // find if the text with the current date is present
    final incidentDateTime = DateFormat("dd/MM/yyyy HH:mm").format(expectedIncident.timestamp);

    expect(find.text(incidentDateTime), findsAtLeastNWidgets(1),
        reason: "Deveria existir pelo menos um Text com o texto '$incidentDateTime' (data de um dos incidentes)");

    // find if the text 'No comments' is present
    expect(find.text(expectedIncident.notes!), findsAtLeastNWidgets(1),
        reason: "Deveria existir pelo menos um Text com o texto '${expectedIncident.notes} (texto de uma dos incidentes)'");
  });

  /** Parte 2 **/

  testWidgets('Lista estacoes - Com delay', (WidgetTester tester) async {
    await tester.pumpAppWithDependencies(delay: 1);

    final listBottomBarItemFinder = find.byKey(Key('list-bottom-bar-item'));
    await tester.tap(listBottomBarItemFinder);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: "Enquanto carrega a lista de hospitais, devia mostrar um CircularProgressIndicator");

    // wait for the response
    await tester.pumpAndSettle(Duration(seconds: 1));

    final Finder listViewFinder = find.byKey(Key('list-view'));
    expect(listViewFinder, findsOneWidget,
        reason: "Após mostrar o CircularProgressIndicator, deveria existir um ListView com a key 'list-view'");
    expect(tester.widget(listViewFinder), isA<ListView>(),
        reason: "O widget com a key 'list-view' deveria ser um ListView");
  });

  testWidgets('Mapa estacoes - Apresenta estacoes', (WidgetTester tester) async {
    await tester.pumpAppWithDependencies();

    final listBottomBarItemFinder = find.byKey(Key('map-bottom-bar-item'));
    await tester.tap(listBottomBarItemFinder);
    await tester.pumpAndSettle();

    final Finder mapFinder = find.byType(GoogleMap);
    expect(mapFinder, findsOneWidget,
        reason: "Depois de saltar para o ecrã com o mapa, deveria existir um widget do tipo GoogleMap");

    final GoogleMap googleMap = tester.widget<GoogleMap>(mapFinder);
    // Ensure the map contains exactly two markers
    expect(googleMap.markers.length, 2, reason: "O mapa deve conter exatamente 2 marcadores");
  });

}