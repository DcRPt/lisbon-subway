import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';

class MetroRepository {

  final List<Station> _stations = [];

  List<Station> getAllStations() {
    return List.unmodifiable(_stations);
  }

  void attachIncident(String id, IncidentReport report)  {
    final station = getStationDetail(id);
    station.reports.add(report);
  }

  void insertStation(Station station)  {
    _stations.add(station);
  }

  Station getStationDetail(String id) {
    try {
      return _stations.firstWhere((s) => s.id == id);
    } on StateError {
      throw StateError('No station found with id "$id".');
    }
  }

  List<Station> getStationsByName(String name)  {
    final query = name.trim().toLowerCase();
    if (query.isEmpty) return List.unmodifiable(_stations);
    return _stations
        .where((s) => s.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<IncidentReport> getIncidentsForStation(String id) {
    return List<IncidentReport>.from(getStationDetail(id).reports)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Station> getStationsByLine(String lineName) {
    final query = lineName.trim().toLowerCase();
    return _stations
        .where((s) => s.lineName.toLowerCase() == query)
        .toList(growable: false);
  }
}