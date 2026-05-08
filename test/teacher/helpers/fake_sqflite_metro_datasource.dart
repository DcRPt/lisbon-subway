import 'package:cmproject/data/sqflite_metro_datasource.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';

class FakeSqfliteMetroDataSource extends SqfliteMetroDataSource {

  final List<Station> stations;

  FakeSqfliteMetroDataSource({required this.stations});

  @override
  Future<bool> init() async {
    return true;
  }

  @override
  Future<void> insertStation(Station station) async {
    final index = stations.indexWhere((item) => item.id == station.id);

    if (index == -1) {
      stations.add(station);
    }
  }

  @override
  Future<void> attachIncident(String id, IncidentReport report) async {
    final index = stations.indexWhere((item) => item.id == id);
    stations[index].reports.add(report);
  }

  @override
  Future<List<Station>> getAllStations() async {
    return stations;
  }

  @override
  Future<Station> getStationDetail(String id) async {
    return stations.firstWhere((element) => element.id == id);
  }

  @override
  Future<List<Station>> getStationsByName(String name) async {
    return stations.where((element) => element.name.toLowerCase().contains(name.toLowerCase())).toList();
  }

}