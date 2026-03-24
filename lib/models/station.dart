import 'dart:core';

import 'incident_report.dart';

class Station {

  final String id;
  final String name;
  final double latitude, longitude;
  final String lineName;
  final List<IncidentReport> reports;

}