import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'incident_report_screen.dart';
import 'list_screen.dart';
import 'map_screen.dart';

final screens = [
  (title: 'Home', icon: Icons.home_rounded, widget: const DashboardScreen(), navKey: const Key('dashboard-bottom-bar-item')),
  (title: 'Estações', icon: Icons.subway, widget: const ListScreen(), navKey: const Key('list-bottom-bar-item')),
  (title: 'Mapa', icon: Icons.location_on, widget: const MapScreen(), navKey: const Key('map-bottom-bar-item')),
  (title: 'Reportar', icon: Icons.speaker_notes_rounded, widget: const IncidentReportScreen(), navKey: const Key('incidents-bottom-bar-item')),
];