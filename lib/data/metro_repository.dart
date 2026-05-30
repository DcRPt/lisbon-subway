import 'package:cmproject/connectivity_module.dart';
import 'package:cmproject/data/http_metro_datasource.dart';
import 'package:cmproject/data/sqflite_metro_datasource.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/line_status.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/models/waiting_time.dart';
import 'generic_data_source.dart';

class MetroRepository {
  final HttpMetroDataSource remote;
  final SqfliteMetroDataSource local;
  final ConnectivityModule connectivity;
  final GenericDataSource generic;

  MetroRepository({
    required this.remote,
    required this.local,
    required this.connectivity,
    required this.generic,
  });

  // ── Stations ──────────────────────────────────────────────────────────────

  Future<List<Station>> getAllStations() async {
    if (await connectivity.checkConnectivity()) {
      final stations = await remote.getAllStations();
      for (final station in stations) {
        await local.insertStation(station);
      }
      return local.getAllStations();
    }
    return local.getAllStations();
  }

  Future<Station> getStationDetail(String id) async {
    if (await connectivity.checkConnectivity()) {
      final station = await remote.getStationDetail(id);
      await local.insertStation(station);
    }
    return local.getStationDetail(id);
  }

  Future<List<Station>> getStationsByName(String name) async {
    if (await connectivity.checkConnectivity()) {
      return remote.getStationsByName(name);
    }
    return local.getStationsByName(name);
  }

  Future<List<Station>> getStationsByLine(String lineName) async {
    final stations = await getAllStations();
    final query = lineName.trim().toLowerCase();
    return stations
        .where((s) => s.lineName.toLowerCase() == query)
        .toList(growable: false);
  }

  // ── Incidents ─────────────────────────────────────────────────────────────

  Future<void> attachIncident(String stationId, IncidentReport report) async {
    await local.attachIncident(stationId, report);
  }

  Future<List<IncidentReport>> getIncidentsForStation(String stationId) async {
    return local.getIncidentsForStation(stationId);
  }

  // ── Favourites ─────────────────────────────────────────────────────────────

  Future<List<Station>> getFavourites() async {
    final result = await generic.execute(type: GenericOperationType.GetFavourites);
    final fromGeneric = (result as List<Station>?) ?? [];
    if (fromGeneric.isNotEmpty) return fromGeneric;
    final all = await local.getAllStations();
    return all.where((s) => s.isFavourite).toList();
  }

  Future<void> toggleFavourite(String stationId) async {
    await generic.execute(type: GenericOperationType.ToggleFavourite, data: stationId);
  }

  // ── Line status ───────────────────────────────────────────────────────────

  Future<List<LineStatus>> getAllLineStatuses() async {
    final result = await generic.execute(type: GenericOperationType.GetLineStatuses);
    return (result as List<LineStatus>?) ?? [];
  }

  Future<LineStatus?> getLineStatus(String lineName) async {
    return await generic.execute(type: GenericOperationType.GetLineStatus, data: lineName) as LineStatus?;
  }

  // ── Waiting times ─────────────────────────────────────────────────────────

  Future<List<WaitingTime>> getWaitingTimes(String stationId) async {
    final result = await generic.execute(type: GenericOperationType.GetWaitingTimes, data: stationId);
    final fromGeneric = (result as List<WaitingTime>?) ?? [];
    if (fromGeneric.isNotEmpty) return fromGeneric;
    try {
      final station = await local.getStationDetail(stationId);
      return station.waitingTimes;
    } catch (_) {
      return [];
    }
  }

  // ── Destinations ─────────────────────────────────────────────────────────

  Future<Map<String, String>> getDestinations() async {
    final result = await generic.execute(type: GenericOperationType.GetDestinations);
    return (result as Map<String, String>?) ?? {};
  }
}