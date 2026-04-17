import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/data/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

String _destinationName(String id) {
  if (id == '10') return 'Reboleira';
  if (id == '20') return 'Santa Apolónia';
  return id;
}

Color _colorForLine(String lineName) =>
    AppColors.kLineColors[lineName.toLowerCase()] ?? AppColors.kGrey;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo       = context.watch<MetroRepository>();
    final stations   = repo.getAllStations();
    final favourites = repo.getFavourites();

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
            _section('NETWORK STATUS', _networkGrid(context, lineDisrupted)),
            const SizedBox(height: 20),
            _section('NEAREST STATION', _stationCard(context, nearest)),
            const SizedBox(height: 20),
            _section('FAVOURITES', _favList(context, favourites),
                icon: Icons.star_rounded),
          ],
        ),
      ),
    );
  }

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

  Widget _timeChips(List<String> times) => Row(
    children: times.map((t) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.kLight, borderRadius: BorderRadius.circular(10),
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

  Widget _networkGrid(BuildContext context, Map<String, bool> lineDisrupted) =>
      GridView.count(
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
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: _cardDecoration(
          color: disrupted ? const Color(0xFFFFF7ED) : Colors.white,
          border: disrupted ? Border.all(color: AppColors.kYellow, width: 1.5) : null,
        ),
        child: Row(children: [
          _dot(color, size: 10),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lineName, style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13,
                )),
                Text(
                  disrupted ? 'Disrupted' : 'Normal',
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

  Widget _stationCard(BuildContext context, Station? station) {
    if (station == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('No stations available.',
            style: TextStyle(color: AppColors.kGrey, fontSize: 13)),
      );
    }

    final color = _colorForLine(station.lineName);

    return GestureDetector(
      onTap: () {},
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
                Text(station.name, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15,
                )),
              ]),
              Row(children: [
                Text('320 m', style: TextStyle(
                  color: Colors.grey[500], fontSize: 13,
                )),
                const SizedBox(width: 2),
                _navArrow(),
              ]),
            ],
          ),
          if (station.waitingTimes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 14),
            ...station.waitingTimes.map((wt) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _platformRow(
                _destinationName(wt.destinationId),
                wt.arrivalsMinutes.map((m) => '$m').toList(),
              ),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _platformRow(String dest, List<String> times) => Row(
    children: [
      Expanded(
        child: Text('→ $dest', style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        )),
      ),
      _timeChips(times),
    ],
  );

  Widget _favList(BuildContext context, List<Station> favourites) {
    if (favourites.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text('No favourites yet.',
            style: TextStyle(color: AppColors.kGrey, fontSize: 13)),
      );
    }
    return Column(
      children: favourites.map((s) => _favCard(context, s)).toList(),
    );
  }

  Widget _favCard(BuildContext context, Station station) {
    final color = _colorForLine(station.lineName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {},
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
            const SizedBox(width: 6),
            _navArrow(),
          ]),
        ),
      ),
    );
  }

  Widget _favTitle(Station station) => Row(children: [
    Text(station.name, style: const TextStyle(
      fontWeight: FontWeight.w700, fontSize: 14,
    )),
    if (station.isFavourite) ...[
      const SizedBox(width: 5),
      const Icon(Icons.star_rounded, size: 14, color: AppColors.kYellow),
    ],
  ]);

  Widget _favDetails(Station station, Color color) => Row(children: [
    _dot(color, size: 8),
    const SizedBox(width: 5),
    Text(station.lineName, style: const TextStyle(fontSize: 12, color: AppColors.kGrey)),
    const SizedBox(width: 8),
    const Icon(Icons.directions_walk_rounded, size: 13, color: Color(0xFF9CA3AF)),
    const SizedBox(width: 3),
    const Text('6 min', style: TextStyle(fontSize: 12, color: AppColors.kGrey)),
  ]);
}