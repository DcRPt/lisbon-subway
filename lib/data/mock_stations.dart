import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/models/waiting_time.dart';

void seedMockData(MetroRepository repo) {
  repo.insertStation(Station(
    id: 'OR',
    name: 'Oriente',
    latitude: 38.7675,
    longitude: -9.0988,
    lineName: 'Vermelha',
    isFavourite: true,
    reports: [
      IncidentReport(timestamp: DateTime(2025, 4, 1, 8, 30),  rate: 3, notes: 'Escada rolante parada no acesso principal.', type: IncidentType.Escalator),
      IncidentReport(timestamp: DateTime(2025, 4, 2, 14, 0),  rate: 5, notes: 'Elevador avariado, sem alternativa acessível.',  type: IncidentType.Elevator),
      IncidentReport(timestamp: DateTime(2025, 4, 3, 9, 15),  rate: 2, notes: 'Máquina de bilhetes não aceita moedas.',         type: IncidentType.TicketMachine),
      IncidentReport(timestamp: DateTime(2025, 4, 4, 17, 45), rate: 4, notes: 'Torniquete bloqueado na saída norte.',           type: IncidentType.Turnstile),
    ],
    waitingTimes: [
      WaitingTime(destinationId: '60', arrivalsSeconds: [161,  715, 1286]),  // → Aeroporto
      WaitingTime(destinationId: '38', arrivalsSeconds: [67,   612, 1198]),  // → S.Sebastião
    ],
  ));

  repo.insertStation(Station(
    id: 'MP',
    name: 'Marquês de Pombal',
    latitude: 38.7262,
    longitude: -9.1499,
    lineName: 'Azul',
    reports: [
      IncidentReport(timestamp: DateTime(2025, 4, 3, 11, 0), rate: 1, type: IncidentType.Other),
    ],
    waitingTimes: [
      WaitingTime(destinationId: '10', arrivalsSeconds: [180, 540,  960]),   // → Reboleira
      WaitingTime(destinationId: '20', arrivalsSeconds: [300, 720, 1140]),   // → Santa Apolónia
    ],
  ));

  repo.insertStation(Station(
    id: 'RS',
    name: 'Rossio',
    latitude: 38.7143,
    longitude: -9.1393,
    lineName: 'Verde',
    isFavourite: true,
    waitingTimes: [
      WaitingTime(destinationId: '30', arrivalsSeconds: [120, 420, 780]),    // → Telheiras
      WaitingTime(destinationId: '40', arrivalsSeconds: [240, 600, 960]),    // → Cais do Sodré
    ],
  ));
}