import 'dart:core';

import 'incident_report.dart';

class Station {

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String lineName;
  final List<IncidentReport> reports;

  Station(this.id, this.name, this.latitude, this.longitude, this.lineName, this.reports);

  double get averageRating {
    if (reports.isEmpty) {
      return 0.0;
    }
    final totalRating = reports.fold(0, (sum, report) => sum + report.rate);
    return totalRating / reports.length;
  }
}