import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';

void seedMockData(MetroRepository repo) {
  repo.insertStation(Station(
    id: '1',
    name: 'Oriente',
    latitude: 38.7675,
    longitude: -9.0988,
    lineName: 'Vermelha',
    reports: [
      IncidentReport(timestamp: DateTime(2025, 4, 1, 8, 30), rate: 3, notes: 'Escada rolante parada no acesso principal.', type: IncidentType.Escalator),
      IncidentReport(timestamp: DateTime(2025, 4, 2, 14, 0), rate: 5, notes: 'Elevador avariado, sem alternativa acessível.', type: IncidentType.Elevator),
      IncidentReport(timestamp: DateTime(2025, 4, 3, 9, 15), rate: 2, notes: 'Máquina de bilhetes não aceita moedas.', type: IncidentType.TicketMachine),
      IncidentReport(timestamp: DateTime(2025, 4, 4, 17, 45), rate: 4, notes: 'Torniquete bloqueado na saída norte.', type: IncidentType.Turnstile),
    ],
  ));

  repo.insertStation(Station(
    id: '2',
    name: 'Marquês de Pombal',
    latitude: 38.7262,
    longitude: -9.1499,
    lineName: 'Azul',
    reports: [
      IncidentReport(timestamp: DateTime(2025, 4, 3, 11, 0), rate: 1, type: IncidentType.Other),
    ],
  ));

  repo.insertStation(Station(
    id: '3',
    name: 'Rossio',
    latitude: 38.7143,
    longitude: -9.1393,
    lineName: 'Verde',
  ));
}