import 'package:cmproject/models/waiting_time.dart';

import 'incident_report.dart';

class Station {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String lineName;
  final bool isFavourite;
  final List<IncidentReport> reports;
  final List<WaitingTime> waitingTimes;

  Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.lineName,
    this.isFavourite = false,
    List<IncidentReport>? reports,
    List<WaitingTime>? waitingTimes,
  })  : reports   = reports ?? [],
        waitingTimes = waitingTimes ?? [];

  double get averageRating {
    if (reports.isEmpty) {
      return 0.0;
    }
    final totalRating = reports.fold(0, (sum, report) => sum + report.rate);
    return totalRating / reports.length;
  }

  int? get frequencyMinutes {
    final first = waitingTimes.firstOrNull;
    if (first == null || first.arrivalsSeconds.length < 2) return null;
    final gap = first.arrivalsSeconds[1] - first.arrivalsSeconds[0];
    return (gap / 60).round();
  }
  bool get isFavorite{
    return isFavourite;
  }

}