import 'package:cmproject/data/metro_datasource.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqfliteMetroDataSource extends MetroDataSource {
  static const _dbName    = 'metro.db';
  static const _dbVersion = 1;

  Database? _db;

  // ── Init dbs ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stations (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        latitude    REAL NOT NULL,
        longitude   REAL NOT NULL,
        lineName    TEXT NOT NULL,
        isFavourite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE incident_reports (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id  TEXT NOT NULL,
        timestamp   TEXT NOT NULL,
        rate        INTEGER NOT NULL,
        type        TEXT NOT NULL,
        notes       TEXT,
        FOREIGN KEY (station_id) REFERENCES stations(id)
      )
    ''');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<IncidentReport>> getIncidentsForStation(
      String stationId,
      ) async {
    final rows = await _db!.query(
      'incident_reports',
      where: 'station_id = ?',
      whereArgs: [stationId],
    );
    return rows.map((row) => IncidentReport.fromDB(row)).toList();
  }

  // ── MetroDataSource ───────────────────────────────────────────────────────

  @override
  Future<void> insertStation(Station station) async {
    await _db!.insert(
      'stations',
      station.toDB(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> attachIncident(String stationId, IncidentReport report) async {
    await _db!.insert('incident_reports', report.toDB(stationId));
  }

  @override
  Future<List<Station>> getAllStations() async {
    final rows = await _db!.query('stations');
    return Future.wait(
      rows.map((row) async {
        final incidents = await getIncidentsForStation(row['id'] as String);
        return Station.fromDB(row, incidents);
      }),
    );
  }

  @override
  Future<Station> getStationDetail(String id) async {
    final rows = await _db!.query(
      'stations',
      where:     'id = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) throw Exception('Station $id not found');

    final incidents = await getIncidentsForStation(id);
    return Station.fromDB(rows.first, incidents);
  }

  @override
  Future<List<Station>> getStationsByName(String name) async {
    final rows = await _db!.query(
      'stations',
      where:     'name LIKE ?',
      whereArgs: ['%$name%'],
    );

    return Future.wait(
      rows.map((row) async {
        final incidents = await getIncidentsForStation(row['id'] as String);
        return Station.fromDB(row, incidents);
      }),
    );
  }

  // ── Favourites  ────────────────────────────────────────────────────────────


  Future<List<Station>> getFavourites() async {
    final rows = await _db!.query(
      'stations',
      where: 'isFavourite = ?',
      whereArgs: [1],
    );
    return Future.wait(
      rows.map((row) async {
        final incidents = await getIncidentsForStation(row['id'] as String);
        return Station.fromDB(row, incidents);
      }),
    );
  }

  Future<void> toggleFavourite(String stationId) async {
    final rows = await _db!.query(
      'stations',
      columns:   ['isFavourite'],
      where:     'id = ?',
      whereArgs: [stationId],
    );

    if (rows.isEmpty) throw Exception('Station $stationId not found');

    final current = (rows.first['isFavourite'] as int) == 1;
    await _db!.update(
      'stations',
      {'isFavourite': current ? 0 : 1},
      where:     'id = ?',
      whereArgs: [stationId],
    );
  }
}