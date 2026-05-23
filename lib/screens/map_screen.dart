import 'dart:math';

import 'package:cmproject/connectivity_module.dart';
import 'package:cmproject/data/app_colors.dart';
import 'package:cmproject/data/generic_data_source.dart';
import 'package:cmproject/data/http_metro_datasource.dart';
import 'package:cmproject/data/metro_repository.dart';
import 'package:cmproject/data/sqflite_metro_datasource.dart';
import 'package:cmproject/location_module.dart';
import 'package:cmproject/models/station.dart';
import 'package:cmproject/screens/station_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _lineColor(String n) {
  final l = n.toLowerCase();
  for (final e in AppColors.kLineColors.entries) {
    if (l.contains(e.key)) return e.value;
  }
  return AppColors.kGrey;
}

double _hueForLine(String n) {
  final l = n.toLowerCase();
  if (l.contains('azul'))     return BitmapDescriptor.hueBlue;
  if (l.contains('verde'))    return BitmapDescriptor.hueGreen;
  if (l.contains('vermelha')) return BitmapDescriptor.hueRed;
  if (l.contains('amarela'))  return BitmapDescriptor.hueYellow;
  return BitmapDescriptor.hueViolet;
}

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
    km < 1 ? '${(km * 1000).toStringAsFixed(0)} m' : '${km.toStringAsFixed(1)} km';

Color _ratingColor(double r) {
  if (r >= 4)   return AppColors.kSuccessGreen;
  if (r >= 2.5) return AppColors.kYellow;
  if (r > 0)    return AppColors.kErrorRed;
  return AppColors.kGrey;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _lisbon = LatLng(38.7169, -9.1399);

  late final MetroRepository _repo;
  late final LocationModule  _location;

  GoogleMapController? _mapController;
  List<Station> _stations     = [];
  LatLng? _userLocation;
  bool _loading = true;
  Station? _selected;
  Offset? _cardOffset;

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
    _load();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stations = await _repo.getAllStations();
    final loc = await _location.onLocationChanged().first
        .timeout(const Duration(seconds: 8), onTimeout: () => LocationData.fromMap({}))
        .catchError((_) => LocationData.fromMap({}));

    if (!mounted) return;
    setState(() {
      _stations     = stations;
      _userLocation = loc.latitude != null && loc.longitude != null
          ? LatLng(loc.latitude!, loc.longitude!)
          : null;
      _loading = false;
    });

    if (_userLocation != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
    }
  }

  Future<void> _updateCardOffset(Station s) async {
    if (_mapController == null || !mounted) return;
    final ratio = MediaQuery.of(context).devicePixelRatio;
    final coord = await _mapController!.getScreenCoordinate(LatLng(s.latitude, s.longitude));
    if (!mounted) return;
    setState(() {
      _cardOffset = Offset(
        coord.x / ratio - 210 / 2, // 210 +- card width
        coord.y / ratio - 48 - 120, // 48 +- pin height, 120 +- card height
      );
    });
  }

  Future<void> _onMarkerTap(Station s) async {
    setState(() { _selected = s; _cardOffset = null; });
    await _updateCardOffset(s);
  }

  void _dismiss() => setState(() { _selected = null; _cardOffset = null; });

  Set<Marker> _buildMarkers() => _stations.map((s) => Marker(
    markerId: MarkerId(s.id),
    position: LatLng(s.latitude, s.longitude),
    icon:     BitmapDescriptor.defaultMarkerWithHue(_hueForLine(s.lineName)),
    anchor:   const Offset(0.5, 1.0),
    onTap:    () => _onMarkerTap(s),
  )).toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('map-screen'),
      body: Stack(children: [
        GoogleMap(
          onMapCreated: (c) {
            _mapController = c;
            if (_userLocation != null) {
              c.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
            }
          },
          initialCameraPosition: CameraPosition(target: _userLocation ?? _lisbon, zoom: 13),
          markers:                 _loading ? {} : _buildMarkers(),
          myLocationEnabled:       true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled:     false,
          onCameraMove:            (_) { if (_selected != null) _updateCardOffset(_selected!); },
          onTap:                   (_) => _dismiss(),
        ),

        if (_loading)
          const ColoredBox(
            color: AppColors.kLight,
            child: Center(child: CircularProgressIndicator(color: AppColors.kNavyBlue)),
          ),

        if (_selected != null && _cardOffset != null)
          Positioned(
            left: _cardOffset!.dx,
            top:  _cardOffset!.dy,
            child: _CalloutCard(
              station:      _selected!,
              userLocation: _userLocation,
              onDismiss:    _dismiss,
              onDetails: () {
                final s = _selected!;
                _dismiss();
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StationDetailScreen(station: s),
                ));
              },
            ),
          ),
      ]),
    );
  }
}

// ── Callout card ──────────────────────────────────────────────────────────────

class _CalloutCard extends StatelessWidget {
  final Station      station;
  final LatLng?      userLocation;
  final VoidCallback onDismiss;
  final VoidCallback onDetails;

  const _CalloutCard({
    required this.station,
    required this.userLocation,
    required this.onDismiss,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = _lineColor(station.lineName);
    final distance  = userLocation != null
        ? _distanceKm(userLocation!.latitude, userLocation!.longitude,
        station.latitude, station.longitude)
        : null;
    final count  = station.reports.length;
    final rColor = _ratingColor(station.averageRating);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.kLight,
      child: SizedBox(
        width: 210,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // name + line badge + close
              Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: lineColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(station.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: lineColor, borderRadius: BorderRadius.circular(99)),
                  child: Text(station.lineName,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, size: 14, color: AppColors.kGrey),
                ),
              ]),

              const Divider(height: 12, thickness: 0.5, color: AppColors.kFieldBorder),

              // distance
              if (distance != null)
                _InfoRow(
                  icon:  Icons.near_me_outlined,
                  label: 'distância',
                  value: _formatDistance(distance),
                ),

              // incidents + rating
              _InfoRow(
                icon:  Icons.warning_amber_outlined,
                label: 'incidentes',
                trailing: count == 0
                    ? const Text('nenhum',
                    style: TextStyle(fontSize: 11,
                        fontStyle: FontStyle.italic, color: AppColors.kGrey))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                  _Pill(text: '$count', color: AppColors.kErrorRed),
                  const SizedBox(width: 5),
                  _Circle(text: station.averageRating.toStringAsFixed(1), color: rColor),
                ]),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDetails,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kNavyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ver detalhes', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── reusable widgets ────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final String?   value;
  final Widget?   trailing;

  const _InfoRow({required this.icon, required this.label, this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, size: 13, color: AppColors.kGrey),
        const SizedBox(width: 6),
        Expanded(child: Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.kFieldText))),
        if (trailing != null)
          trailing!
        else
          Text(value ?? '',
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87)),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color  color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Circle extends StatelessWidget {
  final String text;
  final Color  color;

  const _Circle({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}