import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';

class MetroRepository {

  final List<Station> _stations = [];

  List<Station> getAllStations() {
    return List.from(_stations);
  }

  void attachIncident(String id, IncidentReport report)  {
    throw UnimplementedError("attachIncident");
  }

  void insertStation(Station station)  {
    _stations.add(station);
  }

  Station getStationDetail(String id) {
    throw UnimplementedError("getStationDetail");
  }

  List<Station> getStationsByName(String name)  {
    throw UnimplementedError("getStationsByName");
  }
}