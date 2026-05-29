import 'dart:async';
import 'dart:math';

import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/location_module.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/screens/station_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../connectivity_module.dart';
import '../data/app_colors.dart';
import '../data/generic_data_source.dart';
import '../data/http_metro_datasource.dart';
import '../data/sqflite_metro_datasource.dart';
import '../models/line_status.dart';

const _mockUserLat = 38.7169;
const _mockUserLng = -9.1399;

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

enum _SortBy { distance, name, severity }

extension _SortByExt on _SortBy {
  String get label => switch (this) {
    _SortBy.distance => 'Distância',
    _SortBy.name => 'Nome',
    _SortBy.severity => 'Severidade',
  };
  IconData get icon => switch (this) {
    _SortBy.distance => Icons.near_me_outlined,
    _SortBy.name => Icons.sort_by_alpha,
    _SortBy.severity => Icons.warning_amber_rounded,
  };
}

const _radiusOptions = <double?>[null, 0.5, 1.0, 2.0, 5.0];

String _radiusLabel(double? r) => switch (r) {
  null => 'Qualquer',
  0.5 => '500 m',
  1.0 => '1 km',
  2.0 => '2 km',
  _ => '5 km',
};

Color _lineColor(String lineName) {
  final l = lineName.toLowerCase();
  if (l.contains('azul') || l.contains('blue')) return const Color(0xFF0057A8);
  if (l.contains('amar') || l.contains('yellow')) return AppColors.kYellow;
  if (l.contains('verd') || l.contains('green')) return const Color(0xFF00A89D);
  if (l.contains('verm') || l.contains('red')) return const Color(0xFFEE1D23);
  return AppColors.kGrey;
}

class _Filters {
  _SortBy sortBy = _SortBy.name;
  bool noIncidentsOnly = false;
  int maxSeverity = 5;
  bool severityAtLeast = false;
  Set<IncidentType> excludedTypes = <IncidentType>{};
  double? radiusKm;

  int get activeCount {
    int n = 0;
    if (sortBy != _SortBy.distance) n++;
    if (noIncidentsOnly) n++;
    if (maxSeverity < 5 || severityAtLeast) n++;
    if (excludedTypes.isNotEmpty) n++;
    if (radiusKm != null) n++;
    return n;
  }

  void reset() {
    sortBy = _SortBy.distance;
    noIncidentsOnly = false;
    maxSeverity = 5;
    severityAtLeast = false;
    excludedTypes = <IncidentType>{};
    radiusKm = null;
  }
}

class ListScreen extends StatefulWidget {
  final String? initialLine;
  const ListScreen({super.key, this.initialLine});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _selectedLine;
  final _filters = _Filters();
  bool _favoritesOnly = false;
  List<Station> _allStations = [];
  List<LineStatus> _lineStatuses = [];
  bool _loading = true;
  double? _userLat;
  double? _userLng;

  late final MetroRepository _repo;
  late final LocationModule _location;

  @override
  void initState() {
    super.initState();
    _location = context.read<LocationModule>();
    _repo = MetroRepository(
      remote: context.read<HttpMetroDataSource>(),
      local: context.read<SqfliteMetroDataSource>(),
      connectivity: context.read<ConnectivityModule>(),
      generic: context.read<GenericDataSource>(),
    );
    if (widget.initialLine != null) _selectedLine = widget.initialLine;
    _loadStations();
  }

  Future<void> _loadStations() async {
    final results = await Future.wait([
      _repo.getAllStations(),
      _repo.getAllLineStatuses(),
    ]);

    final loc = await _location.onLocationChanged().first
        .timeout(const Duration(seconds: 8), onTimeout: () => LocationData.fromMap({}))
        .catchError((_) => LocationData.fromMap({}));

    if (!mounted) return;
    setState(() {
      _allStations = results[0] as List<Station>;
      _lineStatuses = results[1] as List<LineStatus>;
      _userLat = loc.latitude;
      _userLng = loc.longitude;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  List<Station> _filtered(List<Station> all) {
    final results = all.where((s) {
      if (_query.isNotEmpty && !s.name.toLowerCase().contains(_query)) {
        return false;
      }
      if (_favoritesOnly && !s.isFavourite) {
        return false;
      }
      if (_selectedLine != null &&
          !s.lineName.toLowerCase().contains(_selectedLine!.toLowerCase())) {
        return false;
      }
      if (_filters.radiusKm != null &&
          _distanceKm(
            _userLat ?? _mockUserLat,
            _userLng ?? _mockUserLng,
            s.latitude,
            s.longitude,
          ) > _filters.radiusKm!) {
        return false;
      }
      if (_filters.noIncidentsOnly && s.reports.isNotEmpty) {
        return false;
      }
      if (!_filters.noIncidentsOnly && s.reports.isNotEmpty) {
        final avg = s.averageRating;
        if (_filters.severityAtLeast && avg < _filters.maxSeverity) return false;
        if (!_filters.severityAtLeast && avg > _filters.maxSeverity) return false;
      }
      if (_filters.excludedTypes.isNotEmpty &&
          s.reports.isNotEmpty &&
          s.reports.every((r) => _filters.excludedTypes.contains(r.type))) {
        return false;
      }
      return true;
    }).toList();

    switch (_filters.sortBy) {
      case _SortBy.distance:
        results.sort((a, b) {
          final aDistance = _distanceKm(
            _userLat ?? _mockUserLat,
            _userLng ?? _mockUserLng,
            a.latitude,
            a.longitude,
          );
          final bDistance = _distanceKm(
            _userLat ?? _mockUserLat,
            _userLng ?? _mockUserLng,
            b.latitude,
            b.longitude,
          );
          return aDistance.compareTo(bDistance);
        });
      case _SortBy.name:
        results.sort((a, b) => a.name.compareTo(b.name));
      case _SortBy.severity:
        results.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    }

    return results;
  }

  List<String> _lines(List<Station> all) {
    final seen = <String>{};
    return all.map((s) => s.lineName).where(seen.add).toList();
  }

  void _showFilterSheet() {
    final draft = _Filters()
      ..sortBy = _filters.sortBy
      ..noIncidentsOnly = _filters.noIncidentsOnly
      ..maxSeverity = _filters.maxSeverity
      ..severityAtLeast = _filters.severityAtLeast
      ..excludedTypes = Set<IncidentType>.from(_filters.excludedTypes)
      ..radiusKm = _filters.radiusKm;

    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFFFAFAF8),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.kFieldBorder,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtros e ordenação',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      TextButton(
                        key: const Key('list-filter-clear'),
                        onPressed: () => setSheet(() => draft.reset()),
                        child: Text('Limpar',
                            style: TextStyle(color: AppColors.kNavyBlue, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _sectionLabel('Ordenar por'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _SortBy.values.map((o) {
                      final sel = draft.sortBy == o;
                      return _sheetChip(
                        o.label, sel,
                        chipKey: Key('list-sort-chip-${o.name}'),
                        icon: o.icon,
                        onTap: () => setSheet(() => draft.sortBy = o),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 28),
                  _sectionLabel('Raio de distância'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _radiusOptions.map((r) {
                      final sel = draft.radiusKm == r;
                      return _sheetChip(_radiusLabel(r), sel,
                          onTap: () => setSheet(() => draft.radiusKm = r));
                    }).toList(),
                  ),
                  const Divider(height: 28),
                  _sectionLabel('Estado'),
                  const SizedBox(height: 8),
                  _sheetToggleTile(
                    icon: Icons.check_circle_outline,
                    label: 'Apenas sem incidentes',
                    value: draft.noIncidentsOnly,
                    onChanged: (v) => setSheet(() {
                      draft.noIncidentsOnly = v;
                      if (v) {
                        draft.maxSeverity = 5;
                        draft.excludedTypes = <IncidentType>{};
                      }
                    }),
                  ),
                  if (!draft.noIncidentsOnly) ...[
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel('Severidade'),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.kFieldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.kFieldBorder),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _directionButton('≤ Máximo', !draft.severityAtLeast,
                                onTap: () => setSheet(() => draft.severityAtLeast = false)),
                            _directionButton('≥ Mínimo', draft.severityAtLeast,
                                onTap: () => setSheet(() => draft.severityAtLeast = true)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(
                        draft.severityAtLeast
                            ? 'Mostrar severidade ≥ ${draft.maxSeverity}'
                            : 'Mostrar severidade ≤ ${draft.maxSeverity}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kNavyBlue),
                      ),
                    ]),
                    SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        activeTrackColor: AppColors.kNavyBlue,
                        thumbColor: AppColors.kNavyBlue,
                        inactiveTrackColor: AppColors.kFieldBorder,
                        overlayColor: AppColors.kNavyBlue.withValues(alpha: 0.1),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: draft.maxSeverity.toDouble(),
                        min: 1, max: 5, divisions: 4,
                        onChanged: (v) => setSheet(() => draft.maxSeverity = v.round()),
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1 – Menor', style: TextStyle(fontSize: 11, color: AppColors.kGrey)),
                        Text('5 – Crítico', style: TextStyle(fontSize: 11, color: AppColors.kGrey)),
                      ],
                    ),
                    const Divider(height: 28),
                    _sectionLabel('Tipo de incidente'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: IncidentType.values.map((t) {
                        final active = !draft.excludedTypes.contains(t);
                        return _sheetChip(t.displayName, active,
                            onTap: () => setSheet(() {
                              if (active) {
                                draft.excludedTypes.add(t);
                              } else {
                                draft.excludedTypes.remove(t);
                              }
                            }));
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      key: const Key('list-filter-apply'),
                      onPressed: () {
                        setState(() {
                          _filters.sortBy = draft.sortBy;
                          _filters.noIncidentsOnly = draft.noIncidentsOnly;
                          _filters.maxSeverity = draft.maxSeverity;
                          _filters.severityAtLeast = draft.severityAtLeast;
                          _filters.excludedTypes = Set<IncidentType>.from(draft.excludedTypes);
                          _filters.radiusKm = draft.radiusKm;
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kNavyBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Aplicar',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }

  Widget _directionButton(String label, bool selected, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.kNavyBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.kGrey)),
        ),
      );

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kGrey));

  Widget _sheetChip(String label, bool selected,
      {IconData? icon, required VoidCallback onTap, Key? chipKey}) =>
      GestureDetector(
        key: chipKey,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.kNavyBlue : AppColors.kFieldBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.kNavyBlue : AppColors.kFieldBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : AppColors.kGrey),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.kGrey)),
          ]),
        ),
      );

  Widget _sheetToggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Row(children: [
        Icon(icon, size: 18, color: value ? AppColors.kNavyBlue : AppColors.kGrey),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: value ? AppColors.kNavyBlue : const Color(0xFF1A1A2E),
                    fontWeight: value ? FontWeight.w600 : FontWeight.w400))),
        Switch(
          key: const Key('list-filter-no-incidents-switch'),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.kNavyBlue,
        ),
      ]);

  Widget _searchBar() => TextField(
    controller: _searchController,
    onChanged: _onSearch,
    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
    decoration: InputDecoration(
      hintText: 'Pesquisar estação...',
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.kGrey),
      prefixIcon: const Icon(Icons.search, color: AppColors.kGrey, size: 20),
      filled: true,
      fillColor: AppColors.kFieldBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kFieldBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kFieldBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kNavyBlue, width: 1.5)),
    ),
  );

  Widget _disruptionBanner() {
    final disrupted = _lineStatuses.where((ls) => !ls.isNormal).toList();
    final names = disrupted.map((ls) => ls.lineName[0].toUpperCase() + ls.lineName.substring(1)).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.kYellow),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.kYellow, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
              disrupted.length == 1
                  ? 'Perturbação ativa na linha $names.'
                  : 'Perturbações ativas nas linhas $names.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
            )),
      ]),
    );
  }

  Widget _favoritesTabs() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.kFieldBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.kFieldBorder),
    ),
    child: Row(children: [
      Expanded(
        child: GestureDetector(
          key: const Key('list-tab-all'),
          onTap: () => setState(() => _favoritesOnly = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: !_favoritesOnly ? AppColors.kNavyBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('Todos',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !_favoritesOnly ? Colors.white : AppColors.kGrey)),
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          key: const Key('list-tab-favourites'),
          onTap: () => setState(() => _favoritesOnly = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _favoritesOnly ? AppColors.kNavyBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('⭐ Favoritos',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _favoritesOnly ? Colors.white : AppColors.kGrey)),
            ),
          ),
        ),
      ),
    ]),
  );

  Widget _lineChips(List<String> lines) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Linhas',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kGrey)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          _lineChip('Todas', null),
          ...lines.map((l) => _lineChip(l, l)),
        ],
      ),
    ],
  );

  String _stripLinha(String name) =>
      name.replaceAll(RegExp(r'linha\s*', caseSensitive: false), '').trim();

  Widget _lineChip(String label, String? value) {
    final selected = _selectedLine == value;
    final displayLabel = value != null ? _stripLinha(label) : label;
    return GestureDetector(
      key: value != null
          ? Key('list-line-chip-$value')
          : const Key('list-line-chip-all'),
      onTap: () => setState(() => _selectedLine = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.kNavyBlue : AppColors.kFieldBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.kNavyBlue : AppColors.kFieldBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (value != null) ...[
            Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _lineColor(value), shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(displayLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.kGrey)),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(List<String> lines, bool hasDisruption) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _searchBar(),
      if (hasDisruption) ...[
        const SizedBox(height: 10),
        _disruptionBanner(),
      ],
      const SizedBox(height: 10),
      _favoritesTabs(),
      const SizedBox(height: 10),
      _lineChips(lines),
    ]),
  );

  String _fullLineName(String lineName) {
    final l = lineName.toLowerCase();
    if (l.startsWith('linha')) return lineName;
    return 'Linha $lineName';
  }

  Future<void> _toggleFavourite(String stationId) async {
    await _repo.toggleFavourite(stationId);
    if (!mounted) return;
    final stations = await _repo.getAllStations();
    if (!mounted) return;
    setState(() => _allStations = stations);
  }

  Widget _stationTile(Station station) {
    final distance = _distanceKm(
      _userLat ?? _mockUserLat,
      _userLng ?? _mockUserLng,
      station.latitude,
      station.longitude,
    );
    final fullLine = _fullLineName(station.lineName);
    final avg = station.averageRating;
    final hasIncidents = station.reports.isNotEmpty;

    Color severityBg() {
      if (!hasIncidents) return AppColors.kFieldBg;
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

    return ListTile(
      key: Key('list-station-tile-${station.id}'),
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StationDetailScreen(station: station),
        ));
        // Refresh in case favourite was toggled in the detail screen
        if (!mounted) return;
        final stations = await _repo.getAllStations();
        if (!mounted) return;
        setState(() => _allStations = stations);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        station.name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E)),
      ),
      subtitle: Row(children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: _lineColor(station.lineName), shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(fullLine,
            style: const TextStyle(fontSize: 12, color: AppColors.kGrey)),
        const SizedBox(width: 8),
        const Text('·',
            style: TextStyle(fontSize: 12, color: AppColors.kGrey)),
        const SizedBox(width: 8),
        const Icon(Icons.near_me_outlined, size: 11, color: AppColors.kGrey),
        const SizedBox(width: 3),
        Text(_formatDistance(distance),
            style: const TextStyle(fontSize: 12, color: AppColors.kGrey)),
      ]),
      // severity badge + favourite star in trailing
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIncidents)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 4),
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
                    fontSize: avg >= 10 ? 8 : 10,
                    fontWeight: FontWeight.w700,
                    color: severityFg(),
                  ),
                ),
              ),
            ),
          IconButton(
            key: Key('list-station-tile-${station.id}-favourite'),
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 80),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                station.isFavourite ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey(station.isFavourite),
                size: 22,
                color: station.isFavourite ? AppColors.kYellow : AppColors.kGrey.withValues(alpha: 0.5),
              ),
            ),
            onPressed: () => _toggleFavourite(station.id),
          ),
          const Icon(Icons.chevron_right, color: AppColors.kGrey, size: 20),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.kGrey),
        const SizedBox(height: 12),
        const Text('Nenhuma estação encontrada',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 6),
        const Text('Tente ajustar os filtros ou a pesquisa.',
            style: TextStyle(fontSize: 13, color: AppColors.kGrey),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _query = '';
            _selectedLine = null;
            _searchController.clear();
            _filters.reset();
          }),
          child: Text('Limpar tudo',
              style: TextStyle(color: AppColors.kNavyBlue, fontSize: 14)),
        ),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final all = _allStations;
    final lines = _lines(all);
    final filtered = _filtered(all);
    final hasDisruption = _lineStatuses.any((ls) => !ls.isNormal);
    final activeFilters = _filters.activeCount;

    return Scaffold(
      key: const Key('list-screen'),
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: AppColors.kNavyBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
        title: const Text('Estações',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                key: const Key('list-filter-button'),
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Filtros',
                onPressed: _showFilterSheet,
              ),
              if (activeFilters > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(
                        color: AppColors.kYellow, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$activeFilters',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        // header inside ListView
        child: ListView.builder(
          key: const Key('list-view'),
          itemCount: filtered.isEmpty ? 2 : filtered.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) return _buildHeader(lines, hasDisruption);
            if (filtered.isEmpty) return _emptyState();
            return _stationTile(filtered[i - 1]);
          },
        ),
      ),
    );
  }
}