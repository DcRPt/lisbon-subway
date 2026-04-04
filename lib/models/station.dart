import 'incident_report.dart';

class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String lineName;
  final List<IncidentReport> reports;

  Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lineName,
    List<IncidentReport>? reports,
  }) : reports = reports ?? [];

  double get averageRating {
    if (reports.isEmpty) {
      return 0.0;
    }
    final totalRating = reports.fold(0, (sum, report) => sum + report.rate);
    return totalRating / reports.length;
  }
}