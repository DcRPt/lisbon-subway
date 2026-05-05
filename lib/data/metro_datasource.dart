import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';

abstract class MetroDataSource {

  Future<void> insertStation(Station station);

  Future<List<Station>> getAllStations();

  Future<List<Station>> getStationsByName(String name);

  Future<Station> getStationDetail(String id);

  Future<void> attachIncident(String id, IncidentReport report);

}