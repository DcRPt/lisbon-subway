import 'package:cmproject/data/app_colors.dart';
import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/screens/station_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../connectivity_module.dart';
import '../data/http_metro_datasource.dart';
import '../data/sqflite_metro_datasource.dart';
import 'list_screen.dart';

String _destinationName(String id) {
  if (id == '10') return 'Reboleira';
  if (id == '20') return 'Santa Apolónia';
  return id;
}

Color _colorForLine(String lineName) =>
    AppColors.kLineColors[lineName.toLowerCase()] ?? AppColors.kGrey;

const _mockUserLat = 38.7169;
const _mockUserLng = -9.1399;

double _distanceKm(double? lat, double? lng) {
  if (lat == null || lng == null) return double.maxFinite;
  const r = 6371.0;
  final dLat = (lat - _mockUserLat) * pi / 180;
  final dLng = (lng - _mockUserLng) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_mockUserLat * pi / 180) * cos(lat * pi / 180) *
          sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

String _formatDistance(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

// ── Screen ────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<(List<Station>, List<Station>)> _dataFuture;

  late final MetroRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = MetroRepository(
      remote: context.read<HttpMetroDataSource>(),
      local: context.read<SqfliteMetroDataSource>(),
      connectivity: context.read<ConnectivityModule>(),
    );
    _dataFuture = Future.wait([
      _repo.getAllStations(),
      _repo.getFavourites(),
    ]).then((results) => (results[0], results[1]));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final (stations, favourites) = snapshot.data!;
        return _buildContent(context, stations, favourites);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Station> stations, List<Station> favourites) {
    final Station? nearest = stations.isEmpty
        ? null
        : stations.firstWhere(
          (s) => s.name == 'Marquês de Pombal',
      orElse: () => stations.first,
    );

    final now = DateTime.now();
    final Map<String, bool> lineDisrupted = {};
    for (final s in stations) {
      final key = s.lineName;
      if (lineDisrupted[key] != true) {
        lineDisrupted[key] = s.reports.any(
              (r) => now.difference(r.timestamp).inHours < 24,
        );
      }
    }

    return Scaffold(
      key: const Key('dashboard-screen'),
      backgroundColor: AppColors.kLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('ESTADO DA LINHA', _networkGrid(context, lineDisrupted)),
            const SizedBox(height: 20),
            _section('ESTAÇÃO MAIS PRÓXIMA', _stationCard(context, nearest)),
            const SizedBox(height: 20),
            _section('FAVORITOS', _favList(context, favourites),
                icon: Icons.star_rounded),
            const SizedBox(height: 20),
            _section('MAPA DO METRO', _subwayMap(context),
                icon: Icons.map_rounded),
          ],
        ),
      ),
    );
  }

  // ── Shared ───────────────────────────────────────────────────────────────

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

  Widget _timeChips(List<String> times, {Key? rowKey}) => Row(
    key: rowKey,
    children: times.map((t) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.kLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15,
            color: Color(0xFF111827),
          )),
          const Text('min', style: TextStyle(
            fontSize: 10, color: Color(0xFF9CA3AF),
          )),
        ]),
      ),
    )).toList(),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // NETWORK STATUS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _networkGrid(BuildContext context, Map<String, bool> lineDisrupted) =>
      GridView.count(
        key: const Key('dashboard-network-grid'),
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 2.8,
        children: lineDisrupted.entries
            .map((e) => _lineCard(context, e.key, e.value))
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
                  disrupted ? 'Disrupted' : 'Normal',
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
                child: const Icon(
                  Icons.priority_high_rounded, size: 10, color: Colors.white,
                ),
              ),
            ),
          _navArrow(),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEAREST STATION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _stationCard(BuildContext context, Station? station) {
    if (station == null) {
      return Container(
        key: const Key('dashboard-nearest-empty'),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('No stations available.',
            style: TextStyle(color: AppColors.kGrey, fontSize: 13)),
      );
    }

    final color = _colorForLine(station.lineName);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                _dot(color, size: 10),
                const SizedBox(width: 8),
                Text(station.name,
                  key: const Key('dashboard-nearest-name'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ]),
              Row(children: [
                Text('320 m',
                  key: const Key('dashboard-nearest-distance'),
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(width: 2),
                _navArrow(),
              ]),
            ],
          ),
          if (station.waitingTimes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),
            for (int i = 0; i < station.waitingTimes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _platformRow(
                  i,
                  _destinationName(station.waitingTimes[i].destinationId),
                  station.waitingTimes[i].arrivalsMinutes.map((m) => '$m').toList(),
                ),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _platformRow(int index, String dest, List<String> times) => Row(
    key: Key('dashboard-platform-row-$index'),
    children: [
      Expanded(
        child: Text('→ $dest',
          key: Key('dashboard-platform-dest-$index'),
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ),
      _timeChips(times, rowKey: Key('dashboard-platform-chips-$index')),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // FAVOURITES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _favList(BuildContext context, List<Station> favourites) {
    if (favourites.isEmpty) {
      return Container(
        key: const Key('dashboard-favourites-empty'),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('No favourites yet.',
            style: TextStyle(color: AppColors.kGrey, fontSize: 13)),
      );
    }
    return Column(
      key: const Key('dashboard-favourites-list'),
      children: favourites.map((s) => _favCard(context, s)).toList(),
    );
  }

  Widget _favCard(BuildContext context, Station station) {
    final color = _colorForLine(station.lineName);
    final avg = station.averageRating;
    final hasIncidents = station.reports.isNotEmpty;

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
                  _favTitle(station),
                  const SizedBox(height: 6),
                  _favDetails(station, color),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // severity badge
            if (hasIncidents) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: severityBg(),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: severityFg().withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: severityFg(),
                    ),
                  ),
                ),
              ),
            ],
            _navArrow(),
          ]),
        ),
      ),
    );
  }

  Widget _favTitle(Station station) => Row(children: [
    Text(station.name,
      key: Key('dashboard-fav-name-${station.id}'),
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    if (station.isFavourite) ...[
      const SizedBox(width: 5),
      const Icon(Icons.star_rounded, size: 14, color: AppColors.kYellow),
    ],
  ]);

  Widget _favDetails(Station station, Color color) {
    final distance = _distanceKm(station.latitude, station.longitude);

    return Row(children: [
      _dot(color, size: 8),
      const SizedBox(width: 5),
      Text(
        station.lineName,
        key: Key('dashboard-fav-line-${station.id}'),
        style: const TextStyle(fontSize: 12, color: AppColors.kGrey),
      ),
      const SizedBox(width: 8),
      const Text('·', style: TextStyle(fontSize: 12, color: AppColors.kGrey)),
      const SizedBox(width: 8),
      const Icon(Icons.near_me_outlined, size: 11, color: Color(0xFF9CA3AF)),
      const SizedBox(width: 3),
      Text(
        _formatDistance(distance),
        style: const TextStyle(fontSize: 12, color: AppColors.kGrey),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Subway Line Map
  // ─────────────────────────────────────────────────────────────────────────

  void _openLineMapFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.asset(
                'assets/images/subway-line-map.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
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
                      color: Colors.white, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subwayMap(BuildContext context) => InkWell(
    onTap: () => _openLineMapFullscreen(context),
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