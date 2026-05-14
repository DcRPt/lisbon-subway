import 'package:cmproject/models/waiting_time.dart';

import 'incident_report.dart';

class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String lineName;
  final bool isFavourite;
  final List<IncidentReport> reports;
  final List<WaitingTime> waitingTimes;

  Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lineName,
    this.isFavourite = false,
    List<IncidentReport>? reports,
    List<WaitingTime>? waitingTimes,
  })  : reports   = reports ?? [],
        waitingTimes = waitingTimes ?? [];

  double get averageRating {
    if (reports.isEmpty) {
      return 0.0;
    }
    final totalRating = reports.fold(0, (sum, report) => sum + report.rate);
    return totalRating / reports.length;
  }

  int? get frequencyMinutes {
    final first = waitingTimes.firstOrNull;
    if (first == null || first.arrivalsSeconds.length < 2) return null;
    final gap = first.arrivalsSeconds[1] - first.arrivalsSeconds[0];
    return (gap / 60).round();
  }

  bool get isFavorite{
    return isFavourite;
  }

  // ── HTTP ──────────────────────────────────────────────────────────────────
  // /infoEstacao/todos and /infoEstacao/{estacao} response shape:
  // {
  //   "stop_id":   "AM",
  //   "stop_name": "Alameda",
  //   "stop_lat":  "38.7373",
  //   "stop_lon":  "-9.13409",
  //   "linha":     "[Verde, Vermelha]",  ← may have multiple lines
  //   "zone_id":   "L" TODO is this needed??
  // }
  factory Station.fromJson(Map<String, dynamic> json) {
    //TODO verify if in the app we are expected to only have 1 line per station or if i need a list
    // "[Verde, Vermelha]" → "Verde" (take first line)
    final linhaRaw = json['linha'] as String;
    final lineName = linhaRaw
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .first
        .trim();

    return Station(
      id:        json['stop_id']   as String,
      name:      json['stop_name'] as String,
      latitude:  double.parse(json['stop_lat'].toString()),
      longitude: double.parse(json['stop_lon'].toString()),
      lineName:  lineName,
    );
  }

  // ── SQLite ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toDB() => {
    'id':          id,
    'name':        name,
    'latitude':    latitude,
    'longitude':   longitude,
    'lineName':    lineName,
    'isFavourite': isFavourite ? 1 : 0,
  };

  factory Station.fromDB(Map<String, dynamic> row, List<IncidentReport> incidents) =>
      Station(
        id:          row['id']        as String,
        name:        row['name']      as String,
        latitude:    row['latitude']  as double,
        longitude:   row['longitude'] as double,
        lineName:    row['lineName']  as String,
        isFavourite: (row['isFavourite'] as int) == 1,
        reports:     incidents,
      );
}