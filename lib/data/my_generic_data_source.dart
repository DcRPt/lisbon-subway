import 'dart:convert';
import 'package:cmproject/data/generic_data_source.dart';
import 'package:cmproject/http/http_client.dart';
import 'package:cmproject/models/destination.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/line_status.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/models/waiting_time.dart';
import 'package:sqflite/sqflite.dart';

class MyGenericDataSource extends GenericDataSource {
  static const _tokenUrl       = 'https://api.metrolisboa.pt:8243/token';
  static const _baseUrl        = 'https://api.metrolisboa.pt:8243/estadoServicoML/1.0.1';
  static const _consumerKey    = 'YOUR_CONSUMER_KEY_HERE';
  static const _consumerSecret = 'YOUR_CONSUMER_SECRET_HERE';

  final HttpClient _client;
  final Database _db;

  String? _accessToken;
  String? _refreshToken;

  MyGenericDataSource({required HttpClient client, required Database db})
      : _client = client,
        _db = db;

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<void> _fetchToken() async {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final response = await _client.post(
      url: _tokenUrl,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );
    if (response.statusCode == 200) {
      final json    = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken  = json['access_token']  as String;
      _refreshToken = json['refresh_token'] as String?;
      return;
    }
    throw Exception('Failed to get access token: ${response.statusCode}');
  }

  Future<void> _refreshAccessToken() async {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));
    final response = await _client.post(
      url: _tokenUrl,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=refresh_token&refresh_token=$_refreshToken',
    );
    if (response.statusCode == 200) {
      final json    = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken  = json['access_token']  as String;
      _refreshToken = json['refresh_token'] as String?;
      return;
    }
    await _fetchToken(); // refresh expired, start fresh
  }

  // Single helper used by all HTTP operations — fetches token if needed,
  // retries once on 401.
  Future<dynamic> _get(String url) async {
    if (_accessToken == null) await _fetchToken();
    var response = await _client.get(
      url: url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 401) {
      await _refreshAccessToken();
      response = await _client.get(
        url: url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
    }
    return response;
  }

  // ── Sqflite operations ────────────────────────────────────────────────────

  Future<List<IncidentReport>> _getIncidentsForStation(String stationId) async {
    final rows = await _db.query(
      'incident_reports',
      where: 'station_id = ?',
      whereArgs: [stationId],
    );
    return rows.map((row) => IncidentReport.fromDB(row)).toList();
  }

  Future<List<Station>> _getFavourites() async {
    final rows = await _db.query(
      'stations',
      where: 'isFavourite = ?',
      whereArgs: [1],
    );
    return Future.wait(rows.map((row) async {
      final incidents = await _getIncidentsForStation(row['id'] as String);
      return Station.fromDB(row, incidents);
    }));
  }

  Future<void> _toggleFavourite(String stationId) async {
    final rows = await _db.query(
      'stations',
      columns:   ['isFavourite'],
      where:     'id = ?',
      whereArgs: [stationId],
    );
    if (rows.isEmpty) throw Exception('Station $stationId not found');
    final current = (rows.first['isFavourite'] as int) == 1;
    await _db.update(
      'stations',
      {'isFavourite': current ? 0 : 1},
      where:     'id = ?',
      whereArgs: [stationId],
    );
  }

  // ── HTTP operations ───────────────────────────────────────────────────────

  Future<List<LineStatus>> _getLineStatuses() async {
    final response = await _get('$_baseUrl/estadoLinha/todos');
    if (response.statusCode == 200) return LineStatus.listFromResponse(jsonDecode(response.body));
    throw Exception('Failed to load line statuses');
  }

  Future<LineStatus> _getLineStatus(String lineName) async {
    final response = await _get('$_baseUrl/estadoLinha/$lineName');
    if (response.statusCode == 200) return LineStatus.fromResponse(lineName, jsonDecode(response.body));
    throw Exception('Failed to load status for $lineName');
  }

  Future<List<WaitingTime>> _getWaitingTimes(String stationId) async {
    final response = await _get('$_baseUrl/tempoEspera/Estacao/$stationId');
    if (response.statusCode == 200) return WaitingTime.listFromResponse(jsonDecode(response.body));
    throw Exception('Failed to load waiting times for $stationId');
  }

  Future<Map<String, String>> _getDestinations() async {
    final response = await _get('$_baseUrl/infoDestinos/todos');
    if (response.statusCode == 200) return Destination.mapFromResponse(jsonDecode(response.body));
    throw Exception('Failed to load destinations');
  }

  // ── execute ───────────────────────────────────────────────────────────────

  @override
  Future<dynamic> execute({required GenericOperationType type, dynamic data}) async {
    switch (type) {
      case GenericOperationType.GetFavourites:
        return _getFavourites();
      case GenericOperationType.ToggleFavourite:
        return _toggleFavourite(data as String);
      case GenericOperationType.GetIncidentsForStation:
        return _getIncidentsForStation(data as String);
      case GenericOperationType.GetLineStatuses:
        return _getLineStatuses();
      case GenericOperationType.GetLineStatus:
        return _getLineStatus(data as String);
      case GenericOperationType.GetWaitingTimes:
        return _getWaitingTimes(data as String);
      case GenericOperationType.GetDestinations:
        return _getDestinations();
    }
  }
}