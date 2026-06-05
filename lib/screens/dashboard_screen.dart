import 'dart:math';

import 'package:cmproject/data/app_colors.dart';
import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/line_status.dart';
import 'package:cmproject/models/waiting_time.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/screens/station_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../connectivity_module.dart';
import '../data/generic_data_source.dart';
import '../data/http_metro_datasource.dart';
import '../data/sqflite_metro_datasource.dart';
import '../location_module.dart';
import 'list_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _colorForLine(String lineName) =>
    AppColors.kLineColors[lineName.toLowerCase()] ?? AppColors.kGrey;

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

String _formatDistance(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

// ── Data bundle loaded once ───────────────────────────────────────────────────

class _DashboardData {
  final List<Station>    stations;
  final List<Station>    favourites;
  final List<LineStatus> lineStatuses;
  final Map<String, String> destinations; // id → name from API
  final LocationData?    location;

  const _DashboardData({
    required this.stations,
    required this.favourites,
    required this.lineStatuses,
    required this.destinations,
    required this.location,
  });

  // Nearest station to the user's GPS position
  Station? get nearest {
    if (stations.isEmpty) return null;
    if (location?.latitude == null || location?.longitude == null) {
      return stations.first;
    }
    return stations.reduce((a, b) {
      final da = _distanceKm(location!.latitude!, location!.longitude!, a.latitude, a.longitude);
      final db = _distanceKm(location!.latitude!, location!.longitude!, b.latitude, b.longitude);
      return da < db ? a : b;
    });
  }

  double? distanceTo(Station s) {
    if (location?.latitude == null || location?.longitude == null) return null;
    return _distanceKm(location!.latitude!, location!.longitude!, s.latitude, s.longitude);
  }

  bool isLineDisrupted(String lineName) {
    final status = lineStatuses.firstWhere(
          (ls) => ls.lineName.toLowerCase() == lineName.toLowerCase(),
      orElse: () => const LineStatus(lineName: '', status: '', shortStatus: 'normal'),
    );
    return !status.isNormal;
  }

  String destinationName(String id) => destinations[id] ?? id;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final MetroRepository _repo;
  late final LocationModule  _location;
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _location = context.read<LocationModule>();
    _repo = MetroRepository(
      remote:       context.read<HttpMetroDataSource>(),
      local:        context.read<SqfliteMetroDataSource>(),
      connectivity: context.read<ConnectivityModule>(),
      generic:      context.read<GenericDataSource>(),
    );
    _dataFuture = _load();
  }

  Future<_DashboardData> _load() async {
    // Location uses a short timeout so an empty stream (e.g. in tests where
    // FakeLocationModule returns Stream.empty()) resolves immediately instead
    // of blocking pumpAndSettle for the full duration.
    final locationFuture = _location
        .onLocationChanged()
        .first
        .timeout(const Duration(seconds: 8), onTimeout: () => LocationData.fromMap({}))
        .catchError((_) => LocationData.fromMap({}));

    final results = await Future.wait([
      _repo.getAllStations(),
      _repo.getFavourites(),
      _repo.getAllLineStatuses(),
      _repo.getDestinations(),
      locationFuture,
    ]);

    final stations     = results[0] as List<Station>;
    final favourites   = results[1] as List<Station>;
    final lineStatuses = results[2] as List<LineStatus>;
    final destinations = results[3] as Map<String, String>;
    final location     = results[4] as LocationData;

    Station? nearest;
    if (stations.isNotEmpty) {
      if (location.latitude != null && location.longitude != null) {
        nearest = stations.reduce((a, b) {
          final da = _distanceKm(location.latitude!, location.longitude!, a.latitude, a.longitude);
          final db = _distanceKm(location.latitude!, location.longitude!, b.latitude, b.longitude);
          return da < db ? a : b;
        });
      } else {
        nearest = stations.first;
      }

      final waitingTimes = await _repo.getWaitingTimes(nearest.id)
          .timeout(const Duration(seconds: 3), onTimeout: () => [])
          .catchError((_) => <WaitingTime>[]);
      if (waitingTimes.isNotEmpty) {
        final enriched = Station(
          id:           nearest.id,
          name:         nearest.name,
          latitude:     nearest.latitude,
          longitude:    nearest.longitude,
          lineName:     nearest.lineName,
          isFavourite:  nearest.isFavourite,
          reports:      nearest.reports,
          waitingTimes: waitingTimes,
        );
        final idx = stations.indexWhere((s) => s.id == enriched.id);
        if (idx != -1) stations[idx] = enriched;
      }
    }

    return _DashboardData(
      stations:     stations,
      favourites:   favourites,
      lineStatuses: lineStatuses,
      destinations: destinations,
      location:     location,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildContent(BuildContext context, _DashboardData data) {
    final lineNames = data.stations.map((s) => s.lineName).toSet();

    return Scaffold(
      key: const Key('dashboard-screen'),
      backgroundColor: AppColors.kLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('ESTADO DA LINHA',
                _networkGrid(context, lineNames, data)),
            const SizedBox(height: 20),
            _section('ESTAÇÃO MAIS PRÓXIMA',
                _stationCard(context, data.nearest, data)),
            const SizedBox(height: 20),
            _section('FAVORITOS',
                _favList(context, data.favourites, data),
                icon: Icons.star_rounded),
            const SizedBox(height: 20),
            _section('MAPA DO METRO',
                _subwayMap(context),
                icon: Icons.map_rounded),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _section(String label, Widget child, {IconData? icon}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppColors.kGrey),
          const SizedBox(width: 4),
        ],
        Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 0.8, color: AppColors.kGrey,
        )),
      ]),
      const SizedBox(height: 10),
      child,
    ],
  );

  BoxDecoration _cardDecoration({Color color = Colors.white, Border? border}) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      );

  Widget _navArrow() => const Icon(
    Icons.chevron_right_rounded, size: 18, color: Color(0xFFD1D5DB),
  );

  Widget _dot(Color color, {double size = 8}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _timeChips(List<int> minutes, {Key? rowKey}) => Row(
    key: rowKey,
    children: minutes.map((m) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.kLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$m', style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87,
          )),
          const Text('min', style: TextStyle(
            fontSize: 10, color: AppColors.kFieldText,
          )),
        ]),
      ),
    )).toList(),
  );

  // ── Network status ────────────────────────────────────────────────────────

  Widget _networkGrid(BuildContext context, Set<String> lineNames, _DashboardData data) =>
      GridView.count(
        key: const Key('dashboard-network-grid'),
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 2.8,
        children: lineNames
            .map((name) => _lineCard(context, name, data.isLineDisrupted(name)))
            .toList(),
      );

  Widget _lineCard(BuildContext context, String lineName, bool disrupted) {
    final color = _colorForLine(lineName);
    return InkWell(
      key: Key('dashboard-line-card-$lineName'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ListScreen(initialLine: lineName),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: _cardDecoration(
          color: disrupted ? const Color(0xFFFFF7ED) : Colors.white,
          border: disrupted
              ? Border.all(color: AppColors.kYellow, width: 1.5)
              : null,
        ),
        child: Row(children: [
          _dot(color, size: 10),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lineName,
                  key: Key('dashboard-line-name-$lineName'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  disrupted ? 'Perturbado' : 'Normal',
                  key: Key('dashboard-line-status-$lineName'),
                  style: TextStyle(
                    fontSize: 11,
                    color: disrupted ? AppColors.kYellow : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (disrupted)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.kYellow, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high_rounded,
                    size: 10, color: Colors.white),
              ),
            ),
          _navArrow(),
        ]),
      ),
    );
  }

  // ── Nearest station ───────────────────────────────────────────────────────

  Widget _stationCard(BuildContext context, Station? station, _DashboardData data) {
    if (station == null) {
      return Container(
        key: const Key('dashboard-nearest-empty'),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('Sem estações disponíveis.',
            style: TextStyle(color: AppColors.kGrey, fontSize: 13)),
      );
    }

    final color = _colorForLine(station.lineName);
    final distance = data.distanceTo(station);

    return InkWell(
      key: const Key('dashboard-nearest-card'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StationDetailScreen(station: station),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                // Coloured left-edge accent bar instead of dot + pill
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.name,
                      key: const Key('dashboard-nearest-name'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Linha ${station.lineName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ]),
              Row(children: [
                if (distance != null) ...[
                  const Icon(Icons.near_me_outlined, size: 12, color: AppColors.kGrey),
                  const SizedBox(width: 3),
                  Text(
                    _formatDistance(distance),
                    key: const Key('dashboard-nearest-distance'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(width: 2),
                ],
                _navArrow(),
              ]),
            ],
          ),
          // ── Waiting times ────────────────────────────────────────────
          if (station.waitingTimes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),
            for (int i = 0; i < station.waitingTimes.length; i += 2) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  _platformRow(i,
                    data.destinationName(station.waitingTimes[i].destinationId),
                    station.waitingTimes[i].arrivalsMinutes,
                  ),
                  if (i + 1 < station.waitingTimes.length) ...[
                    Divider(height: 1, color: Colors.black.withValues(alpha: 0.06), indent: 0, endIndent: 0),
                    _platformRow(i + 1,
                      data.destinationName(station.waitingTimes[i + 1].destinationId),
                      station.waitingTimes[i + 1].arrivalsMinutes,
                    ),
                  ],
                ]),
              ),
              if (i + 2 < station.waitingTimes.length) const SizedBox(height: 10),
            ],
          ],
        ]),
      ),
    );
  }

  Widget _platformRow(int index, String dest, List<int> minutes) => Padding(
    key: Key('dashboard-platform-row-$index'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(dest,
            key: Key('dashboard-platform-dest-$index'),
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151),
            ),
          ),
        ),
        _timeChips(minutes, rowKey: Key('dashboard-platform-chips-$index')),
      ],
    ),
  );

  // ── Favourites ────────────────────────────────────────────────────────────

  Widget _favList(BuildContext context, List<Station> favourites, _DashboardData data) {
    if (favourites.isEmpty) {
      return Container(
        key: const Key('dashboard-favourites-empty'),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('Sem favoritos.',
            style: TextStyle(color: AppColors.kGrey, fontSize: 13)),
      );
    }
    return Column(
      key: const Key('dashboard-favourites-list'),
      children: favourites.map((s) => _favCard(context, s, data)).toList(),
    );
  }

  Widget _favCard(BuildContext context, Station station, _DashboardData data) {
    final color = _colorForLine(station.lineName);
    final avg = station.averageRating;
    final hasIncidents = station.reports.isNotEmpty;
    final distance = data.distanceTo(station);

    Color severityBg() {
      if (!hasIncidents) return Colors.transparent;
      if (avg < 2) return AppColors.kSuccessGreen.withValues(alpha: 0.12);
      if (avg < 4) return AppColors.kYellow.withValues(alpha: 0.12);
      return AppColors.kErrorRed.withValues(alpha: 0.12);
    }

    Color severityFg() {
      if (!hasIncidents) return AppColors.kGrey;
      if (avg < 2) return AppColors.kSuccessGreen;
      if (avg < 4) return AppColors.kYellow;
      return AppColors.kErrorRed;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: Key('dashboard-fav-card-${station.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StationDetailScreen(station: station),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: _cardDecoration(),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(station.name,
                      key: Key('dashboard-fav-name-${station.id}'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    if (station.isFavourite) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.kYellow),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    _dot(color, size: 8),
                    const SizedBox(width: 5),
                    Text(station.lineName,
                      key: Key('dashboard-fav-line-${station.id}'),
                      style: const TextStyle(fontSize: 12, color: AppColors.kGrey),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      const Text('·', style: TextStyle(fontSize: 12, color: AppColors.kGrey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.near_me_outlined, size: 11, color: AppColors.kGrey),
                      const SizedBox(width: 3),
                      Text(_formatDistance(distance),
                          style: const TextStyle(fontSize: 12, color: AppColors.kGrey)),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasIncidents)
              Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: severityBg(),
                  shape: BoxShape.circle,
                  border: Border.all(color: severityFg().withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(avg.toStringAsFixed(1),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: severityFg()),
                  ),
                ),
              ),
            _navArrow(),
          ]),
        ),
      ),
    );
  }

  // ── Subway map ────────────────────────────────────────────────────────────

  Widget _subwayMap(BuildContext context) => InkWell(
    onTap: () => showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(children: [
          InteractiveViewer(
            minScale: 0.5, maxScale: 4.0,
            child: Image.asset('assets/images/subway-line-map.png',
                fit: BoxFit.contain,
                width: double.infinity, height: double.infinity),
          ),
          Positioned(
            top: 16, right: 16,
            child: SafeArea(
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
            ),
          ),
        ]),
      ),
    ),
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.hardEdge,
      child: Image.asset(
        'assets/images/subway-line-map.png',
        fit: BoxFit.contain,
      ),
    ),
  );
}