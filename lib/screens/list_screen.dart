import 'dart:async';
import 'dart:math';

import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/models/incident_report.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/screens/station_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock user location (Lisbon city centre — swap for Geolocator later)
// ─────────────────────────────────────────────────────────────────────────────

const _mockUserLat = 38.7169;
const _mockUserLng = -9.1399;

double _distanceKm(double lat, double lng) {
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

// ─────────────────────────────────────────────────────────────────────────────
// Sort
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Radius options (km; null = no limit)
// ─────────────────────────────────────────────────────────────────────────────

const _radiusOptions = <double?>[null, 0.5, 1.0, 2.0, 5.0];

String _radiusLabel(double? r) => switch (r) {
  null => 'Qualquer',
  0.5 => '500 m',
  1.0 => '1 km',
  2.0 => '2 km',
  _ => '5 km',
};

// ─────────────────────────────────────────────────────────────────────────────
// Colours
// ─────────────────────────────────────────────────────────────────────────────

const _navy = Color(0xFF003087);
const _warmWhite = Color(0xFFFAFAF8);
const _warmSurface = Color(0xFFF2F0EB);
const _nearBlack = Color(0xFF1A1A2E);
const _muted = Color(0xFF6B6B7A);
const _borderDefault = Color(0xFFD8D6CF);
const _warnBg = Color(0xFFFFF8E1);
const _warnBorder = Color(0xFFF5A800);
const _warnIcon = Color(0xFFF5A800);

Color _lineColor(String lineName) {
  final l = lineName.toLowerCase();
  if (l.contains('azul') || l.contains('blue')) return const Color(0xFF0057A8);
  if (l.contains('amar') || l.contains('yellow')) return const Color(0xFFF5A800);
  if (l.contains('verd') || l.contains('green')) return const Color(0xFF00A89D);
  if (l.contains('verm') || l.contains('red')) return const Color(0xFFEE1D23);
  return _muted;
}

Color _severityBg(double avg) {
  if (avg == 0) return _warmSurface;
  if (avg < 2) return const Color(0xFFEDF7E3);
  if (avg < 4) return const Color(0xFFFFF8E1);
  return const Color(0xFFFCEBEB);
}

Color _severityFg(double avg) {
  if (avg == 0) return _muted;
  if (avg < 2) return const Color(0xFF2E7D6B);
  if (avg < 4) return const Color(0xFFB36B00);
  return const Color(0xFFA32D2D);
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter state
// ─────────────────────────────────────────────────────────────────────────────

class _Filters {
  _SortBy sortBy = _SortBy.distance;
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

// ─────────────────────────────────────────────────────────────────────────────
// ListScreen
// ─────────────────────────────────────────────────────────────────────────────

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

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

  @override
  void initState() {
    super.initState();
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
      if (_query.isNotEmpty && !s.name.toLowerCase().contains(_query)) return false;
      if (_favoritesOnly && !s.isFavorite) return false;
      if (_selectedLine != null &&
          !s.lineName.toLowerCase().contains(_selectedLine!.toLowerCase())) return false;
      if (_filters.radiusKm != null &&
          _distanceKm(s.latitude, s.longitude) > _filters.radiusKm!) return false;
      if (_filters.noIncidentsOnly && s.reports.isNotEmpty) return false;
      if (!_filters.noIncidentsOnly && s.reports.isNotEmpty) {
        final avg = s.averageRating;
        if (_filters.severityAtLeast && avg < _filters.maxSeverity) return false;
        if (!_filters.severityAtLeast && avg > _filters.maxSeverity) return false;
      }
      if (_filters.excludedTypes.isNotEmpty &&
          s.reports.isNotEmpty &&
          s.reports.every((r) => _filters.excludedTypes.contains(r.type))) return false;
      return true;
    }).toList();

    switch (_filters.sortBy) {
      case _SortBy.distance:
        results.sort((a, b) => _distanceKm(a.latitude, a.longitude)
            .compareTo(_distanceKm(b.latitude, b.longitude)));
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

  // ── Filter bottom sheet ───────────────────────────────────────────────────

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
      backgroundColor: _warmWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _borderDefault,
                        borderRadius: BorderRadius.circular(2)),
                  )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filtros e ordenação',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _nearBlack)),
                  TextButton(
                    onPressed: () => setSheet(() => draft.reset()),
                    child: const Text('Limpar',
                        style: TextStyle(color: _navy, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _sectionLabel('Ordenar por'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _SortBy.values.map((o) {
                  final sel = draft.sortBy == o;
                  return _sheetChip(o.label, sel,
                      icon: o.icon,
                      onTap: () => setSheet(() => draft.sortBy = o));
                }).toList(),
              ),
              const Divider(height: 28),
              _sectionLabel('Raio de distância'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
              const Divider(height: 28),
              if (!draft.noIncidentsOnly) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionLabel('Severidade'),
                    Container(
                      decoration: BoxDecoration(
                        color: _warmSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderDefault),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        _directionButton('≤ Máximo', !draft.severityAtLeast,
                            onTap: () =>
                                setSheet(() => draft.severityAtLeast = false)),
                        _directionButton('≥ Mínimo', draft.severityAtLeast,
                            onTap: () =>
                                setSheet(() => draft.severityAtLeast = true)),
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
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _navy),
                  ),
                ]),
                SliderTheme(
                  data: SliderTheme.of(ctx).copyWith(
                    activeTrackColor: _navy,
                    thumbColor: _navy,
                    inactiveTrackColor: _borderDefault,
                    overlayColor: _navy.withValues(alpha: 0.1),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: draft.maxSeverity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) =>
                        setSheet(() => draft.maxSeverity = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('1 – Menor',
                        style: TextStyle(fontSize: 11, color: _muted)),
                    Text('5 – Crítico',
                        style: TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
                const Divider(height: 28),
                _sectionLabel('Tipo de incidente'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filters.sortBy = draft.sortBy;
                      _filters.noIncidentsOnly = draft.noIncidentsOnly;
                      _filters.maxSeverity = draft.maxSeverity;
                      _filters.severityAtLeast = draft.severityAtLeast;
                      _filters.excludedTypes =
                      Set<IncidentType>.from(draft.excludedTypes);
                      _filters.radiusKm = draft.radiusKm;
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Aplicar',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheet helpers ──────────────────────────────────────────────────────────

  Widget _directionButton(String label, bool selected,
      {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _muted)),
        ),
      );

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: _muted));

  Widget _sheetChip(String label, bool selected,
      {IconData? icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _navy : _warmSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? _navy : _borderDefault),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? Colors.white : _muted),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : _muted)),
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
        Icon(icon, size: 18, color: value ? _navy : _muted),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: value ? _navy : _nearBlack,
                    fontWeight:
                    value ? FontWeight.w600 : FontWeight.w400))),
        Switch(value: value, onChanged: onChanged, activeColor: _navy),
      ]);

  // ── List widgets ───────────────────────────────────────────────────────────

  Widget _searchBar() => TextField(
    controller: _searchController,
    onChanged: _onSearch,
    style: const TextStyle(fontSize: 14, color: _nearBlack),
    decoration: InputDecoration(
      hintText: 'Pesquisar estação...',
      hintStyle: const TextStyle(fontSize: 14, color: _muted),
      prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
      filled: true,
      fillColor: _warmSurface,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderDefault)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderDefault)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _navy, width: 1.5)),
    ),
  );

  Widget _disruptionBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _warnBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _warnBorder),
    ),
    child: const Row(children: [
      Icon(Icons.warning_amber_rounded, color: _warnIcon, size: 16),
      SizedBox(width: 8),
      Expanded(
          child: Text('Perturbações ativas em algumas linhas.',
              style: TextStyle(fontSize: 13, color: _nearBlack))),
    ]),
  );

  Widget _favoritesTabs() => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: _warmSurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _borderDefault),
    ),
    child: Row(children: [
      _tabButton(
        label: 'Todos',
        selected: !_favoritesOnly,
        onTap: () => setState(() => _favoritesOnly = false),
      ),
      _tabButton(
        label: '⭐ Favoritos',
        selected: _favoritesOnly,
        onTap: () => setState(() => _favoritesOnly = true),
      ),
    ]),
  );

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _navy : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _muted)),
            ),
          ),
        ),
      );

  Widget _lineChips(List<String> lines) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Linhas',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _muted)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
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
      onTap: () => setState(() => _selectedLine = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _navy : _warmSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _navy : _borderDefault),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (value != null) ...[
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: _lineColor(value), shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              displayLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _muted),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header widget ─────────────────────────────────────────────────────────

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

  // ── Station tile (com Navigator) ──────────────────────────────────────────

  String _fullLineName(String lineName) {
    final l = lineName.toLowerCase();
    if (l.startsWith('linha')) return lineName;
    return 'Linha $lineName';
  }

  Widget _stationTile(Station station) {
    final avg = station.averageRating;
    final hasReports = station.reports.isNotEmpty;
    final distance = _distanceKm(station.latitude, station.longitude);
    final fullLine = _fullLineName(station.lineName);

    return ListTile(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => StationDetailScreen(station: station),
      )),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            station.name,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _nearBlack),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                    color: _lineColor(station.lineName),
                    shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(fullLine,
                style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(width: 8),
            const Text('·', style: TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(width: 8),
            const Icon(Icons.near_me_outlined, size: 11, color: _muted),
            const SizedBox(width: 3),
            Text(_formatDistance(distance),
                style: const TextStyle(fontSize: 12, color: _muted)),
          ]),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: _muted, size: 20),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off_rounded, size: 48, color: _muted),
        const SizedBox(height: 12),
        const Text('Nenhuma estação encontrada',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _nearBlack)),
        const SizedBox(height: 6),
        const Text('Tente ajustar os filtros ou a pesquisa.',
            style: TextStyle(fontSize: 13, color: _muted),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _query = '';
            _selectedLine = null;
            _searchController.clear();
            _filters.reset();
          }),
          child: const Text('Limpar tudo',
              style: TextStyle(color: _navy, fontSize: 14)),
        ),
      ]),
    ),
  );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final all = context.watch<MetroRepository>().getAllStations();
    final lines = _lines(all);
    final filtered = _filtered(all);
    final hasDisruption = all.any((s) => s.averageRating >= 4);
    final activeFilters = _filters.activeCount;

    return Scaffold(
      key: const Key('list-screen'),
      backgroundColor: _warmWhite,
      appBar: AppBar(
        backgroundColor: _navy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Estações',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Filtros',
                onPressed: _showFilterSheet,
              ),
              if (activeFilters > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF5A800), shape: BoxShape.circle),
                    child: Center(
                      child: Text('$activeFilters',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lines, hasDisruption),
            Container(height: 1, color: _borderDefault),
            Expanded(
              child: ListView.builder(
                key: const Key('list-view'),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _stationTile(filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}