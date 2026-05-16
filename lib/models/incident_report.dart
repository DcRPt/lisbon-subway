enum IncidentType {
  Escalator('Escada rolante'),
  Elevator('Elevador'),
  TicketMachine('Máquina de bilhetes'),
  Turnstile('Torniquete'),
  Other('Outro');

  final String displayName;

  const IncidentType(this.displayName);
}

class IncidentReport {

  final DateTime timestamp;
  final int rate;
  final String? notes;
  final IncidentType type;

  IncidentReport({
    required this.timestamp,
    required this.rate,
    required this.type,
    this.notes,
  });

  Map<String, dynamic> toDB(String stationId) => {
    'station_id': stationId,
    'timestamp':  timestamp.toLocal().toIso8601String(),
    'rate':       rate,
    'type':       type.name,
    'notes':      notes,
  };

  factory IncidentReport.fromDB(Map<String, dynamic> row) => IncidentReport(
    timestamp: DateTime.parse(row['timestamp'] as String).toLocal(),
    rate:      row['rate']  as int,
    type:      IncidentType.values.firstWhere((t) => t.name == row['type']),
    notes:     row['notes'] as String?,
  );
}
