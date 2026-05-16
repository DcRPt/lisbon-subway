import 'dart:convert';
import 'package:cmproject/data/metro_datasource.dart';
import 'package:cmproject/http/http_client.dart';
import 'package:cmproject/models/destination.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/line_status.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/models/waiting_time.dart';

class HttpMetroDataSource extends MetroDataSource {

  //TODO create gitignore and env to put the keys?
  static const _tokenUrl = 'https://api.metrolisboa.pt:8243/ACCESS_TOKEN';
  static const _baseUrl  = 'https://api.metrolisboa.pt:8243/estadoServicoML/1.0.1';
  static const _consumerKey    = 'CONSUMER_KEY';
  static const _consumerSecret = 'CONSUMER_SECRET';

  final HttpClient? _client;

  String? _accessToken;
  DateTime? _tokenExpiry;
  Future<String>? _pendingTokenFetch;

  HttpMetroDataSource({HttpClient? client}) : _client = client;

  // ── Token ─────────────────────────────────────────────────────────────────

  Future<String> _getToken() {
    // Return cached token if still valid
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return Future.value(_accessToken!);
    }

    // Reuse in-flight fetch if one is already running
    _pendingTokenFetch ??= _fetchToken().whenComplete(() {
      _pendingTokenFetch = null;
    });

    return _pendingTokenFetch!;
  }

  Future<String> _fetchToken() async {
    final credentials = base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'));

    final response = await _client?.post(
      url: _tokenUrl,
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (response?.statusCode == 200) {
      final json   = jsonDecode(response!.body) as Map<String, dynamic>;
      _accessToken = json['access_token'] as String;
      _tokenExpiry = DateTime.now().add(Duration(seconds: json['expires_in'] as int));
      return _accessToken!;
    }

    throw Exception('Failed to get access token: ${response?.statusCode}');
  }

  // ── MetroDataSource ───────────────────────────────────────────────────────

  @override
  Future<void> insertStation(Station station) async =>
      throw Exception('Not Available');

  @override
  Future<void> attachIncident(String id, IncidentReport report) async =>
      throw Exception('Not Available');

  // GET /infoEstacao/todos
  @override
  Future<List<Station>> getAllStations() async {
    final token    = await _getToken();
    final response = await _client?.get(
      url: '$_baseUrl/infoEstacao/todos',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response?.statusCode == 200) {
      final decoded = jsonDecode(response!.body);
      final List<dynamic> results = decoded['resposta'];
      return results.map((json) => Station.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load stations');
    }
  }

  // GET /infoEstacao/{estacao}
  @override
  Future<Station> getStationDetail(String id) async {
    final token    = await _getToken();
    final response = await _client?.get(
      url: '$_baseUrl/infoEstacao/$id',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response?.statusCode == 200) {
      final decoded = jsonDecode(response!.body);
      final List<dynamic> results = decoded['resposta'];
      return Station.fromJson(results.first);
    } else {
      throw Exception('Failed to load station $id');
    }
  }

  // Filters locally — no search endpoint in the API
  @override
  Future<List<Station>> getStationsByName(String name) async {
    final allStations = await getAllStations();
    final lowerName   = name.toLowerCase();
    return allStations
        .where((s) => s.name.toLowerCase().contains(lowerName))
        .toList();
  }

  // ── Extra endpoints ───────────────────────────────────────────────────────

  // GET /estadoLinha/todos
  Future<List<LineStatus>> getAllLineStatuses() async {
    final token    = await _getToken();
    final response = await _client?.get(
      url: '$_baseUrl/estadoLinha/todos',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response?.statusCode == 200) {
      final decoded = jsonDecode(response!.body);
      return LineStatus.listFromResponse(decoded);
    } else {
      throw Exception('Failed to load line statuses');
    }
  }

  // GET /estadoLinha/{linha}
  Future<LineStatus> getLineStatus(String lineName) async {
    final token    = await _getToken();
    final response = await _client?.get(
      url: '$_baseUrl/estadoLinha/$lineName',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response?.statusCode == 200) {
      final decoded = jsonDecode(response!.body);
      return LineStatus.fromResponse(lineName, decoded);
    } else {
      throw Exception('Failed to load status for $lineName');
    }
  }

  // GET /tempoEspera/Estacao/{estacao}
  Future<List<WaitingTime>> getWaitingTimes(String stationId) async {
    final token    = await _getToken();
    final response = await _client?.get(
      url: '$_baseUrl/tempoEspera/Estacao/$stationId',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response?.statusCode == 200) {
      final decoded = jsonDecode(response!.body);
      return WaitingTime.listFromResponse(decoded);
    } else {
      throw Exception('Failed to load waiting times for $stationId');
    }
  }

  // GET /infoDestinos/todos
  Future<Map<String, String>> getDestinations() async {
    final token    = await _getToken();
    final response = await _client?.get(
      url: '$_baseUrl/infoDestinos/todos',
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response?.statusCode == 200) {
      final decoded = jsonDecode(response!.body);
      return Destination.mapFromResponse(decoded);
    } else {
      throw Exception('Failed to load destinations');
    }
  }
}