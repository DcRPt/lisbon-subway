import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';

class MetroRepository {

  List<Station> getAllStations() {
    throw UnimplementedError("getAllStations");
  }

  void attachIncident(String id, IncidentReport report)  {
    throw UnimplementedError("attachIncident");
  }

  void insertStation(Station station)  {
    throw UnimplementedError("insertStation");
  }

  Station getStationDetail(String id) {
    throw UnimplementedError("getStationDetail");
  }

  List<Station> getStationsByName(String name)  {
    throw UnimplementedError("getStationsByName");
  }
}