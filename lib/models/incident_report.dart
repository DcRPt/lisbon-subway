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

}
